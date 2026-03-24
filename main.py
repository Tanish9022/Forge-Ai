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
    
    # Check for critical missing settings
    missing = []
    if not settings.GOOGLE_API_KEY: missing.append("GOOGLE_API_KEY")
    if not settings.GITLAB_TOKEN: missing.append("GITLAB_TOKEN")
    if not settings.GITLAB_PROJECT_ID: missing.append("GITLAB_PROJECT_ID")
    if not settings.GITLAB_WEBHOOK_SECRET: missing.append("GITLAB_WEBHOOK_SECRET")
    
    if missing:
        logger.warning("missing_environment_variables", missing=missing)
    else:
        logger.info("all_critical_env_vars_present")

    # Verify State Manager (Redis or In-Memory fallback)
    manager_type = type(state_manager).__name__
    if not state_manager.ping():
        logger.warning("state_manager_ping_failed", manager=manager_type)
    else:
        logger.info("state_manager_connected", manager=manager_type)
        
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

@app.get("/")
def root():
    """Welcome page with system overview."""
    return {
        "name": "ForgeAI - GitLab SDLC Agents",
        "status": "active",
        "version": "1.0.0",
        "endpoints": {
            "health": "/health",
            "webhook": "/webhook (POST)"
        },
        "links": {
            "docs": "/docs",
            "repository": "https://gitlab.com/Tanish98/ai-sdlc-agent"
        }
    }

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
    print(f"WEBHOOK RECEIVED: {x_gitlab_event}")
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
        
        # Event Type Mapping
        event_map = {
            "Issue Hook": "issue",
            "Push Hook": "push",
            "Merge Request Hook": "merge_request",
            "Note Hook": "note"
        }
        
        mapped_event = event_map.get(x_gitlab_event)
        print(f"EVENT DETECTED: {mapped_event}")

        if not mapped_event:
            print(f"UNHANDLED EVENT: {x_gitlab_event}")
            return {"status": "ignored", "reason": "unhandled_event"}

        # Process in background to prevent GitLab timeout
        background_tasks.add_task(process_pipeline, payload, mapped_event)

        return {"status": "accepted", "message": "Pipeline processing started"}
    
    except Exception as e:
        logger.error("webhook_top_level_error", error=str(e))
        return {"status": "error", "message": "Internal error handled"}

def process_pipeline(payload: dict, event_type: str):
    """
    Background task to process the GitLab event through the agents pipeline.
    Safe synchronous execution wrapper.
    """
    print("PIPELINE STARTED")
    try:
        logger.info("pipeline_started", event=event_type)
        
        parsed_payload = None

        if event_type == "issue":
            parsed_payload = parser.parse_issue_event(payload)
        elif event_type == "push":
            parsed_payload = parser.parse_push_event(payload)
        elif event_type == "merge_request":
            parsed_payload = parser.parse_mr_event(payload)
        elif event_type == "note":
            parsed_payload = parser.parse_note_event(payload)

        print(f"PARSED PAYLOAD: {parsed_payload}")

        if not parsed_payload:
            print(f"ERROR: Payload parsing failed for {event_type}")
            logger.warning("payload_parsing_failed", event_type=event_type)
            return

        project_id = parsed_payload.get("project_id")
        issue_iid = parsed_payload.get("issue_iid") or parsed_payload.get("mr_iid")

        # Validate required fields
        if not project_id:
            print("ERROR: project_id missing", payload)
            return
            
        if event_type in ["issue", "note", "merge_request"] and not issue_iid:
            print("ERROR: issue_iid missing", payload)
            return

        print(f"CALLING ORCHESTRATOR: {event_type}")
        # handle_event is now synchronous
        orchestrator.handle_event(event_type, parsed_payload)
        logger.info("pipeline_completed_successfully", event_type=event_type)

    except Exception as e:
        print(f"PIPELINE ERROR: {str(e)}")
        logger.error("pipeline_execution_error", error=str(e), event=event_type)

if __name__ == "__main__":
    import uvicorn
    import os
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port)
