from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import Optional

class Settings(BaseSettings):
    """Configuration settings for the SDLC agent system."""
    
    # API Keys
    GOOGLE_API_KEY: str
    
    # GitLab Configuration
    GITLAB_URL: str = "https://gitlab.com"
    GITLAB_TOKEN: str
    GITLAB_PROJECT_ID: int
    GITLAB_WEBHOOK_SECRET: str
    
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
