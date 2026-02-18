from fastapi import FastAPI
from .db import get_conn

app = FastAPI(title="Dive Data Platform API")


@app.get("/health")
def health():
    # Verifies API is up + DB connection works
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT 1 AS ok;")
            row = cur.fetchone()
    return {"status": "ok", "db": row}
