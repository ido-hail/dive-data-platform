from pydantic import BaseModel, EmailStr
from datetime import datetime


class UserCreate(BaseModel):
    full_name: str
    email: EmailStr | None = None


class UserOut(BaseModel):
    id: int
    full_name: str
    email: str | None
    created_at: datetime
    updated_at: datetime

class DiveSiteCreate(BaseModel):
    name: str
    country: str | None = None
    region: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    difficulty: str | None = None


class DiveSiteOut(BaseModel):
    id: int
    name: str
    country: str | None
    region: str | None
    latitude: float | None
    longitude: float | None
    difficulty: str | None
    created_at: datetime
    updated_at: datetime

from decimal import Decimal


class DiveCreate(BaseModel):
    user_id: int
    site_id: int | None = None
    club_id: int | None = None
    instructor_id: int | None = None

    start_time: datetime
    end_time: datetime

    max_depth_m: Decimal | None = None
    avg_depth_m: Decimal | None = None
    water_temp_c: Decimal | None = None
    notes: str | None = None


class DiveOut(BaseModel):
    id: int
    user_id: int
    site_id: int | None
    club_id: int | None
    instructor_id: int | None

    start_time: datetime
    end_time: datetime

    max_depth_m: Decimal | None = None
    avg_depth_m: Decimal | None
    water_temp_c: Decimal | None
    notes: str | None

    created_at: datetime
    updated_at: datetime

class ErrorResponse(BaseModel):
    error_code: str
    message: str
    details: dict | None = None
