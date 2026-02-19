from fastapi import FastAPI, HTTPException
from .db import get_conn
from .schemas import (
    UserCreate,
    UserOut,
    DiveSiteCreate,
    DiveSiteOut,
    DiveCreate,
    DiveOut,
)
from psycopg.errors import UniqueViolation, ForeignKeyViolation, CheckViolation


app = FastAPI(title="Dive Data Platform API")


# =========================
# Generic structured error
# =========================
def _http_error(status_code: int, error_code: str, message: str, details: dict | None = None):
    raise HTTPException(
        status_code=status_code,
        detail={
            "error_code": error_code,
            "message": message,
            "details": details,
        },
    )


# ===========
# Health
# ===========
@app.get("/health")
def health():
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT 1 AS ok;")
            row = cur.fetchone()
    return {"status": "ok", "db": row}


# ===========
# Users
# ===========
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
        _http_error(
            409,
            "USER_EMAIL_EXISTS",
            "A user with this email already exists",
        )


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


# ===========
# Dive Sites
# ===========
@app.post("/dive-sites", response_model=DiveSiteOut)
def create_dive_site(payload: DiveSiteCreate):
    sql = """
    INSERT INTO dive_sites (name, country, region, latitude, longitude, difficulty)
    VALUES (%s, %s, %s, %s, %s, %s)
    RETURNING id, name, country, region, latitude, longitude, difficulty, created_at, updated_at;
    """
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                sql,
                (
                    payload.name,
                    payload.country,
                    payload.region,
                    payload.latitude,
                    payload.longitude,
                    payload.difficulty,
                ),
            )
            row = cur.fetchone()
        conn.commit()
    return row


@app.get("/dive-sites", response_model=list[DiveSiteOut])
def list_dive_sites():
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT id, name, country, region, latitude, longitude, difficulty, created_at, updated_at
                FROM dive_sites
                ORDER BY id DESC;
                """
            )
            rows = cur.fetchall()
    return rows


# ===========
# Dives
# ===========
@app.post("/dives", response_model=DiveOut)
def create_dive(payload: DiveCreate):
    sql = """
    INSERT INTO dives (
        user_id, site_id, club_id, instructor_id,
        start_time, end_time,
        max_depth_m, avg_depth_m, water_temp_c, notes
    )
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    RETURNING
        id, user_id, site_id, club_id, instructor_id,
        start_time, end_time,
        max_depth_m, avg_depth_m, water_temp_c, notes,
        created_at, updated_at;
    """

    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    sql,
                    (
                        payload.user_id,
                        payload.site_id,
                        payload.club_id,
                        payload.instructor_id,
                        payload.start_time,
                        payload.end_time,
                        payload.max_depth_m,
                        payload.avg_depth_m,
                        payload.water_temp_c,
                        payload.notes,
                    ),
                )
                row = cur.fetchone()
            conn.commit()
        return row

    except ForeignKeyViolation as e:
        _http_error(
            400,
            "INVALID_REFERENCE",
            "One of the referenced IDs does not exist",
            {"constraint": e.diag.constraint_name},
        )

    except CheckViolation as e:
        _http_error(
            400,
            "INVALID_DIVE_VALUES",
            "Dive failed validation rules (time range or depth constraint)",
            {"constraint": e.diag.constraint_name},
        )


@app.get("/dives", response_model=list[DiveOut])
def list_dives(limit: int = 100):
    limit = max(1, min(limit, 500))

    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                    id, user_id, site_id, club_id, instructor_id,
                    start_time, end_time,
                    max_depth_m, avg_depth_m, water_temp_c, notes,
                    created_at, updated_at
                FROM dives
                ORDER BY start_time DESC, id DESC
                LIMIT %s;
                """,
                (limit,),
            )
            rows = cur.fetchall()

    return rows
