import pytest
import asyncio
from unittest.mock import AsyncMock, MagicMock
from orchestrator.orchestrator import Orchestrator
from orchestrator.state import PipelineState

@pytest.fixture
def mock_gitlab():
    return MagicMock()

@pytest.fixture
def mock_llm():
    return MagicMock()

@pytest.fixture
def mock_state_manager():
    sm = MagicMock()
    sm.get_state.return_value = None
    sm.get_context.return_value = {}
    return sm

@pytest.mark.asyncio
async def test_handle_issue_opened(mock_gitlab, mock_llm, mock_state_manager):
    """Test orchestrator routes issue:opened to PMAgent."""
    orchestrator = Orchestrator(mock_gitlab, mock_llm, mock_state_manager)
    
    # Mocking agent's run method
    orchestrator.pm_agent.run = AsyncMock(return_value={"requirements_path": "docs/requirements.md"})
    
    payload = {
        "event_type": "issue",
        "action": "open",
        "project_id": 1,
        "issue_iid": 123,
        "title": "Fix bug",
        "description": "Bug description"
    }
    
    await orchestrator.handle_event("issue", payload)
    
    # Check if agent was called
    orchestrator.pm_agent.run.assert_called_once()
    # Check if state was updated
    mock_state_manager.set_state.assert_any_call(1, 123, PipelineState.REQUIREMENTS_READY)

@pytest.mark.asyncio
async def test_handle_note_approved(mock_gitlab, mock_llm, mock_state_manager):
    """Test orchestrator runs Test and Security agents in parallel on MR approval."""
    orchestrator = Orchestrator(mock_gitlab, mock_llm, mock_state_manager)
    
    orchestrator.test_agent.run = AsyncMock(return_value={"test_paths": ["tests/unit/test_app.py"]})
    orchestrator.security_agent.run = AsyncMock(return_value={"security_verdict": "LOW"})
    
    payload = {
        "event_type": "note",
        "project_id": 1,
        "issue_iid": 123,
        "mr_iid": 456,
        "note": "APPROVED",
        "noteable_type": "MergeRequest"
    }
    
    await orchestrator.handle_event("note", payload)
    
    # Check if both agents were called
    orchestrator.test_agent.run.assert_called_once()
    orchestrator.security_agent.run.assert_called_once()
    # Verify state transition to security ready
    mock_state_manager.set_state.assert_any_call(1, 123, PipelineState.SECURITY_READY)
