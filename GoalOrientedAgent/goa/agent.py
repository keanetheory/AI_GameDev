"""The agent's phases: analyse, plan, execute, ask."""
import json
from datetime import datetime

from . import config, prompts
from .llm import Loop
from .tools import Sandbox, READ_TOOL_SCHEMAS, WRITE_TOOL_SCHEMAS


class Agent:
    def __init__(self, client, log, survey, state, say=print, confirm_cmd=None):
        self.loop = Loop(client, log, say)
        self.log, self.survey, self.state, self.say = log, survey, state, say
        self.confirm_cmd = confirm_cmd

    def _system(self, instructions):
        # the survey is the big stable part; cache it so each tool turn re-reads it cheaply
        return [{"type": "text", "text": instructions},
                {"type": "text", "text": self.survey["text"], "cache_control": {"type": "ephemeral"}}]

    def _first_user(self, text, with_images=False):
        blocks = []
        if with_images:
            for label, img in self.survey["images"]:
                blocks += [{"type": "text", "text": f"Concept art: {label}"}, img]
        blocks.append({"type": "text", "text": text, "cache_control": {"type": "ephemeral"}})
        return blocks

    def _state_brief(self):
        return json.dumps({
            "requirements": self.state.requirements,
            "tasks": [{k: t[k] for k in ("id", "title", "priority", "status", "category")} for t in self.state.tasks],
        }, indent=1)

    # ---- phase 2: analyse -------------------------------------------------------------------------
    def analyse(self):
        self.say("\n[ANALYSE] Comparing the docs, concept art and crew briefs with the game. This takes a few minutes.")
        prior = ""
        if self.state.tasks:
            prior = ("\n\nThis is a RE-ANALYSIS. Current state (do not re-propose tasks already done or skipped; keep "
                     "requirement ids stable where the requirement is unchanged):\n" + self._state_brief())
        out = self.loop.run(
            self._system(prompts.ANALYSE),
            self._first_user("Analyse the project now and submit your assessment." + prior, with_images=True),
            READ_TOOL_SCHEMAS, Sandbox(), prompts.SUBMIT_ANALYSIS, max_turns=40, label="Analysis")
        return out

    # ---- phase 4: implications + plan --------------------------------------------------------------
    def plan(self, task):
        self.say(f"\n[PLAN] Working out the implications of {task['id']}: {task['title']}")
        brief = json.dumps(task, indent=1)
        return self.loop.run(
            self._system(prompts.PLAN),
            self._first_user(f"The creator picked this task:\n{brief}\n\nInvestigate and submit the plan."),
            READ_TOOL_SCHEMAS, Sandbox(), prompts.SUBMIT_PLAN, max_turns=25, label=f"Plan {task['id']}")

    # ---- phase 5: execute ---------------------------------------------------------------------------
    def execute(self, task, plan, extra_instruction=""):
        self.say(f"\n[EXECUTE] {task['id']}: {task['title']}")
        sb = Sandbox(writable=True, task_id=f"{task['id']}_{datetime.now():%H%M%S}", confirm=self.confirm_cmd)
        msg = (f"Task:\n{json.dumps(task, indent=1)}\n\nApproved plan:\n{json.dumps(plan, indent=1)}\n\n"
               + (f"Creator's note: {extra_instruction}\n\n" if extra_instruction else "")
               + "Carry out the plan now, then submit the result.")
        result = self.loop.run(self._system(prompts.EXECUTE), self._first_user(msg),
                               READ_TOOL_SCHEMAS + WRITE_TOOL_SCHEMAS, sb, prompts.SUBMIT_RESULT,
                               max_turns=45, label=f"Execute {task['id']}")
        return result, sb

    # ---- Q&A ---------------------------------------------------------------------------------------
    def ask(self, question, history):
        history.append({"role": "user", "content": self._first_user(
            f"Current backlog and requirements:\n{self._state_brief()}\n\nQuestion: {question}")
            if not history else [{"type": "text", "text": question}]})
        return self.loop.chat(self._system(prompts.ASK), history, READ_TOOL_SCHEMAS, Sandbox())
