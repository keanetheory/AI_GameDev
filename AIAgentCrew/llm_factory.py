"""Builds the real LLM the crews use (same settings as main_dialogue.py)."""
import os
import sys


def make_real_llm():
    """Return a crewai LLM, or None (after printing why) if no API key is set."""
    from crewai import LLM
    model = os.getenv("CREW_MODEL", "anthropic/claude-sonnet-5-5")
    key_var = {"anthropic": "ANTHROPIC_API_KEY", "openai": "OPENAI_API_KEY",
               "gemini": "GEMINI_API_KEY"}.get(model.split("/")[0])
    if key_var and not os.getenv(key_var):
        print(f"[crew] {key_var} is not set for model '{model}'. Add it to .env, or run with --offline.",
              file=sys.stderr)
        return None
    extra = {}
    workspace = os.getenv("ANTHROPIC_WORKSPACE_ID")
    if workspace:  # needed when the API key is not scoped to a workspace
        extra["client_params"] = {"default_headers": {"anthropic-workspace-id": workspace}}
    return LLM(model=model, max_tokens=16000, **extra)  # no temperature: newer models reject it
