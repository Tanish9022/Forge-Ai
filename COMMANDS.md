# GitLab SDLC Agents: Running the Server

If you encounter a `CommandNotFoundException` for `uvicorn`, it is likely because the correct virtual environment is not active. Use the following commands to run the project correctly on Windows.

## 1. Activate the Correct Virtual Environment
The dependencies (including `uvicorn`) are installed in the `.venv` folder.

```powershell
# Activate the environment
.\.venv\Scripts\Activate.ps1
```

## 2. Run the FastAPI Server
Once activated, you can run the server using `uvicorn`:

```powershell
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Alternative: Run without Activation
If you don't want to activate the environment, you can call the executable directly:

```powershell
.\.venv\Scripts\uvicorn.exe main:app --reload --host 0.0.0.0 --port 8000
```

### Alternative: Run as a Python Module
Sometimes using the Python module syntax is more reliable:

```powershell
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

---

## 🛠️ Troubleshooting

### "uvicorn : The term 'uvicorn' is not recognized..."
This means you are either:
1. Not in a virtual environment.
2. In the wrong virtual environment (e.g., `venv` instead of `.venv`).

**Fix:** Ensure your terminal prompt shows `(.venv)` at the start. If it shows `(venv)`, you are in the wrong one. Run `deactivate` and then `.\.venv\Scripts\Activate.ps1`.

### "Running uvicorn ... on Windows" (but no output)
If the server starts but you don't see logs, check if another process is using port 8000:
```powershell
Stop-Process -Id (Get-NetTCPConnection -LocalPort 8000).OwningProcess -Force
```
