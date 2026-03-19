import time
import structlog
from contextlib import asynccontextmanager
from fastapi import FastAPI
from webhooks.router import router as webhook_router
from tools.gitlab_tools import GitLabTools
from orchestrator.state import state_manager
from config import settings

# Setup structured logging
structlog.configure(
    processors=[
        structlog.processors.JSONRenderer()
    ]
)
logger = structlog.get_logger()

start_time = time.time()

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup and shutdown."""
    logger.info("startup_checks_begin")
    
    # Verify Redis (already fallback handled in state.py)
    if not state_manager.ping():
        logger.warning("redis_unavailable_running_in_memory_mode")
    else:
        logger.info("state_manager_connected")
        
    # Verify GitLab (Optional at startup to prevent crash)
    gitlab_tools = GitLabTools()
    try:
        if not gitlab_tools.ping():
            logger.warning("gitlab_connection_failed_check_creds")
        else:
            logger.info("gitlab_connected")
    except Exception as e:
        logger.warning("gitlab_init_error", error=str(e))
        
    # Log active agents
    agents = ["PMAgent", "ArchitectAgent", "DeveloperAgent", "ReviewAgent", "TestAgent", "SecurityAgent", "DevOpsAgent"]
    logger.info("agents_ready", active_agents=agents)
    
    yield
    logger.info("shutdown")

app = FastAPI(title="GitLab SDLC Agents", lifespan=lifespan)

app.include_router(webhook_router)

@app.get("/health")
async def health_check():
    """Returns application health status."""
    uptime = time.time() - start_time
    return {
        "status": "healthy",
        "uptime": f"{uptime:.2f}s",
        "version": "0.1.0",
        "environment": settings.ENVIRONMENT,
        "state_manager": state_manager.__class__.__name__
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
