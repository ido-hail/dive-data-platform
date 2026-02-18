from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    oltp_host: str = "localhost"
    oltp_port: int = 5433
    oltp_db: str = "dive_app"
    oltp_user: str = "oltp_user"
    oltp_password: str = "oltp_pass"

    class Config:
        env_file = ".env"
        env_prefix = ""
        case_sensitive = False


settings = Settings()
