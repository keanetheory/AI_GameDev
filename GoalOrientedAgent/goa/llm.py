"""The model call and the tool loop shared by every phase."""
import json

from . import config
from .tools import ToolError


class Loop:
    """Runs a model <-> tools loop until the model calls a 'final' tool (its structured answer)."""

    def __init__(self, client, log, say=print):
        self.client, self.log, self.say = client, log, say

    def run(self, system, first_user, tools, sandbox, final_tool, max_turns=30, max_tokens=20000, label=""):
        """system: list of text blocks. first_user: list of content blocks. Returns the final tool's input dict."""
        schemas = tools + [final_tool]
        messages = [{"role": "user", "content": first_user}]
        for turn in range(1, max_turns + 1):
            if turn == max_turns - 2:
                messages[-1]["content"] = _with_note(messages[-1]["content"],
                    f"You are nearly out of turns. Call {final_tool['name']} now with what you have.")
            with self.client.messages.stream(model=config.MODEL, max_tokens=max_tokens, system=system,
                                             tools=schemas, messages=messages) as stream:
                resp = stream.get_final_message()
            messages.append({"role": "assistant", "content": [b.model_dump(exclude_none=True) for b in resp.content]})
            text = "".join(b.text for b in resp.content if b.type == "text").strip()
            if text:
                self.log.add(f"{label} - model note", text)
            uses = [b for b in resp.content if b.type == "tool_use"]
            if resp.stop_reason == "max_tokens" and not uses:
                raise RuntimeError("The model ran out of output tokens before finishing.")
            if not uses:
                messages.append({"role": "user", "content": [{"type": "text",
                    "text": f"Continue, and finish by calling {final_tool['name']}."}]})
                continue
            results, final = [], None
            for u in uses:
                if u.name == final_tool["name"]:
                    final = u.input
                    results.append({"type": "tool_result", "tool_use_id": u.id, "content": "Received."})
                    continue
                self.say(f"   . {u.name} {_brief(u.input)}")
                try:
                    out = sandbox.call(u.name, u.input)
                    is_err = False
                except ToolError as e:
                    out, is_err = f"ERROR: {e}", True
                except Exception as e:  # keep the loop alive on unexpected tool failures
                    out, is_err = f"ERROR: {type(e).__name__}: {e}", True
                self.log.add_tool(u.name, u.input, out if isinstance(out, str) else "[image]", is_err)
                content = out if isinstance(out, list) else ([out] if isinstance(out, dict) else out)
                results.append({"type": "tool_result", "tool_use_id": u.id, "content": content, "is_error": is_err})
            messages.append({"role": "user", "content": results})
            if final is not None:
                self.log.add(f"{label} - structured result", "```json\n" + json.dumps(final, indent=2) + "\n```")
                return final
        raise RuntimeError(f"No result after {max_turns} turns.")

    def chat(self, system, messages, tools, sandbox, max_turns=12):
        """Free-form Q&A with read tools. Returns the answer text."""
        for _ in range(max_turns):
            with self.client.messages.stream(model=config.MODEL, max_tokens=6000, system=system,
                                             tools=tools, messages=messages) as stream:
                resp = stream.get_final_message()
            messages.append({"role": "assistant", "content": [b.model_dump(exclude_none=True) for b in resp.content]})
            uses = [b for b in resp.content if b.type == "tool_use"]
            if not uses:
                return "".join(b.text for b in resp.content if b.type == "text").strip()
            results = []
            for u in uses:
                self.say(f"   . {u.name} {_brief(u.input)}")
                try:
                    out, is_err = sandbox.call(u.name, u.input), False
                except Exception as e:
                    out, is_err = f"ERROR: {e}", True
                self.log.add_tool(u.name, u.input, out if isinstance(out, str) else "[image]", is_err)
                content = [out] if isinstance(out, dict) else out
                results.append({"type": "tool_result", "tool_use_id": u.id, "content": content, "is_error": is_err})
            messages.append({"role": "user", "content": results})
        return "(ran out of turns)"


def _brief(args: dict) -> str:
    s = ", ".join(f"{k}={str(v)[:60]!r}" for k, v in args.items() if k not in {"content", "old_string", "new_string"})
    return s[:110]


def _with_note(content, note):
    content = list(content) if isinstance(content, list) else [{"type": "text", "text": content}]
    return content + [{"type": "text", "text": note}]
