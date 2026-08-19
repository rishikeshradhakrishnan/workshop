import sqlite3
import click
from flask import current_app, g

SCHEMA = """
CREATE TABLE IF NOT EXISTS users   (id INTEGER PRIMARY KEY, username TEXT UNIQUE NOT NULL, password_hash TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS reviews (id INTEGER PRIMARY KEY, product_id TEXT NOT NULL, user_id INTEGER NOT NULL,
                                    rating INTEGER NOT NULL, body TEXT NOT NULL, private INTEGER NOT NULL DEFAULT 0);
"""

def get_db():
    if "db" not in g:
        g.db = sqlite3.connect(current_app.config["DATABASE"])
        g.db.row_factory = sqlite3.Row
    return g.db

def close_db(_exc=None):
    conn = g.pop("db", None)
    if conn is not None:
        conn.close()

def init_db(seed=True):
    conn = get_db()
    conn.executescript(SCHEMA)
    if seed:
        conn.executescript("""
        INSERT OR IGNORE INTO users(id, username, password_hash) VALUES (1,'ada','x'),(2,'grace','x');
        INSERT OR IGNORE INTO reviews(id, product_id, user_id, rating, body, private) VALUES
          (1,'telescope-01',1,5,'Crisp optics',0),(2,'telescope-01',2,2,'Wobbly mount',0),(3,'lens-07',2,4,'draft: gift idea',1);
        """)
    conn.commit()

@click.command("init-db")
def init_db_command():
    init_db()
    click.echo("initialized")
