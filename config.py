from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import Optional
from urllib.parse import urlparse

class Settings(BaseSettings):
    """Configuration settings for the SDLC agent system."""
    
    # API Keys
    GOOGLE_API_KEY: Optional[str] = None
    
    # GitLab Configuration
    GITLAB_URL: str = "https://gitlab.com"
    GITLAB_TOKEN: Optional[str] = None
    GITLAB_PROJECT_ID: Optional[int] = None
    GITLAB_WEBHOOK_SECRET: Optional[str] = None
    
    @field_validator("GITLAB_URL", mode="before")
    @classmethod
    def validate_gitlab_url(cls, v: str) -> str:
        """Ensure GITLAB_URL is just the base URL (e.g., https://gitlab.com)."""
        if not v:
            return "https://gitlab.com"
        parsed = urlparse(v)
        return f"{parsed.scheme}://{parsed.netloc}"

    # Redis Configuration
    REDIS_URL: str = "redis://localhost:6379/0"
    
    # Agent Settings
    AGENT_MODEL: str = "gemini-1.5-pro" 
    AGENT_MAX_TOKENS: int = 8192
    AGENT_TIMEOUT_SECONDS: int = 180
    AGENT_MAX_RETRIES: int = 2
    
    # Logging & Environment
    LOG_LEVEL: str = "INFO"
    ENVIRONMENT: str = "development"
    
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

settings = Settings()
