# GitLab SDLC Agents: Essential Commands

This guide provides a comprehensive list of commands for running, testing, and maintaining the GitLab SDLC agent system.

## 🚀 Running the Server

### 1. Activate Virtual Environment
```powershell
# Windows
.\.venv\Scripts\Activate.ps1

# Linux/macOS
source .venv/bin/activate
```

### 2. Start the FastAPI Server
```powershell
# Development mode with hot-reload
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 3. Alternative Execution (Windows)
If you don't want to activate the environment:
```powershell
.\.venv\Scripts\uvicorn.exe main:app --reload --host 0.0.0.0 --port 8000
```

---

## 🧪 Testing & Quality

### Run All Tests
```powershell
pytest
```

### Run Tests with Coverage
```powershell
pytest --cov=agents --cov=orchestrator
```

### Linting & Formatting
```powershell
# Check formatting
ruff check .

# Fix formatting
ruff format .

# Type checking
mypy .
```

---

## 🛠️ Troubleshooting & Utilities

### Check Port 8000 (Windows)
If the server fails to start because the port is in use:
```powershell
# Find and stop the process using port 8000
Stop-Process -Id (Get-NetTCPConnection -LocalPort 8000).OwningProcess -Force
```

### Verify Redis Connection
```powershell
redis-cli ping
# Should return "PONG"
```

### Verify GitLab Webhook Payload
You can use `curl` to simulate a webhook event (replace with your secret):
```powershell
curl -X POST "http://localhost:8000/webhook" `
     -H "X-Gitlab-Token: YOUR_SECRET" `
     -H "X-Gitlab-Event: Issue Hook" `
     -H "Content-Type: application/json" `
     -d '{ "object_kind": "issue", "project": { "id": 123 }, "object_attributes": { "iid": 1, "action": "open" } }'
```

---

## 📦 Dependency Management

### Install Development Dependencies
```powershell
pip install -e ".[dev]"
```

### Update Requirements
If you add new packages to `pyproject.toml`:
```powershell
pip install -e .
```

---

## 📡 Monitoring

### Check Health Status
```powershell
# Using PowerShell
Invoke-RestMethod -Uri "http://localhost:8000/health"

# Using curl
curl http://localhost:8000/health
```
