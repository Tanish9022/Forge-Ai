import time
import hmac
import structlog
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, BackgroundTasks, Header, HTTPException
from tools.gitlab_tools import GitLabTools
from tools.llm_tools import LLMClient
from orchestrator.orchestrator import Orchestrator
from orchestrator.state import state_manager
from webhooks import parser
from config import settings
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Setup structured logging
structlog.configure(
    processors=[
        structlog.processors.JSONRenderer()
    ]
)
logger = structlog.get_logger()

# Global instances for reuse
gitlab_tools = GitLabTools()
llm_client = LLMClient()
orchestrator = Orchestrator(gitlab_tools, llm_client, state_manager)

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
    try:
        if not gitlab_tools.ping():
            logger.warning("gitlab_connection_failed_check_creds")
        else:
            logger.info("gitlab_connected")
    except Exception as e:
        logger.warning("gitlab_init_error", error=str(e))
        
    # Log active agents
    agents = ["PMAgent", "ArchitectAgent", "UMLAgent", "DeveloperAgent", "ReviewAgent", "TestAgent", "SecurityAgent", "DevOpsAgent"]
    logger.info("agents_ready", active_agents=agents)
    
    yield
    logger.info("shutdown")

app = FastAPI(title="ForgeAI - GitLab SDLC Agents", lifespan=lifespan)

@app.get("/health")
def health():
    """Returns application health status."""
    return {"status": "healthy"}

@app.post("/webhook")
async def webhook(
    request: Request, 
    background_tasks: BackgroundTasks,
    x_gitlab_token: str = Header(None),
    x_gitlab_event: str = Header(None)
):
    """
    Main webhook entry point.
    Immediately returns 202 Accepted and processes the pipeline in the background.
    Never fails with 500 to keep GitLab webhook enabled.
    """
    try:
        # Security check
        if not x_gitlab_token or not hmac.compare_digest(x_gitlab_token, settings.GITLAB_WEBHOOK_SECRET):
            logger.warning("webhook_auth_failed")
            return {"status": "ignored", "reason": "unauthorized"}

        try:
            payload = await request.json()
        except Exception as e:
            logger.error("webhook_json_decode_error", error=str(e))
            return {"status": "error", "message": "Invalid JSON"}

        logger.info("webhook_received", event=x_gitlab_event)

        # Process in background to prevent GitLab timeout
        # Using synchronous process_pipeline so FastAPI runs it in a thread pool,
        # ensuring the event loop stays free for other incoming webhooks.
        background_tasks.add_task(process_pipeline, payload, x_gitlab_event)

        return {"status": "accepted", "message": "Pipeline processing started"}
    
    except Exception as e:
        logger.error("webhook_top_level_error", error=str(e))
        return {"status": "error", "message": "Internal error handled"}

def process_pipeline(payload: dict, event_header: str):
    """
    Background task to process the GitLab event through the agents pipeline.
    Safe synchronous execution wrapper.
    """
    try:
        logger.info("pipeline_started", event=event_header)
        
        parsed_payload = None
        event_type = None

        if event_header == "Issue Hook":
            parsed_payload = parser.parse_issue_event(payload)
            event_type = "issue"
        elif event_header == "Push Hook":
            parsed_payload = parser.parse_push_event(payload)
            event_type = "push"
        elif event_header == "Merge Request Hook":
            parsed_payload = parser.parse_mr_event(payload)
            event_type = "merge_request"
        elif event_header == "Note Hook":
            parsed_payload = parser.parse_note_event(payload)
            event_type = "note"
        else:
            logger.info("unhandled_event_type", event_header=event_header)
            return

        if parsed_payload:
            # handle_event is now synchronous
            orchestrator.handle_event(event_type, parsed_payload)
            logger.info("pipeline_completed_successfully", event_type=event_type)
        else:
            logger.warning("payload_parsing_failed", event_header=event_header)

    except Exception as e:
        logger.error("pipeline_execution_error", error=str(e), event=event_header)

if __name__ == "__main__":
    import uvicorn
    import os
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port)
