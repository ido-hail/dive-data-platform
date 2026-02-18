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
