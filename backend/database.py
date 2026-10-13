"""SQLite connection helpers and password / token hashing."""

from __future__ import annotations

import hashlib
import hmac
import os
import secrets
import sqlite3
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
DB_PATH = Path(os.environ.get("CAMPUS_DB_PATH", BASE_DIR / "crimson_campus.db"))
SCHEMA_PATH = BASE_DIR / "schema.sql"

PBKDF2_ITERATIONS = 200_000


def connect() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


MEDIA_DIR = Path(os.environ.get("CAMPUS_MEDIA_DIR", BASE_DIR / "media"))


def init_db() -> None:
    MEDIA_DIR.mkdir(parents=True, exist_ok=True)
    with connect() as conn:
        conn.executescript(SCHEMA_PATH.read_text(encoding="utf-8"))
        # Migration: profile photos were added after the first release.
        columns = {row["name"] for row in conn.execute("PRAGMA table_info(students)")}
        if "photo_file" not in columns:
            conn.execute("ALTER TABLE students ADD COLUMN photo_file TEXT")


def hash_password(password: str, salt: str | None = None) -> tuple[str, str]:
    salt = salt or secrets.token_hex(16)
    digest = hashlib.pbkdf2_hmac(
        "sha256", password.encode("utf-8"), bytes.fromhex(salt), PBKDF2_ITERATIONS
    )
    return digest.hex(), salt


def verify_password(password: str, stored_hash: str, salt: str) -> bool:
    candidate, _ = hash_password(password, salt)
    return hmac.compare_digest(candidate, stored_hash)


def new_token() -> tuple[str, str]:
    """Returns (token for the client, hash to store)."""
    token = secrets.token_urlsafe(32)
    return token, hash_token(token)


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()
