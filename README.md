# GitLab AI-powered SDLC Agent System

A production-ready, multi-agent SDLC automation system powered by **Google Gemini 1.5 Pro**. This system automates the entire software development lifecycle—from issue creation to deployment—by orchestrating specialized AI agents via GitLab webhooks.

## 🚀 Features

- **PMAgent**: Transforms GitLab issues into structured requirements (`docs/requirements.md`).
- **ArchitectAgent**: Generates high-level architecture designs from requirements.
- **UMLAgent**: Generates specific PlantUML diagrams (Sequence, Component, and Architecture diagrams).
- **DeveloperAgent**: Implements application code based on designs and opens Merge Requests.
- **ReviewAgent**: Performs automated architectural and code quality reviews on Merge Requests.
- **TestAgent**: Generates pytest suites and configures CI/CD test stages.
- **SecurityAgent**: Scans for vulnerabilities, generates reports, and ensures security compliance.
- **DevOpsAgent**: Configures Docker, finalizes `.gitlab-ci.yml`, and monitors pipelines.

## 🛠️ Prerequisites

- **Python 3.11+**
- **Redis Server**: Used for state management and context persistence.
- **GitLab Instance**: A project where you have maintainer access.
- **Google Gemini API Key**: For LLM-powered reasoning.

## 📦 Installation

1. **Clone the repository:**
   ```bash
   cd gitlab-sdlc-agents
   ```

2. **Create a virtual environment and install dependencies:**
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   pip install -e ".[dev]"
   ```

3. **Configure Environment Variables:**
   Copy the example environment file and fill in your credentials:
   ```bash
   cp .env.example .env
   ```
   Edit `.env`:
   - `GOOGLE_API_KEY`: Your Gemini API key.
   - `GITLAB_TOKEN`: Personal Access Token with `api` scope.
   - `GITLAB_PROJECT_ID`: The ID of your GitLab project.
   - `GITLAB_WEBHOOK_SECRET`: A random string for securing your webhook.
   - `REDIS_URL`: (Optional) Custom Redis connection string.

## 🚦 Running the System

1. **Start Redis:**
   Ensure your Redis server is running (default: `localhost:6379`).

2. **Start the FastAPI Server:**
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

3. **Expose to the Internet (for Webhooks):**
   If running locally, use a tool like `ngrok` to expose your local port 8000:
   ```bash
   ngrok http 8000
   ```

4. **Configure GitLab Webhook:**
   - Go to **Settings > Webhooks** in your GitLab project.
   - URL: `https://your-public-url.com/webhook`
   - Secret Token: The `GITLAB_WEBHOOK_SECRET` from your `.env`.
   - Trigger: Select **Push events**, **Comments**, **Issues events**, and **Merge request events**.

## 🔄 Workflow

1. **Trigger**: Create a new Issue in GitLab.
2. **Requirements**: `PMAgent` creates a feature branch and `docs/requirements.md`.
3. **Architecture**: `ArchitectAgent` generates high-level designs.
4. **UML Diagrams**: `UMLAgent` generates detailed PlantUML diagrams (`.puml`).
5. **Implementation**: `DeveloperAgent` generates the code and opens a Merge Request.
6. **Review**: `ReviewAgent` comments on the MR with code quality feedback.
7. **Testing & Security**: Once the MR is commented with "APPROVED", `TestAgent` and `SecurityAgent` run in parallel.
8. **Deployment**: `DevOpsAgent` triggers the final CI/CD pipeline and monitors for success.

## 📡 Health & Monitoring

The system includes a health check endpoint:
- **Health Check**: `GET /health` - Returns uptime, version, and connection status for Redis and GitLab.

## 🧪 Testing

Run the test suite to ensure everything is configured correctly:
```bash
pytest
```

