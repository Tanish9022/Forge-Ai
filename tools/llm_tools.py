import time
import asyncio
import structlog
from google import genai
from google.genai import types
from typing import Optional
from config import settings

logger = structlog.get_logger()

class LLMClient:
    """Wrapper for Google GenAI SDK with retries and logging."""
    
    def __init__(self, api_key: str = settings.GOOGLE_API_KEY, model: str = settings.AGENT_MODEL):
        self.client = genai.Client(api_key=api_key)
        self.model = model

    def call(self, system_prompt: str, user_prompt: str, max_tokens: Optional[int] = None) -> str:
        """Calls the Gemini LLM with backoff retries."""
        max_retries = settings.AGENT_MAX_RETRIES
        delay = 2
        
        for attempt in range(max_retries + 1):
            try:
                response = self.client.models.generate_content(
                    model=self.model,
                    contents=user_prompt,
                    config=types.GenerateContentConfig(
                        system_instruction=system_prompt,
                        max_output_tokens=max_tokens or settings.AGENT_MAX_TOKENS,
                    )
                )
                
                content = response.text
                logger.info("llm_call_success", model=self.model)
                return content
                
            except Exception as e:
                # Handle rate limits (429) or transient errors (500)
                error_str = str(e)
                if "429" in error_str or "500" in error_str:
                    if attempt == max_retries:
                        logger.error("llm_call_failed_max_retries", error=error_str)
                        raise
                    logger.warning("llm_call_retry", attempt=attempt + 1, delay=delay, error=error_str)
                    time.sleep(delay)
                    delay *= 2
                else:
                    logger.error("llm_call_error", error=error_str)
                    raise
        return ""
