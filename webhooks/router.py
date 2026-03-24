import hmac
import structlog
from fastapi import APIRouter, Header, Request, HTTPException, BackgroundTasks
from config import settings, GITLAB_WEBHOOK_SECRET
from webhooks import parser
from orchestrator.orchestrator import Orchestrator
from tools.gitlab_tools import GitLabTools
from tools.llm_tools import LLMClient
from orchestrator.state import state_manager

router = APIRouter(prefix="/webhook")
logger = structlog.get_logger()

# Dependencies will be injected or initialized here
gitlab_tools = GitLabTools()
llm_client = LLMClient()
# Use the global state_manager
orchestrator = Orchestrator(gitlab_tools, llm_client, state_manager)

@router.post("")
async def handle_webhook(
    request: Request,
    background_tasks: BackgroundTasks,
    x_gitlab_token: str = Header(None),
    x_gitlab_event: str = Header(None)
):
    """Main webhook entry point."""
    if not x_gitlab_token or not hmac.compare_digest(x_gitlab_token, GITLAB_WEBHOOK_SECRET):
        logger.warning("invalid_webhook_token")
        raise HTTPException(status_code=401, detail="Invalid token")

    payload = await request.json()
    
    parsed_payload = None
    if x_gitlab_event == "Issue Hook":
        parsed_payload = parser.parse_issue_event(payload)
        event_type = "issue"
    elif x_gitlab_event == "Push Hook":
        parsed_payload = parser.parse_push_event(payload)
        event_type = "push"
    elif x_gitlab_event == "Merge Request Hook":
        parsed_payload = parser.parse_mr_event(payload)
        event_type = "merge_request"
    elif x_gitlab_event == "Note Hook":
        parsed_payload = parser.parse_note_event(payload)
        event_type = "note"
    else:
        logger.info("unhandled_event", event_header=x_gitlab_event)
        return {"status": "ignored", "event": x_gitlab_event}

    if parsed_payload:
        logger.info("webhook_received", event_name=event_type)
        background_tasks.add_task(orchestrator.handle_event, event_type, parsed_payload)
        
    return {"status": "accepted", "event": event_type}
