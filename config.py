import os
import json
from typing import Optional
from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict
from urllib.parse import urlparse

def load_config():
    """Loads config from a single APP_CONFIG environment variable (JSON string)."""
    config_str = os.getenv("APP_CONFIG", "{}")
    try:
        config_data = json.loads(config_str)
        print("CONFIG LOADED:", config_data)
        return config_data
    except Exception:
        print("Invalid APP_CONFIG JSON")
        return {}

# Parse JSON config once
app_config = load_config()

# Map to variables for easy access
GEMINI_API_KEY = app_config.get("GEMINI_API_KEY") or app_config.get("GOOGLE_API_KEY")
GITLAB_TOKEN = app_config.get("GITLAB_TOKEN")
GITLAB_PROJECT_ID = app_config.get("GITLAB_PROJECT_ID")
GITLAB_WEBHOOK_SECRET = app_config.get("GITLAB_WEBHOOK_SECRET")
GITLAB_URL = app_config.get("GITLAB_URL", "https://gitlab.com")

# Fail Fast Validation
if not GITLAB_TOKEN or not GITLAB_PROJECT_ID:
    print("CRITICAL: Missing GitLab config (GITLAB_TOKEN or GITLAB_PROJECT_ID)")
    # Not exiting here to allow FastAPI to start and log errors if needed, 
    # but in a real prod environment we might exit(1)

class Settings(BaseSettings):
    """Configuration settings for the SDLC agent system."""
    
    # API Keys
    GOOGLE_API_KEY: Optional[str] = GEMINI_API_KEY
    
    # GitLab Configuration
    GITLAB_URL: str = GITLAB_URL
    GITLAB_TOKEN: Optional[str] = GITLAB_TOKEN
    GITLAB_PROJECT_ID: Optional[int] = GITLAB_PROJECT_ID
    GITLAB_WEBHOOK_SECRET: Optional[str] = GITLAB_WEBHOOK_SECRET
    
    @field_validator("GITLAB_URL", mode="before")
    @classmethod
    def validate_gitlab_url(cls, v: str) -> str:
        """Ensure GITLAB_URL is just the base URL (e.g., https://gitlab.com)."""
        if not v:
            return "https://gitlab.com"
        parsed = urlparse(v)
        return f"{parsed.scheme}://{parsed.netloc}"

    # Redis Configuration
    REDIS_URL: str = app_config.get("REDIS_URL", "redis://localhost:6379/0")
    
    # Agent Settings
    AGENT_MODEL: str = app_config.get("AGENT_MODEL", "gemini-1.5-pro")
    AGENT_MAX_TOKENS: int = int(app_config.get("AGENT_MAX_TOKENS", 8192))
    AGENT_TIMEOUT_SECONDS: int = int(app_config.get("AGENT_TIMEOUT_SECONDS", 180))
    AGENT_MAX_RETRIES: int = int(app_config.get("AGENT_MAX_RETRIES", 2))
    
    # Logging & Environment
    LOG_LEVEL: str = app_config.get("LOG_LEVEL", "INFO")
    ENVIRONMENT: str = app_config.get("ENVIRONMENT", "development")
    
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

settings = Settings()
