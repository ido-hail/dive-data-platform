from fastapi import FastAPI
from .db import get_conn
from .schemas import UserCreate, UserOut
from psycopg.errors import UniqueViolation
from fastapi import HTTPException


app = FastAPI(title="Dive Data Platform API")


@app.get("/health")
def health():
    # Verifies API is up + DB connection works
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT 1 AS ok;")
            row = cur.fetchone()
    return {"status": "ok", "db": row}

@app.post("/users", response_model=UserOut)
def create_user(payload: UserCreate):
    sql = """
    INSERT INTO users (full_name, email)
    VALUES (%s, %s)
    RETURNING id, full_name, email, created_at, updated_at;
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, (payload.full_name, payload.email))
                row = cur.fetchone()
            conn.commit()
        return row
    except UniqueViolation:
        raise HTTPException(status_code=409, detail="Email already exists")


@app.get("/users", response_model=list[UserOut])
def list_users():
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT id, full_name, email, created_at, updated_at
                FROM users
                ORDER BY id DESC;
                """
            )
            rows = cur.fetchall()
    return rows
