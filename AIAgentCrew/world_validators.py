"""Deterministic checks for the Asset, Boat, Player Movement and Lighting agents.

Same role as validators.py: they run as CrewAI guardrails (a failing agent gets the errors back and
retries) and again in the integrator before any file is written.
"""
import re
from pathlib import Path

from schemas import ReviewReport
from style_guide import StyleGuide, check_image, check_negative_prompt, check_prompt
from validators import TIMER_WORDS, check_review  # noqa: F401  (check_review re-exported for the integrator)
from world_canon import ASSET_FOLDERS
from world_schemas import AssetReview, BoatSpec, FalSubmission, LightingSpec, PlayerMovementSpec

HEX = re.compile(r"^#[0-9A-Fa-f]{6}$")


# ---------------- Asset agent ----------------
def check_submission(sub: FalSubmission, guide: StyleGuide, base_dir: Path | None = None) -> tuple[list[str], dict]:
    """Deterministic findings on a creator's FAL submission. Returns (findings, image_metrics)."""
    findings = check_prompt(sub.prompt, guide) + check_negative_prompt(sub.negative_prompt, guide)
    low = sub.prompt.lower()
    if sub.category == "saint_calder_city" and not ("amber" in low or "gold" in low):
        findings.append("Saint Calder prompts must carry its amber and gold glow (style guide colour meanings).")
    if sub.category == "saint_calder_city" and "gothic" not in low:
        findings.append("Saint Calder prompts must say 'gothic' (1800s Gothic cathedral skyline).")
    metrics: dict = {}
    if sub.source_image:
        path = Path(sub.source_image)
        if not path.is_absolute() and base_dir:
            path = base_dir / path
        if not path.exists():
            findings.append(f"source_image not found: {sub.source_image}")
        else:
            image_errs, metrics = check_image(path, guide)
            findings += image_errs
    return findings, metrics


def check_asset_review(review: AssetReview, sub: FalSubmission, findings: list[str], guide: StyleGuide) -> list[str]:
    errs = []
    if review.asset_id != sub.asset_id:
        errs.append(f"asset_id must be '{sub.asset_id}', got '{review.asset_id}'.")
    want = ASSET_FOLDERS[sub.category]
    if review.godot_target_folder != want:
        errs.append(f"godot_target_folder for category '{sub.category}' must be '{want}'.")
    if findings and review.verdict == "APPROVE":
        errs.append("Verdict is APPROVE but the deterministic style checks found problems: " + " | ".join(findings))
    if review.verdict == "REVISE" and not review.issues:
        errs.append("A REVISE verdict must list the issues.")
    errs += [f"revised_prompt: {e}" for e in check_prompt(review.revised_prompt, guide)]
    errs += [f"revised_negative_prompt: {e}" for e in check_negative_prompt(review.revised_negative_prompt, guide)]
    notes = " ".join(review.import_notes).lower()
    for word in ("scale", "collision", "pivot"):
        if word not in notes:
            errs.append(f"import_notes must cover {word}.")
    return errs


# ---------------- Boat agent ----------------
def check_boat(b: BoatSpec) -> list[str]:
    errs = []
    if not 2.0 <= b.speed_mps <= 12.0:
        errs.append(f"speed_mps {b.speed_mps} is outside 2-12 m/s (creator chose 8 m/s on 2026-10-20; the GDD says 10).")
    if b.steer_left_action != "move_left" or b.steer_right_action != "move_right":
        errs.append("Steering must use the move_left and move_right actions (A and D).")
    if b.throttle_actions:
        errs.append(f"The boat has one fixed speed: throttle_actions must be empty, got {b.throttle_actions}.")
    if not re.search(r"\b(nothing|no effect|ignored|unused)\b", b.other_move_keys_do, re.I):
        errs.append("other_move_keys_do must state that W and S have no effect on the boat.")
    if not 20 <= b.max_turn_rate_deg_s <= 60:
        errs.append("max_turn_rate_deg_s must be 20-60 so a first-time player can steer through gaps without spinning.")
    if not 0.1 <= b.steer_response_s <= 1.0:
        errs.append("steer_response_s must be 0.1-1.0 s so steering is smooth but responsive.")
    if not b.rudder_returns_to_centre:
        errs.append("rudder_returns_to_centre must be true so releasing A and D flies the boat straight.")
    if not re.search(r"tide|wave", b.tide_hook, re.I):
        errs.append("tide_hook must name where a tide or wave force plugs in later.")
    legs = {l.leg_id: l for l in b.legs}
    if list(legs) != ["OUTBOUND", "RETURN"]:
        errs.append("legs must be OUTBOUND then RETURN.")
    else:
        o, r = legs["OUTBOUND"], legs["RETURN"]
        if (o.from_zone, o.to_zone) != ("DOCK_LIGHTHOUSE", "DOCK_PORT"):
            errs.append("OUTBOUND must run DOCK_LIGHTHOUSE -> DOCK_PORT.")
        if (r.from_zone, r.to_zone) != ("DOCK_PORT", "DOCK_LIGHTHOUSE"):
            errs.append("RETURN must run DOCK_PORT -> DOCK_LIGHTHOUSE.")
        for leg in (o, r):
            ms = [w.route_m for w in leg.waypoints]
            if ms != sorted(ms) or ms[0] != 0 or ms[-1] > leg.length_m:
                errs.append(f"{leg.leg_id} waypoints must ascend from 0 and stay within length_m {leg.length_m}.")
            if not 1000 <= leg.length_m <= 2000:
                errs.append(f"{leg.leg_id} length_m {leg.length_m} should be 1000-2000 (lore: 1-2 km).")
        if abs(o.length_m - r.length_m) > 0.1 * o.length_m:
            errs.append("OUTBOUND and RETURN are the same water; their lengths should match within 10%.")
    if {d.zone_id for d in b.docks} != {"DOCK_LIGHTHOUSE", "DOCK_PORT"}:
        errs.append("docks must define DOCK_LIGHTHOUSE and DOCK_PORT.")
    for d in b.docks:
        if not d.auto_dock:
            errs.append(f"{d.zone_id}: docking is automatic inside the zone (canon).")
        if d.approach_radius_m < 5:
            errs.append(f"{d.zone_id}: approach_radius_m must be at least 5 m or the player can never dock.")
    text = " ".join([b.collision_recovery, b.tide_hook, *b.handling_checks])
    if TIMER_WORDS.search(text):
        errs.append("No timer or countdown wording anywhere in the boat spec (Pillar 2).")
    if not re.search(r"safe|recover", b.collision_recovery, re.I):
        errs.append("collision_recovery must recover the boat to a safe point.")
    if not any(re.search(r"dock", c, re.I) for c in b.handling_checks):
        errs.append("handling_checks must include a docking test.")
    return errs


# ---------------- Player Movement agent ----------------
GLITCH_TOPICS = {
    "slopes": r"slope|incline|ramp",
    "steps and lips": r"\bsteps?\b|stair|ledge|\blip",
    "turning while moving": r"turn",
    "stuck in corners": r"corner|wedge|stuck",
    "falling through": r"fall|through|tunnel",
    "frame rate": r"frame|fps|delta",
    "camera": r"camera|clip|jitter|judder",
}


def check_player(p: PlayerMovementSpec) -> list[str]:
    errs = []
    if not 1.5 <= p.walk_speed_mps <= 5.0:
        errs.append("walk_speed_mps must be 1.5-5.")
    if p.sprint_speed_mps <= p.walk_speed_mps or p.sprint_speed_mps > 9.0:
        errs.append("sprint_speed_mps must exceed walk speed and be at most 9.")
    if p.accel_time_s > 0.3 or p.decel_time_s > 0.3:
        errs.append("accel_time_s and decel_time_s must be at most 0.3 s so controls feel responsive.")
    if p.mouse_smoothing:
        errs.append("mouse_smoothing must be false: smoothing makes turning feel laggy.")
    if not 0.001 <= p.mouse_sensitivity_rad_per_px <= 0.006:
        errs.append("mouse_sensitivity_rad_per_px must be 0.001-0.006.")
    if not 60 <= p.pitch_limit_deg <= 89:
        errs.append("pitch_limit_deg must be 60-89 (89 or less avoids gimbal flip).")
    if not p.move_while_turning:
        errs.append("move_while_turning must be true: turning and moving are independent and simultaneous.")
    if not p.uses_delta_time:
        errs.append("uses_delta_time must be true: movement must not depend on frame rate.")
    if not (1.4 <= p.capsule_height_m <= 1.9 and 0.2 <= p.capsule_radius_m <= 0.4):
        errs.append("capsule must be 1.4-1.9 m tall with radius 0.2-0.4 m.")
    if p.capsule_radius_m * 2 >= p.capsule_height_m:
        errs.append("capsule radius x 2 must be smaller than its height.")
    if not 0.8 * p.capsule_height_m <= p.eye_height_m <= p.capsule_height_m:
        errs.append("eye_height_m must sit in the top 20% of the capsule.")
    if not 0.2 <= p.step_height_m <= 0.5:
        errs.append("step_height_m must be 0.2-0.5.")
    if not 45 <= p.max_floor_angle_deg <= 65:
        errs.append("max_floor_angle_deg must be 45-65 (the AI-generated island has steep rock).")
    if p.floor_snap_m < p.step_height_m:
        errs.append("floor_snap_m must be at least step_height_m or the player floats off the ground after a step.")
    if p.head_bob_amplitude_m > 0.03:
        errs.append("head_bob_amplitude_m must be at most 0.03 (comfort).")
    if p.fall_respawn_y_m > -10:
        errs.append("fall_respawn_y_m must be well below the sea (-10 or lower).")
    ids = [g.check_id for g in p.glitch_checks]
    if len(set(ids)) != len(ids):
        errs.append("glitch check IDs must be unique.")
    blob = " ".join(f"{g.symptom} {g.likely_cause} {g.mitigation} {g.test}" for g in p.glitch_checks).lower()
    for topic, pattern in GLITCH_TOPICS.items():
        if not re.search(pattern, blob):
            errs.append(f"glitch_checks must cover '{topic}'.")
    return errs


# ---------------- Lighting agent ----------------
SALTGATE_BEARING_DEG = 180.0   # the Saltgate (and Saint Calder behind it) is due south of the lighthouse: +Z in Level.tscn

def _hexes(obj) -> list[str]:
    """Every string that starts with '#' anywhere in a dumped model."""
    if isinstance(obj, str):
        return [obj] if obj.startswith("#") else []
    if isinstance(obj, dict):
        return [h for v in obj.values() for h in _hexes(v)]
    if isinstance(obj, (list, tuple)):
        return [h for v in obj for h in _hexes(v)]
    return []


def check_lighting(s: LightingSpec, guide: StyleGuide) -> list[str]:
    errs = []
    palette = guide.palette_all
    for h in _hexes(s.model_dump()):
        if not HEX.match(h):
            errs.append(f"'{h}' is not a #RRGGBB colour.")
        elif h.upper() not in palette:
            errs.append(f"{h} is not in the style guide palette {sorted(palette)}.")
    ph = {p.phase_id: p for p in s.phases}
    if list(ph) != ["ISLAND", "OUTBOUND", "RETURN", "BEACON_RELIT"]:
        errs.append("phases must be ISLAND, OUTBOUND, RETURN, BEACON_RELIT in that order.")
        return errs
    if ph["RETURN"].hazard_visibility_m > ph["OUTBOUND"].hazard_visibility_m:
        errs.append("RETURN hazard_visibility_m must not exceed OUTBOUND (the return is harder).")
    if ph["RETURN"].fog_density < ph["OUTBOUND"].fog_density:
        errs.append("RETURN fog_density must be at least OUTBOUND's.")
    if ph["BEACON_RELIT"].hazard_visibility_m < ph["RETURN"].hazard_visibility_m:
        errs.append("BEACON_RELIT visibility must be at least RETURN's: the relit beacon helps.")
    # Lightning per phase: only once the burner is collected (RETURN on), always within the flash cap.
    min_gap = 1.0 / s.lightning.max_flashes_per_second
    for p in s.phases:
        lt = p.lightning
        if lt.enabled:
            if lt.interval_s is None or lt.style == "none":
                errs.append(f"{p.phase_id}: enabled lightning needs a style and interval_s.")
            elif lt.interval_s[0] > lt.interval_s[1] or lt.interval_s[0] < min_gap:
                errs.append(f"{p.phase_id}: lightning interval_s {lt.interval_s} must satisfy "
                            f"{min_gap:.2f} s <= min <= max (photosensitivity cap).")
        elif lt.interval_s is not None or lt.style != "none":
            errs.append(f"{p.phase_id}: disabled lightning must have style 'none' and interval_s null.")
    for pid in ("ISLAND", "OUTBOUND"):
        if ph[pid].lightning.enabled:
            errs.append(f"{pid}: no lightning yet; it starts on the RETURN once the burner is collected.")
    if not ph["RETURN"].lightning.enabled or ph["RETURN"].lightning.style != "cloud_to_cloud":
        errs.append("RETURN: lightning must be on and flash between the clouds (style 'cloud_to_cloud').")
    # Clouds: ominous and gathering on the island, darker and fuller outbound, darkest on the return.
    c = {pid: ph[pid].clouds for pid in ph}
    if c["ISLAND"].trend != "gathering":
        errs.append("ISLAND clouds must be 'gathering' (ominous, before the player first sets off).")
    if not (c["OUTBOUND"].coverage > c["ISLAND"].coverage and c["OUTBOUND"].darkness > c["ISLAND"].darkness):
        errs.append("OUTBOUND clouds must be fuller and darker than ISLAND.")
    if not (c["RETURN"].coverage >= c["OUTBOUND"].coverage and c["RETURN"].darkness > c["OUTBOUND"].darkness):
        errs.append("RETURN skies must be darker than OUTBOUND, and at least as full.")
    # Creator decision 2026-10-16: the storm stays near full strength once the beacon is relit.
    bc, rc = ph["BEACON_RELIT"], ph["RETURN"]
    if (bc.clouds.darkness < 0.9 * rc.clouds.darkness or bc.rain.intensity < 0.8 * rc.rain.intensity
            or not bc.lightning.enabled):
        errs.append("BEACON_RELIT: the storm stays near full strength (clouds at least 90% as dark and rain at least "
                    "80% as heavy as RETURN, lightning still on).")
    # Creator decision 2026-10-16: a second, darker layer drifts slowly across the sky on the RETURN only,
    # thin enough for the lightning to light it through, and free to cross the moon.
    for pid in ("ISLAND", "OUTBOUND", "BEACON_RELIT"):
        if ph[pid].clouds.low_coverage != 0:
            errs.append(f"{pid}: the second (low) cloud layer belongs to the RETURN only; low_coverage must be 0.")
    lo = ph["RETURN"].clouds
    if lo.low_coverage <= 0:
        errs.append("RETURN: the second, darker cloud layer must be present (low_coverage above 0).")
    if not 0.3 <= lo.low_opacity <= 0.85:
        errs.append("RETURN: low_opacity must be 0.3-0.85, so the lightning lights the layer through.")
    if lo.low_drift_mps >= lo.drift_mps:
        errs.append("RETURN: the low layer moves slowly - low_drift_mps must be below the main layer's drift_mps.")
    # Rain: dry on the island, starts on the outbound crossing, no lighter on the return.
    r = {pid: ph[pid].rain.intensity for pid in ph}
    if r["ISLAND"] != 0:
        errs.append("ISLAND must be dry: the rain starts on the outbound crossing.")
    if r["OUTBOUND"] <= 0:
        errs.append("OUTBOUND rain must have started (intensity above 0).")
    if r["RETURN"] < r["OUTBOUND"]:
        errs.append("RETURN rain must be at least as heavy as OUTBOUND.")
    fl, fh = s.lightning.flash_duration_s
    if not (0.03 <= fl <= fh <= 0.5):
        errs.append("flash_duration_s must satisfy 0.03 <= min <= max <= 0.5 s.")
    pl, ph_ = s.lightning.strobe_pulses
    if not 1 <= pl <= ph_ <= 5:
        errs.append("lightning.strobe_pulses must satisfy 1 <= min <= max <= 5.")
    gl, gh = s.lightning.strobe_gap_s
    if not 0.04 <= gl <= gh <= 0.25:
        errs.append("lightning.strobe_gap_s must satisfy 0.04 <= min <= max <= 0.25 s.")
    if ph["RETURN"].lightning.enabled and not s.lightning.bolt_visible:
        errs.append("lightning.bolt_visible must be true: the return shows the bolts between the clouds.")
    if not s.lightning.reveals_hazards:
        errs.append("lightning.reveals_hazards must be true: a flash must never hide a hazard.")
    if s.moon.state == "absent" and s.moon.visible_disc:
        errs.append("moon.state 'absent' cannot have a visible disc.")
    if s.moon.state == "full":
        # Supermoon vibe until the Flighted ship eclipses it: big, bright, and it lights both crossings.
        if not (s.moon.visible_disc and s.moon.lights_crossings):
            errs.append("A full moon must show its disc and light both crossings.")
        if s.moon.light_energy < 0.35:
            errs.append("moon.light_energy must be at least 0.35 so the moon lights the crossings.")
        if s.moon.disc_scale < 1.2:
            errs.append("moon.disc_scale must be at least 1.2 for the supermoon look.")
        # Creator decision 2026-10-16: the moon sits on the far side of the lighthouse from the Saltgate, so it
        # lights the crossings and leaves Saint Calder (beyond the Saltgate) in relative darkness.
        off = abs((s.moon.azimuth_deg - SALTGATE_BEARING_DEG + 180.0) % 360.0 - 180.0)
        if off < 135.0:
            errs.append(f"moon.azimuth_deg {s.moon.azimuth_deg} is only {off:.0f} deg from the Saltgate bearing "
                        f"({SALTGATE_BEARING_DEG}); it must sit on the far side of the lighthouse (at least 135 deg away).")
        for pid in ("OUTBOUND", "RETURN"):
            if not ph[pid].clouds.moon_gap:
                errs.append(f"{pid}: the clouds must leave a moon_gap so the moon can light the crossing.")
    kinds = {x.kind for x in s.sources}
    for need in ("beacon", "arc_lamp", "steam_glow", "boat_lamp", "saint_calder_lights"):
        if need not in kinds:
            errs.append(f"sources must include a '{need}' light.")
    ids = [x.source_id for x in s.sources]
    if len(set(ids)) != len(ids):
        errs.append("source_id values must be unique.")
    if any(x.is_navigation_marker for x in s.sources) or s.saint_calder.is_navigation_marker:
        errs.append("No light may be a navigation marker (Pillar 3: guidance comes from Ted and Arthur).")
    gold_amber = {guide.colour_meanings.get("Amber", "").upper(), guide.colour_meanings.get("Gold", "").upper()}
    for x in s.sources:
        if x.kind == "saint_calder_lights" and x.colour.upper() not in gold_amber:
            errs.append(f"{x.source_id}: Saint Calder lights must be amber or gold.")
    if any(c.upper() not in gold_amber for c in s.saint_calder.colours):
        errs.append("saint_calder.colours must be amber and gold only.")
    sc = s.saint_calder
    if not sc.window_lights:
        errs.append("saint_calder.window_lights must be true: the city's windows are lit.")
    if not 0 < sc.glow_at_lighthouse <= 0.35:
        errs.append("saint_calder.glow_at_lighthouse must be above 0 and at most 0.35: only just visible from the lighthouse.")
    if sc.glow_at_saltgate <= sc.glow_at_lighthouse:
        errs.append("saint_calder.glow_at_saltgate must be stronger than glow_at_lighthouse: it is more obvious at the Saltgate.")
    if not s.saint_calder.visible_through_fog:
        errs.append("saint_calder.visible_through_fog must be true: the city is the distant glow the crossing is seen against.")
    if not 3 <= s.beacon.sweep_period_s <= 15:
        errs.append("beacon.sweep_period_s must be 3-15 s.")
    states = " ".join(s.beacon.states).lower()
    for word in ("dark", "relit"):
        if word not in states:
            errs.append(f"beacon.states must include a '{word}' state.")
    lights = [x for x in s.sources if "light3d" in x.godot_node.lower()]
    if len(lights) + 2 > s.max_dynamic_lights:  # +2: lightning and moon rim
        errs.append(f"{len(lights)} Light3D sources plus lightning and moon exceed max_dynamic_lights {s.max_dynamic_lights}.")
    if sum(x.casts_shadow for x in s.sources) > s.max_shadow_casters:
        errs.append("More shadow-casting sources than max_shadow_casters.")
    blob = " ".join(s.legibility_checks).lower()
    for topic in ("hazard", "lightning", "saint calder", "beacon", "moon", "rain"):
        if topic not in blob:
            errs.append(f"legibility_checks must cover '{topic}'.")
    if TIMER_WORDS.search(" ".join(s.legibility_checks) + " " + s.lightning.note):
        errs.append("No timer or countdown wording (Pillar 2).")
    return errs


def check_world_review(report: ReviewReport) -> list[str]:
    return check_review(report)
