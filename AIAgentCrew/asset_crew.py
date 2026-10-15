"""Asset review crew - CrewAI pipeline for Lighting the Storm.

One agent, run once per FAL submission:

  Asset agent   FalSubmission + style guide + deterministic findings  ->  AssetReview

The agent checks that the prompt, negative prompt and source image tie into
Docs/Lore Build/world/style_guide.md, rewrites the prompt where it does not, and says where the
finished model goes in Godot. The style guide is read live (style_guide.py). The guardrail refuses an
APPROVE when the deterministic checks found problems, and refuses a revised prompt that still breaks the guide.
"""
import json

from crewai import Agent, Crew, Process, Task

from roles import ASSET_PIPELINE
from style_guide import StyleGuide, style_block
from world_canon import ASSET_FOLDERS
from world_schemas import AssetReview, FalSubmission
from world_validators import check_asset_review

from validators import parse

JSON_RULE = (
    "Respond with ONLY a single JSON object that matches the JSON schema below. "
    "No markdown fences, no commentary. Use only single quotes inside text values.\nJSON SCHEMA:\n"
)


def build_asset_crew(llm, guide: StyleGuide, sub: FalSubmission, findings: list[str], metrics: dict,
                     verbose: bool = True, state: dict | None = None):
    """Return (crew, state). state['review'] holds the validated AssetReview."""
    state = {} if state is None else state

    def review_guard(out):
        review, err = parse(out.raw, AssetReview)
        if err:
            return False, err
        problems = check_asset_review(review, sub, findings, guide)
        if problems:
            return False, "Fix these contract violations: " + " | ".join(problems)
        state["review"] = review
        return True, review.model_dump_json(indent=2)

    asset_agent = Agent(
        role=ASSET_PIPELINE[0],
        goal="Make sure every FAL submission ties into the locked style guide before it is generated, and say how to import it.",
        backstory=(
            "You are the art gatekeeper for Lighting the Storm, a gritty dark cel-shaded folk-horror game set in the "
            "mid-to-late 1800s. You know the style guide by heart. You never name reference touchstones, real artists "
            "or franchises in prompts. You write prompts that image-to-3D models can follow: one object, clear "
            "silhouette, neutral background, the guide's style descriptors, the guide's palette. You also know Godot 4: "
            "scale in metres, pivot at the base, collision for anything walkable."
        ),
        llm=llm, allow_delegation=False, verbose=verbose, max_iter=5,
    )
    task = Task(
        description=(
            f"[TASK ASSET_REVIEW]\n{style_block(guide)}\n\n"
            f"GODOT TARGET FOLDERS: {json.dumps(ASSET_FOLDERS)}\n\n"
            f"SUBMISSION:\n{sub.model_dump_json(indent=1)}\n\n"
            f"DETERMINISTIC FINDINGS (already verified, treat as true): {json.dumps(findings)}\n"
            f"IMAGE METRICS: {json.dumps(metrics)}\n\n"
            "Review the submission against the style guide. Write at least four style_checks (for example: style "
            "descriptors, palette, era and tone, negative prompt, source image) each with result pass or fail and "
            "evidence. verdict is APPROVE only if there are no findings and every check passes, otherwise REVISE "
            "with the issues listed. Always give a revised_prompt and revised_negative_prompt that pass every check "
            "(keep the creator's subject and intent; add the style descriptors and palette colours; the negative "
            "prompt must contain every global negative). godot_target_folder must be the folder for the category. "
            "import_notes must cover scale (metres), pivot, collision and materials for Godot 4.3. summary is one "
            f"or two factual sentences.\n\n{JSON_RULE}{json.dumps(AssetReview.model_json_schema(), indent=1)}"
        ),
        expected_output="An AssetReview JSON object.",
        agent=asset_agent,
        guardrail=review_guard,
        guardrail_max_retries=3,
    )
    crew = Crew(agents=[asset_agent], tasks=[task], process=Process.sequential, verbose=verbose)
    return crew, state
