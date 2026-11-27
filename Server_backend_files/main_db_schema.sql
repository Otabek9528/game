CREATE TABLE IF NOT EXISTS "main_db" (
"City_Korean" TEXT,
  "City_English" TEXT,
  "Building_type" TEXT,
  "Name" TEXT,
  "Tel" TEXT,
  "Actual_address" TEXT,
  "KakaoMap_link" TEXT,
  "Latitude" REAL,
  "Longitude" REAL,
  "NaverMap_Link" TEXT
, Unique_number TEXT, Photo_path TEXT, view_count INTEGER DEFAULT 0, Menu_URL TEXT, telegram_url TEXT, tiktok_url TEXT, instagram_url TEXT, owner_note TEXT);
CREATE TABLE reviews (
    Review_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    Unique_number TEXT NOT NULL,
    User_ID TEXT,
    Rating INTEGER NOT NULL,
    Review_Text TEXT,
    Timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (Unique_number) REFERENCES main_db (Unique_number)
);
CREATE TABLE sqlite_sequence(name,seq);
CREATE TABLE house_posts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            username TEXT,
            address TEXT,
            lat REAL,
            lon REAL,
            post_text TEXT,
            timestamp TEXT
        );
CREATE INDEX idx_main_db_menu_url ON main_db(Menu_URL) WHERE Menu_URL IS NOT NULL;
CREATE TABLE place_submissions (
    id                    INTEGER PRIMARY KEY AUTOINCREMENT,

    -- References main_db.Unique_number. Deliberately NOT a FOREIGN KEY:
    -- Unique_number has no unique index in the live schema (admin_add_place
    -- checks uniqueness in Python), so SQLite would reject the constraint,
    -- and PRAGMA foreign_keys is off by default in this app anyway. The admin
    -- queue therefore LEFT JOINs main_db so a submission for a deleted
    -- place still surfaces instead of vanishing from the queue.
    place_id              INTEGER NOT NULL,

    field                 TEXT    NOT NULL
                                  CHECK (field IN ('telegram','tiktok','instagram','note')),

    -- Normalised, validated value as it will be written on approve.
    value                 TEXT    NOT NULL,

    -- Snapshot of main_db.<field> at submit time, so the panel can diff
    -- old vs new. NULL means nothing was registered when this was submitted.
    current_value         TEXT,

    status                TEXT    NOT NULL DEFAULT 'pending'
                                  CHECK (status IN ('pending','approved','rejected')),

    submitted_by_tg_id    INTEGER,
    submitted_by_username TEXT,

    -- 'YYYY-MM-DD HH:MM:SS' in Asia/Seoul (see KST above).
    created_at            TEXT    NOT NULL,
    reviewed_at           TEXT,
    admin_note            TEXT
);
CREATE UNIQUE INDEX ux_place_submissions_pending
            ON place_submissions (place_id, field)
            WHERE status = 'pending'
        ;
CREATE INDEX ix_place_submissions_queue
            ON place_submissions (status, created_at)
        ;
CREATE INDEX ix_place_submissions_rate
            ON place_submissions (submitted_by_tg_id, created_at)
        ;
CREATE TABLE notify_subscribers (
    tg_id       INTEGER PRIMARY KEY,
    username    TEXT,
    lang        TEXT NOT NULL DEFAULT 'uz',
    active      INTEGER NOT NULL DEFAULT 1,
    created_at  TEXT NOT NULL,
    updated_at  TEXT NOT NULL,
    blocked_at  TEXT
, welcomed_at TEXT, via_telegram INTEGER NOT NULL DEFAULT 1, via_push INTEGER NOT NULL DEFAULT 1);
CREATE TABLE place_watches (
    tg_id       INTEGER NOT NULL,
    place_id    INTEGER NOT NULL,
    created_at  TEXT NOT NULL,
    PRIMARY KEY (tg_id, place_id)
);
CREATE INDEX idx_place_watches_place ON place_watches (place_id);
CREATE TABLE place_owners (
    place_id    INTEGER PRIMARY KEY,
    tg_id       INTEGER NOT NULL,
    username    TEXT,
    approved_at TEXT NOT NULL
);
CREATE TABLE owner_claims (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    place_id    INTEGER NOT NULL,
    tg_id       INTEGER NOT NULL,
    username    TEXT,
    status      TEXT NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at  TEXT NOT NULL,
    reviewed_at TEXT
);
CREATE UNIQUE INDEX uq_owner_claims_pending
    ON owner_claims (place_id, tg_id) WHERE status = 'pending';
CREATE TABLE announcements (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    place_id        INTEGER NOT NULL,
    author_tg_id    INTEGER,
    author_username TEXT,
    author_role     TEXT NOT NULL CHECK (author_role IN ('owner', 'public', 'admin')),
    text            TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at      TEXT NOT NULL,
    reviewed_at     TEXT,
    sent_at         TEXT,
    recipients      INTEGER
);
CREATE INDEX idx_announcements_place ON announcements (place_id, status);
CREATE TABLE notify_outbox (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    tg_id           INTEGER NOT NULL,
    text            TEXT NOT NULL,
    buttons         TEXT,
    status          TEXT NOT NULL DEFAULT 'queued'
                    CHECK (status IN ('queued', 'sent', 'failed')),
    attempts        INTEGER NOT NULL DEFAULT 0,
    next_attempt_at TEXT NOT NULL,
    event_ref       TEXT,
    created_at      TEXT NOT NULL,
    sent_at         TEXT,
    error           TEXT
, pushed_at TEXT);
CREATE INDEX idx_outbox_due ON notify_outbox (status, next_attempt_at);
CREATE TABLE IF NOT EXISTS "area_watches" (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    tg_id       INTEGER NOT NULL,
    source      TEXT NOT NULL CHECK (source IN ('location', 'address')),
    label       TEXT,
    lat         REAL NOT NULL,
    lon         REAL NOT NULL,
    radius_km   INTEGER NOT NULL CHECK (radius_km IN (1, 3, 5, 10)),
    types       TEXT NOT NULL,
    created_at  TEXT NOT NULL,
    updated_at  TEXT NOT NULL
);
CREATE INDEX idx_area_watches_tg ON area_watches (tg_id);
CREATE INDEX idx_area_watches_pos ON area_watches (lat, lon);
CREATE INDEX idx_main_db_lat_lon ON main_db (Latitude, Longitude);
