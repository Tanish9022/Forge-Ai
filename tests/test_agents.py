import pytest
from unittest.mock import AsyncMock, MagicMock
from agents.pm_agent import PMAgent
from agents.review_agent import ReviewAgent

@pytest.fixture
def mock_gitlab():
    gl = MagicMock()
    gl.get_issue.return_value = {"title": "Test Title", "description": "Test Description"}
    return gl

@pytest.fixture
def mock_llm():
    return MagicMock()

@pytest.fixture
def mock_state_manager():
    return MagicMock()

@pytest.mark.asyncio
async def test_pm_agent_run(mock_gitlab, mock_llm, mock_state_manager):
    """Test PMAgent generates and commits requirements."""
    agent = PMAgent(mock_gitlab, mock_llm, mock_state_manager)
    mock_llm.call.return_value = "Generated requirements content"
    
    context = {"project_id": 1, "issue_iid": 123}
    result = await agent.run(context)
    
    assert result["requirements_path"] == "docs/requirements.md"
    mock_gitlab.commit_file.assert_called_with(
        branch="ai-sdlc/issue-123",
        file_path="docs/requirements.md",
        content="Generated requirements content",
        commit_message="docs: define requirements for issue #123"
    )

@pytest.mark.asyncio
async def test_review_agent_parsing(mock_gitlab, mock_llm, mock_state_manager):
    """Test ReviewAgent parses JSON responses correctly."""
    agent = ReviewAgent(mock_gitlab, mock_llm, mock_state_manager)
    
    # JSON with markdown markers
    mock_llm.call.return_value = '```json\n{"verdict": "APPROVED", "issues": []}\n```'
    
    context = {"mr_iid": 456}
    result = await agent.run(context)
    
    assert result["review_verdict"] == "APPROVED"
    assert len(result["review_issues"]) == 0
