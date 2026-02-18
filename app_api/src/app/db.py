from psycopg import Connection
from psycopg.rows import dict_row
from .config import settings


def get_conn() -> Connection:
    return Connection.connect(
        host=settings.oltp_host,
        port=settings.oltp_port,
        dbname=settings.oltp_db,
        user=settings.oltp_user,
        password=settings.oltp_password,
        row_factory=dict_row,
    )
