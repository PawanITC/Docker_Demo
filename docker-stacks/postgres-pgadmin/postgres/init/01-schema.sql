-- Runs once, on first start, against $POSTGRES_DB (appdb).
CREATE TABLE IF NOT EXISTS customers (
    id         SERIAL PRIMARY KEY,
    name       TEXT NOT NULL,
    email      TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO customers (name, email) VALUES
    ('Asha',  'asha@example.com'),
    ('Ravi',  'ravi@example.com'),
    ('Meera', 'meera@example.com')
ON CONFLICT DO NOTHING;
