import json
import hmac
import structlog
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, BackgroundTasks, Header, Response
from typing import Optional
from tools.gitlab_tools import GitLabTools
from tools.llm_tools import LLMClient
from orchestrator.orchestrator import Orchestrator
from orchestrator.state import state_manager
from webhooks import parser
from config import settings, GEMINI_API_KEY, GITLAB_TOKEN, GITLAB_PROJECT_ID, GITLAB_WEBHOOK_SECRET
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
    x_gitlab_token: Optional[str] = Header(None),
    x_gitlab_event: Optional[str] = Header(None)
):
    """
    Main webhook entry point.
    Returns 202 immediately to prevent GitLab timeout.
    """
    try:
        # 1. Fast security check (constant time)
        if not x_gitlab_token or not hmac.compare_digest(x_gitlab_token, GITLAB_WEBHOOK_SECRET):
            return Response(content=json.dumps({"status": "ignored", "reason": "unauthorized"}), status_code=401, media_type="application/json")

        # 2. Receive raw body asynchronously (fast)
        body = await request.body()
        
        # 3. Offload ALL processing to background task to ensure 202 is sent ASAP
        background_tasks.add_task(process_pipeline, body, x_gitlab_event)

        return Response(content=json.dumps({"status": "accepted"}), status_code=202, media_type="application/json")
    
    except Exception as e:
        logger.error("webhook_top_level_error", error=str(e))
        return Response(content=json.dumps({"status": "error"}), status_code=200, media_type="application/json")

def process_pipeline(body: bytes, event_header: str):
    """
    Background task to parse and process the GitLab event.
    Runs in a thread pool to avoid blocking the event loop.
    """
    print("PIPELINE BACKGROUND TASK STARTED")
    try:
        payload = json.loads(body)
        
        # Event Type Mapping
        event_map = {
            "Issue Hook": "issue",
            "Push Hook": "push",
            "Merge Request Hook": "merge_request",
            "Note Hook": "note"
        }
        
        event_type = event_map.get(event_header)
        print("PIPELINE STARTED")
        print("EVENT TYPE:", event_type)
        
        if not event_type:
            print(f"UNHANDLED EVENT: {event_header}")
            return

        logger.info("pipeline_started", event_type=event_type)
        
        parsed_payload = None
        if event_type == "issue":
            parsed_payload = parser.parse_issue_event(payload)
        elif event_type == "push":
            parsed_payload = parser.parse_push_event(payload)
        elif event_type == "merge_request":
            parsed_payload = parser.parse_mr_event(payload)
        elif event_type == "note":
            parsed_payload = parser.parse_note_event(payload)

        if not parsed_payload:
            print(f"ERROR: Payload parsing failed for {event_type}")
            return

        project_id = parsed_payload.get("project_id")
        issue_iid = parsed_payload.get("issue_iid") or parsed_payload.get("mr_iid")
        print("ISSUE IID:", issue_iid)

        # Validate required fields
        if not project_id:
            print("ERROR: project_id missing", payload)
            return
            
        if event_type in ["issue", "note", "merge_request"] and not issue_iid:
            print("ERROR: issue_iid missing", payload)
            return

        print("PIPELINE STARTED")
        print(f"CALLING ORCHESTRATOR: {event_type}")
        orchestrator.handle_event(event_type, parsed_payload)
        logger.info("pipeline_completed_successfully", event_type=event_type)

    except Exception as e:
        print(f"PIPELINE ERROR: {str(e)}")
        logger.error("pipeline_execution_error", error=str(e), event_type=event_header)

if __name__ == "__main__":
    import uvicorn
    import os
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port)
