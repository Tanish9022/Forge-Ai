import json
from enum import Enum
from typing import Any, Dict, Optional, Protocol
import redis
import structlog
from config import settings

logger = structlog.get_logger()

class PipelineState(str, Enum):
    """Possible states for the SDLC pipeline."""
    ISSUE_CREATED = "ISSUE_CREATED"
    REQUIREMENTS_READY = "REQUIREMENTS_READY"
    ARCHITECTURE_READY = "ARCHITECTURE_READY"
    UML_READY = "UML_READY"
    CODE_READY = "CODE_READY"
    REVIEW_APPROVED = "REVIEW_APPROVED"
    TESTS_READY = "TESTS_READY"
    SECURITY_READY = "SECURITY_READY"
    DEPLOYING = "DEPLOYING"
    DONE = "DONE"
    HUMAN_INTERVENTION_REQUIRED = "HUMAN_INTERVENTION_REQUIRED"
    FAILED = "FAILED"

class StateManagerInterface(Protocol):
    def get_state(self, project_id: int, issue_id: int) -> Optional[PipelineState]: ...
    def set_state(self, project_id: int, issue_id: int, state: PipelineState) -> None: ...
    def get_context(self, project_id: int, issue_id: int) -> Dict[str, Any]: ...
    def update_context(self, project_id: int, issue_id: int, data: Dict[str, Any]) -> None: ...
    def clear(self, project_id: int, issue_id: int) -> None: ...
    def ping(self) -> bool: ...

class RedisStateManager:
    """Manages pipeline state and context storage in Redis."""
    def __init__(self, redis_url: str = settings.REDIS_URL):
        self._redis = redis.from_url(redis_url, decode_responses=True)

    def _get_state_key(self, project_id: int, issue_id: int) -> str:
        return f"sdlc:{project_id}:{issue_id}:state"

    def _get_context_key(self, project_id: int, issue_id: int) -> str:
        return f"sdlc:{project_id}:{issue_id}:context"

    def get_state(self, project_id: int, issue_id: int) -> Optional[PipelineState]:
        try:
            state = self._redis.get(self._get_state_key(project_id, issue_id))
            return PipelineState(state) if state else None
        except redis.RedisError:
            return None

    def set_state(self, project_id: int, issue_id: int, state: PipelineState) -> None:
        self._redis.set(self._get_state_key(project_id, issue_id), state.value)

    def get_context(self, project_id: int, issue_id: int) -> Dict[str, Any]:
        context = self._redis.get(self._get_context_key(project_id, issue_id))
        return json.loads(context) if context else {}

    def update_context(self, project_id: int, issue_id: int, data: Dict[str, Any]) -> None:
        context = self.get_context(project_id, issue_id)
        context.update(data)
        self._redis.set(self._get_context_key(project_id, issue_id), json.dumps(context))

    def clear(self, project_id: int, issue_id: int) -> None:
        self._redis.delete(self._get_state_key(project_id, issue_id))
        self._redis.delete(self._get_context_key(project_id, issue_id))

    def ping(self) -> bool:
        try:
            return self._redis.ping()
        except Exception:
            return False

class DictStateManager:
    """In-memory fallback for state management (non-persistent)."""
    def __init__(self):
        self._states: Dict[str, PipelineState] = {}
        self._contexts: Dict[str, Dict[str, Any]] = {}

    def _key(self, project_id: int, issue_id: int) -> str:
        return f"{project_id}:{issue_id}"

    def get_state(self, project_id: int, issue_id: int) -> Optional[PipelineState]:
        return self._states.get(self._key(project_id, issue_id))

    def set_state(self, project_id: int, issue_id: int, state: PipelineState) -> None:
        self._states[self._key(project_id, issue_id)] = state

    def get_context(self, project_id: int, issue_id: int) -> Dict[str, Any]:
        return self._contexts.get(self._key(project_id, issue_id), {})

    def update_context(self, project_id: int, issue_id: int, data: Dict[str, Any]) -> None:
        key = self._key(project_id, issue_id)
        if key not in self._contexts:
            self._contexts[key] = {}
        self._contexts[key].update(data)

    def clear(self, project_id: int, issue_id: int) -> None:
        key = self._key(project_id, issue_id)
        self._states.pop(key, None)
        self._contexts.pop(key, None)

    def ping(self) -> bool:
        return True

def get_state_manager() -> StateManagerInterface:
    """Factory to return either Redis or In-Memory state manager."""
    try:
        mgr = RedisStateManager()
        if mgr.ping():
            return mgr
    except Exception:
        pass
    
    logger.warning("redis_unavailable_using_in_memory_state")
    return DictStateManager()

# Global instance for easy use
state_manager = get_state_manager()
