-- Crimson Campus database (SQLite).
-- Holds every piece of data the app collects from a student.

PRAGMA foreign_keys = ON;

-- Account + profile, collected on the Create account and Profile pages.
CREATE TABLE IF NOT EXISTS students (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    student_id       TEXT    NOT NULL UNIQUE,              -- e.g. I23012345
    full_name        TEXT    NOT NULL,
    email            TEXT    NOT NULL UNIQUE COLLATE NOCASE,
    password_hash    TEXT    NOT NULL,                     -- PBKDF2-SHA256
    password_salt    TEXT    NOT NULL,
    programme        TEXT    NOT NULL,
    semester         INTEGER NOT NULL CHECK (semester BETWEEN 1 AND 12),
    total_semesters  INTEGER NOT NULL DEFAULT 8,
    cgpa             REAL    CHECK (cgpa IS NULL OR cgpa BETWEEN 0 AND 4),
    credits_earned   INTEGER NOT NULL DEFAULT 0 CHECK (credits_earned >= 0),
    credits_required INTEGER NOT NULL DEFAULT 120,
    phone            TEXT,
    residence        TEXT,
    advisor          TEXT,
    photo_file       TEXT,                                 -- file name in backend/media/
    created_at       TEXT    NOT NULL DEFAULT (datetime('now')),
    updated_at       TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- Login sessions. Only a SHA-256 hash of each token is stored.
CREATE TABLE IF NOT EXISTS sessions (
    token_hash  TEXT    PRIMARY KEY,
    student_pk  INTEGER NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
    expires_at  TEXT    NOT NULL
);

-- Notification switches on the Profile page.
CREATE TABLE IF NOT EXISTS preferences (
    student_pk       INTEGER PRIMARY KEY REFERENCES students(id) ON DELETE CASCADE,
    announcements    INTEGER NOT NULL DEFAULT 1,
    class_reminders  INTEGER NOT NULL DEFAULT 1,
    shuttle_alerts   INTEGER NOT NULL DEFAULT 0
);

-- Register / Cancel on event cards and the event detail page.
CREATE TABLE IF NOT EXISTS event_registrations (
    student_pk     INTEGER NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    event_id       TEXT    NOT NULL,
    registered_at  TEXT    NOT NULL DEFAULT (datetime('now')),
    PRIMARY KEY (student_pk, event_id)
);

-- Join / Leave on the Clubs page.
CREATE TABLE IF NOT EXISTS club_memberships (
    student_pk  INTEGER NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    club_id     TEXT    NOT NULL,
    joined_at   TEXT    NOT NULL DEFAULT (datetime('now')),
    PRIMARY KEY (student_pk, club_id)
);

-- Read state of announcements.
CREATE TABLE IF NOT EXISTS announcement_reads (
    student_pk       INTEGER NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    announcement_id  TEXT    NOT NULL,
    read_at          TEXT    NOT NULL DEFAULT (datetime('now')),
    PRIMARY KEY (student_pk, announcement_id)
);

-- Renew buttons on the Library page.
CREATE TABLE IF NOT EXISTS library_renewals (
    student_pk  INTEGER NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    book_id     TEXT    NOT NULL,
    renewed_at  TEXT    NOT NULL DEFAULT (datetime('now')),
    PRIMARY KEY (student_pk, book_id)
);

-- Bell toggles on the Shuttle page.
CREATE TABLE IF NOT EXISTS shuttle_alerts (
    student_pk  INTEGER NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    route_id    TEXT    NOT NULL,
    created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
    PRIMARY KEY (student_pk, route_id)
);

-- Tickets raised on the Helpdesk page.
CREATE TABLE IF NOT EXISTS helpdesk_tickets (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    student_pk  INTEGER NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    category    TEXT    NOT NULL,
    message     TEXT    NOT NULL,
    status      TEXT    NOT NULL DEFAULT 'Open',
    created_at  TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_sessions_student ON sessions(student_pk);
CREATE INDEX IF NOT EXISTS idx_tickets_student ON helpdesk_tickets(student_pk);
