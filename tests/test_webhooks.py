import pytest
from fastapi.testclient import TestClient
from main import app
from config import settings, GITLAB_WEBHOOK_SECRET

client = TestClient(app)

def test_webhook_unauthorized():
    """Test webhook with missing or invalid token."""
    response = client.post("/webhook", headers={"X-Gitlab-Token": "invalid"})
    assert response.status_code == 401

def test_webhook_valid_issue():
    """Test webhook with valid issue payload."""
    payload = {
        "object_attributes": {
            "action": "open",
            "iid": 1,
            "title": "Test Issue",
            "description": "Test Description"
        },
        "project": {"id": 123}
    }
    headers = {
        "X-Gitlab-Token": GITLAB_WEBHOOK_SECRET,
        "X-Gitlab-Event": "Issue Hook"
    }
    response = client.post("/webhook", json=payload, headers=headers)
    assert response.status_code == 200
    assert response.json()["status"] == "accepted"

def test_health_endpoint():
    """Test the health check endpoint."""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"
