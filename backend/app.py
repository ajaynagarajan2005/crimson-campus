"""Crimson Campus API — FastAPI + SQLite.

Run from this folder:
    .venv\\Scripts\\python -m uvicorn app:app --host 0.0.0.0 --port 8000 --reload
"""

from __future__ import annotations

import base64
import binascii
import io
import json
import os
import re
import secrets
import sqlite3
import urllib.error
import urllib.parse
import urllib.request
from contextlib import asynccontextmanager
from datetime import date, datetime, timedelta, timezone
from typing import Annotated

from fastapi import Depends, FastAPI, Header, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from PIL import Image, ImageOps, UnidentifiedImageError
from pydantic import BaseModel, Field, field_validator

from database import (
    MEDIA_DIR,
    connect,
    hash_password,
    hash_token,
    init_db,
    new_token,
    verify_password,
)

SESSION_DAYS = 30
EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
ITEM_ID_RE = re.compile(r"^[a-z0-9-]{1,64}$")
DEFAULT_ADVISOR = "To be assigned"

# Per-student lists the app toggles: URL name -> (table, item column).
COLLECTIONS: dict[str, tuple[str, str]] = {
    "events": ("event_registrations", "event_id"),
    "clubs": ("club_memberships", "club_id"),
    "announcements-read": ("announcement_reads", "announcement_id"),
    "library-renewals": ("library_renewals", "book_id"),
    "shuttle-alerts": ("shuttle_alerts", "route_id"),
}
HELPDESK_CATEGORIES = {"IT & Wi-Fi", "Academics", "Hostel", "Fees", "Other"}
TICKET_PRIORITIES = {"Low", "Medium", "High", "Urgent"}
CONTACT_METHODS = {"Email", "Phone", "In person"}

@asynccontextmanager
async def lifespan(_: FastAPI):
    init_db()
    yield


app = FastAPI(title="Crimson Campus API", version="1.0.0", lifespan=lifespan)
# The Flutter web app runs on a different port, so allow cross-origin calls.
# Auth uses a bearer token (no cookies), so a wildcard origin is safe here.
MEDIA_DIR.mkdir(parents=True, exist_ok=True)
# Profile photos live under random, unguessable file names.
app.mount("/media", StaticFiles(directory=MEDIA_DIR), name="media")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------------
# Request models
# ---------------------------------------------------------------------------


def _clean(value: str) -> str:
    return " ".join(value.split())


class RegisterIn(BaseModel):
    full_name: str = Field(min_length=2, max_length=80)
    student_id: str = Field(min_length=3, max_length=20)
    email: str = Field(max_length=120)
    password: str = Field(min_length=6, max_length=128)
    programme: str = Field(min_length=2, max_length=120)
    semester: int = Field(ge=1, le=12)
    cgpa: float | None = Field(default=None, ge=0, le=4)
    credits_earned: int = Field(default=0, ge=0, le=400)
    phone: str | None = Field(default=None, max_length=30)

    @field_validator("full_name", "programme")
    @classmethod
    def _tidy(cls, v: str) -> str:
        return _clean(v)

    @field_validator("student_id")
    @classmethod
    def _student_id(cls, v: str) -> str:
        v = v.strip().upper()
        if not re.fullmatch(r"[A-Z0-9-]+", v):
            raise ValueError("Student ID may only contain letters, numbers and dashes")
        return v

    @field_validator("email")
    @classmethod
    def _email(cls, v: str) -> str:
        v = v.strip().lower()
        if not EMAIL_RE.match(v):
            raise ValueError("Enter a valid email address")
        return v


class LoginIn(BaseModel):
    identifier: str = Field(min_length=3, max_length=120)  # email or student ID
    password: str = Field(min_length=1, max_length=128)


class ProfileUpdate(BaseModel):
    full_name: str | None = Field(default=None, min_length=2, max_length=80)
    programme: str | None = Field(default=None, min_length=2, max_length=120)
    semester: int | None = Field(default=None, ge=1, le=12)
    cgpa: float | None = Field(default=None, ge=0, le=4)
    credits_earned: int | None = Field(default=None, ge=0, le=400)
    phone: str | None = Field(default=None, max_length=30)
    residence: str | None = Field(default=None, max_length=120)


class PreferencesIn(BaseModel):
    announcements: bool
    class_reminders: bool
    shuttle_alerts: bool


class BulkIds(BaseModel):
    ids: list[str] = Field(max_length=200)


class PhotoIn(BaseModel):
    # Base64-encoded image bytes (JPEG, PNG or WebP), max ~5 MB.
    data: str = Field(min_length=10, max_length=7_000_000)


class TicketIn(BaseModel):
    category: str
    message: str = Field(min_length=5, max_length=2000)
    subject: str | None = Field(default=None, max_length=120)
    priority: str | None = None
    preferred_date: date | None = None
    contact_method: str | None = None
    contact_phone: str | None = Field(default=None, max_length=30)

    @field_validator("category")
    @classmethod
    def _category(cls, v: str) -> str:
        if v not in HELPDESK_CATEGORIES:
            raise ValueError("Unknown category")
        return v

    @field_validator("priority")
    @classmethod
    def _priority(cls, v: str | None) -> str | None:
        if v is not None and v not in TICKET_PRIORITIES:
            raise ValueError("Unknown priority")
        return v

    @field_validator("contact_method")
    @classmethod
    def _contact_method(cls, v: str | None) -> str | None:
        if v is not None and v not in CONTACT_METHODS:
            raise ValueError("Unknown contact method")
        return v

    @field_validator("subject", "contact_phone")
    @classmethod
    def _optional_text(cls, v: str | None) -> str | None:
        return (_clean(v) or None) if v is not None else None


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def get_db():
    conn = connect()
    try:
        yield conn
    finally:
        conn.close()


Db = Annotated[sqlite3.Connection, Depends(get_db)]


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _iso(dt: datetime) -> str:
    return dt.strftime("%Y-%m-%d %H:%M:%S")


def current_student(
    db: Db, authorization: Annotated[str | None, Header()] = None
) -> sqlite3.Row:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Please log in")
    token_hash = hash_token(authorization[7:].strip())
    row = db.execute(
        """SELECT s.* FROM sessions x JOIN students s ON s.id = x.student_pk
           WHERE x.token_hash = ? AND x.expires_at > ?""",
        (token_hash, _iso(_now())),
    ).fetchone()
    if row is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Session expired, please log in again")
    return row


Me = Annotated[sqlite3.Row, Depends(current_student)]


def _student_json(row: sqlite3.Row) -> dict:
    return {
        "id": row["id"],
        "student_id": row["student_id"],
        "full_name": row["full_name"],
        "email": row["email"],
        "programme": row["programme"],
        "semester": row["semester"],
        "total_semesters": row["total_semesters"],
        "cgpa": row["cgpa"],
        "credits_earned": row["credits_earned"],
        "credits_required": row["credits_required"],
        "phone": row["phone"],
        "residence": row["residence"],
        "advisor": row["advisor"] or DEFAULT_ADVISOR,
        "photo_url": f"/media/{row['photo_file']}" if row["photo_file"] else None,
        "created_at": row["created_at"],
    }


def _ticket_json(row: sqlite3.Row) -> dict:
    return {
        "id": row["id"],
        "ticket_no": f"HD-{1000 + row['id']}",
        "category": row["category"],
        "message": row["message"],
        "subject": row["subject"],
        "priority": row["priority"],
        "preferred_date": row["preferred_date"],
        "contact_method": row["contact_method"],
        "contact_phone": row["contact_phone"],
        "status": row["status"],
        "created_at": row["created_at"],
    }


def _items(db: sqlite3.Connection, collection: str, student_pk: int) -> list[str]:
    table, column = COLLECTIONS[collection]
    rows = db.execute(
        f"SELECT {column} FROM {table} WHERE student_pk = ? ORDER BY rowid",
        (student_pk,),
    ).fetchall()
    return [r[0] for r in rows]


def _profile(db: sqlite3.Connection, student: sqlite3.Row) -> dict:
    pk = student["id"]
    prefs = db.execute("SELECT * FROM preferences WHERE student_pk = ?", (pk,)).fetchone()
    tickets = db.execute(
        "SELECT * FROM helpdesk_tickets WHERE student_pk = ? ORDER BY id DESC", (pk,)
    ).fetchall()
    return {
        "student": _student_json(student),
        "preferences": {
            "announcements": bool(prefs["announcements"]) if prefs else True,
            "class_reminders": bool(prefs["class_reminders"]) if prefs else True,
            "shuttle_alerts": bool(prefs["shuttle_alerts"]) if prefs else False,
        },
        "registered_events": _items(db, "events", pk),
        "joined_clubs": _items(db, "clubs", pk),
        "read_announcements": _items(db, "announcements-read", pk),
        "renewed_books": _items(db, "library-renewals", pk),
        "shuttle_alerts": _items(db, "shuttle-alerts", pk),
        "tickets": [_ticket_json(t) for t in tickets],
    }


def _start_session(db: sqlite3.Connection, student_pk: int) -> str:
    token, token_hash = new_token()
    db.execute("DELETE FROM sessions WHERE expires_at <= ?", (_iso(_now()),))
    db.execute(
        "INSERT INTO sessions (token_hash, student_pk, expires_at) VALUES (?, ?, ?)",
        (token_hash, student_pk, _iso(_now() + timedelta(days=SESSION_DAYS))),
    )
    return token


def _collection(name: str) -> str:
    if name not in COLLECTIONS:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Unknown collection")
    return name


def _item_id(item_id: str) -> str:
    if not ITEM_ID_RE.match(item_id):
        raise HTTPException(422, "Invalid item id")
    return item_id


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------


@app.get("/api/health")
def health() -> dict:
    return {"status": "ok"}


@app.post("/api/auth/register", status_code=status.HTTP_201_CREATED)
def register(body: RegisterIn, db: Db) -> dict:
    password_hash, salt = hash_password(body.password)
    try:
        with db:
            cur = db.execute(
                """INSERT INTO students (student_id, full_name, email, password_hash,
                       password_salt, programme, semester, cgpa, credits_earned, phone, advisor)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                (
                    body.student_id, body.full_name, body.email, password_hash, salt,
                    body.programme, body.semester, body.cgpa, body.credits_earned,
                    body.phone or None, DEFAULT_ADVISOR,
                ),
            )
            pk = cur.lastrowid
            db.execute("INSERT INTO preferences (student_pk) VALUES (?)", (pk,))
            token = _start_session(db, pk)
    except sqlite3.IntegrityError:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "An account with this email or student ID already exists",
        )
    student = db.execute("SELECT * FROM students WHERE id = ?", (pk,)).fetchone()
    return {"token": token, "profile": _profile(db, student)}


@app.post("/api/auth/login")
def login(body: LoginIn, db: Db) -> dict:
    ident = body.identifier.strip()
    student = db.execute(
        "SELECT * FROM students WHERE email = ? COLLATE NOCASE OR student_id = ?",
        (ident.lower(), ident.upper()),
    ).fetchone()
    if student is None or not verify_password(
        body.password, student["password_hash"], student["password_salt"]
    ):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Incorrect email/student ID or password")
    with db:
        token = _start_session(db, student["id"])
    return {"token": token, "profile": _profile(db, student)}


@app.post("/api/auth/logout", status_code=status.HTTP_204_NO_CONTENT)
def logout(db: Db, me: Me, authorization: Annotated[str, Header()]) -> None:
    with db:
        db.execute("DELETE FROM sessions WHERE token_hash = ?", (hash_token(authorization[7:].strip()),))


@app.get("/api/me")
def get_me(db: Db, me: Me) -> dict:
    return _profile(db, me)


@app.patch("/api/me")
def update_me(body: ProfileUpdate, db: Db, me: Me) -> dict:
    changes = body.model_dump(exclude_unset=True)
    for key in ("full_name", "programme", "phone", "residence"):
        if isinstance(changes.get(key), str):
            changes[key] = _clean(changes[key]) or None
    if changes.get("full_name") is None:
        changes.pop("full_name", None)
    if changes.get("programme") is None:
        changes.pop("programme", None)
    if changes:
        assignments = ", ".join(f"{k} = ?" for k in changes)
        with db:
            db.execute(
                f"UPDATE students SET {assignments}, updated_at = datetime('now') WHERE id = ?",
                (*changes.values(), me["id"]),
            )
    student = db.execute("SELECT * FROM students WHERE id = ?", (me["id"],)).fetchone()
    return _profile(db, student)


@app.put("/api/me/preferences")
def update_preferences(body: PreferencesIn, db: Db, me: Me) -> dict:
    with db:
        db.execute(
            """INSERT INTO preferences (student_pk, announcements, class_reminders, shuttle_alerts)
               VALUES (?, ?, ?, ?)
               ON CONFLICT(student_pk) DO UPDATE SET
                 announcements = excluded.announcements,
                 class_reminders = excluded.class_reminders,
                 shuttle_alerts = excluded.shuttle_alerts""",
            (me["id"], int(body.announcements), int(body.class_reminders), int(body.shuttle_alerts)),
        )
    return body.model_dump()


@app.put("/api/me/{collection}/{item_id}")
def add_item(collection: str, item_id: str, db: Db, me: Me) -> dict:
    name, item = _collection(collection), _item_id(item_id)
    table, column = COLLECTIONS[name]
    with db:
        db.execute(
            f"INSERT OR IGNORE INTO {table} (student_pk, {column}) VALUES (?, ?)",
            (me["id"], item),
        )
    return {"items": _items(db, name, me["id"])}


@app.delete("/api/me/{collection}/{item_id}")
def remove_item(collection: str, item_id: str, db: Db, me: Me) -> dict:
    name, item = _collection(collection), _item_id(item_id)
    table, column = COLLECTIONS[name]
    with db:
        db.execute(f"DELETE FROM {table} WHERE student_pk = ? AND {column} = ?", (me["id"], item))
    return {"items": _items(db, name, me["id"])}


@app.post("/api/me/announcements-read")
def mark_many_read(body: BulkIds, db: Db, me: Me) -> dict:
    ids = [_item_id(i) for i in body.ids]
    with db:
        db.executemany(
            "INSERT OR IGNORE INTO announcement_reads (student_pk, announcement_id) VALUES (?, ?)",
            [(me["id"], i) for i in ids],
        )
    return {"items": _items(db, "announcements-read", me["id"])}


@app.get("/api/me/tickets")
def list_tickets(db: Db, me: Me) -> list[dict]:
    rows = db.execute(
        "SELECT * FROM helpdesk_tickets WHERE student_pk = ? ORDER BY id DESC", (me["id"],)
    ).fetchall()
    return [_ticket_json(r) for r in rows]


@app.post("/api/me/tickets", status_code=status.HTTP_201_CREATED)
def create_ticket(body: TicketIn, db: Db, me: Me) -> dict:
    with db:
        cur = db.execute(
            "INSERT INTO helpdesk_tickets (student_pk, category, message, subject, priority,"
            " preferred_date, contact_method, contact_phone) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            (
                me["id"],
                body.category,
                body.message.strip(),
                body.subject,
                body.priority,
                body.preferred_date.isoformat() if body.preferred_date else None,
                body.contact_method,
                body.contact_phone,
            ),
        )
    row = db.execute("SELECT * FROM helpdesk_tickets WHERE id = ?", (cur.lastrowid,)).fetchone()
    return _ticket_json(row)


# ---------------------------------------------------------------------------
# Profile photo (virtual student ID)
# ---------------------------------------------------------------------------

PHOTO_SIZE = 512
MAX_PHOTO_BYTES = 5 * 1024 * 1024


def _delete_photo_file(name: str | None) -> None:
    if name:
        (MEDIA_DIR / name).unlink(missing_ok=True)


@app.put("/api/me/photo")
def upload_photo(body: PhotoIn, db: Db, me: Me) -> dict:
    try:
        raw = base64.b64decode(body.data, validate=True)
    except (binascii.Error, ValueError):
        raise HTTPException(422, "The photo could not be read")
    if len(raw) > MAX_PHOTO_BYTES:
        raise HTTPException(413, "Photo is too large (max 5 MB)")
    try:
        image = Image.open(io.BytesIO(raw))
        image.verify()  # rejects corrupt or non-image files
        image = Image.open(io.BytesIO(raw))
    except (UnidentifiedImageError, OSError):
        raise HTTPException(422, "Please choose a JPEG, PNG or WebP image")

    # Square, upright, 512 px, no metadata (strips location data from phones).
    image = ImageOps.exif_transpose(image).convert("RGB")
    image = ImageOps.fit(image, (PHOTO_SIZE, PHOTO_SIZE), Image.LANCZOS)
    name = f"{secrets.token_urlsafe(18)}.jpg"
    image.save(MEDIA_DIR / name, "JPEG", quality=88, optimize=True)

    with db:
        db.execute(
            "UPDATE students SET photo_file = ?, updated_at = datetime('now') WHERE id = ?",
            (name, me["id"]),
        )
    _delete_photo_file(me["photo_file"])
    student = db.execute("SELECT * FROM students WHERE id = ?", (me["id"],)).fetchone()
    return _profile(db, student)


@app.delete("/api/me/photo")
def delete_photo(db: Db, me: Me) -> dict:
    with db:
        db.execute("UPDATE students SET photo_file = NULL WHERE id = ?", (me["id"],))
    _delete_photo_file(me["photo_file"])
    student = db.execute("SELECT * FROM students WHERE id = ?", (me["id"],)).fetchone()
    return _profile(db, student)


# ---------------------------------------------------------------------------
# Walking directions (OpenRouteService). The key stays on the server.
# Set ORS_API_KEY in the environment to enable real walking paths.
# ---------------------------------------------------------------------------

ORS_URL = "https://api.openrouteservice.org/v2/directions/foot-walking"


def _coord(value: str) -> tuple[float, float]:
    try:
        lat_s, lon_s = value.split(",")
        lat, lon = float(lat_s), float(lon_s)
    except ValueError:
        raise HTTPException(422, "Use lat,lon for coordinates")
    if not (-90 <= lat <= 90 and -180 <= lon <= 180):
        raise HTTPException(422, "Coordinates out of range")
    return lat, lon


CAMPUS_CENTER = (2.81240, 101.75826)


def _near_campus(lat: float, lon: float, km: float = 5.0) -> bool:
    # ~111 km per degree; good enough for a 5 km radius near the equator.
    return ((lat - CAMPUS_CENTER[0]) ** 2 + (lon - CAMPUS_CENTER[1]) ** 2) ** 0.5 * 111 <= km


@app.get("/api/route/walking")
def walking_route(start: str, end: str) -> dict:
    key = os.environ.get("ORS_API_KEY", "").strip()
    if not key:
        raise HTTPException(503, "Walking directions are not configured (set ORS_API_KEY on the server)")
    (lat1, lon1), (lat2, lon2) = _coord(start), _coord(end)
    # Only campus trips, so the shared API quota can't be spent elsewhere.
    if not (_near_campus(lat1, lon1) and _near_campus(lat2, lon2)):
        raise HTTPException(422, "Directions are only available around the INTI Nilai campus")
    query = urllib.parse.urlencode({"api_key": key, "start": f"{lon1},{lat1}", "end": f"{lon2},{lat2}"})
    request = urllib.request.Request(f"{ORS_URL}?{query}", headers={"Accept": "application/geo+json"})
    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            data = json.load(response)
    except urllib.error.HTTPError as error:
        raise HTTPException(502, f"Routing service error ({error.code})")
    except (urllib.error.URLError, TimeoutError):
        raise HTTPException(502, "Routing service is unreachable")

    feature = data["features"][0]
    summary = feature["properties"].get("summary", {})
    return {
        # GeoJSON is lon,lat; the app wants lat,lon.
        "points": [[lat, lon] for lon, lat in feature["geometry"]["coordinates"]],
        "distance_m": summary.get("distance"),
        "duration_s": summary.get("duration"),
    }
