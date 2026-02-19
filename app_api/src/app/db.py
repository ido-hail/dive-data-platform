from psycopg import Connection
from psycopg.rows import dict_row
from pymongo import MongoClient

from .config import settings

# =========================
# Postgres (OLTP)
# =========================

def get_conn() -> Connection:
    """
    Returns a new psycopg connection to the OLTP database.
    Uses dict_row so rows are returned as dictionaries.
    """
    return Connection.connect(
        host=settings.oltp_host,
        port=settings.oltp_port,
        dbname=settings.oltp_db,
        user=settings.oltp_user,
        password=settings.oltp_password,
        row_factory=dict_row,
    )


# =========================
# MongoDB (Events)
# =========================

_mongo_client: MongoClient | None = None


def get_mongo_client() -> MongoClient:
    """
    Returns a singleton MongoClient instance.
    Prevents creating a new connection on every request.
    """
    global _mongo_client

    if _mongo_client is None:
        _mongo_client = MongoClient(settings.mongo_uri)

    return _mongo_client


def get_events_collection():
    """
    Returns the Mongo collection used for valid events.
    """
    client = get_mongo_client()
    return client[settings.mongo_db][settings.mongo_events_collection]
