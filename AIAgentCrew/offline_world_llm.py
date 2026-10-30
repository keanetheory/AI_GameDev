"""Offline scripted LLM for the world crew and the asset review crew (no API key needed).

Like the other offline LLMs it runs the REAL CrewAI agents, tasks, context passing and guardrails; only the
model's text is scripted. The first Boat and Lighting attempts deliberately contain a fault each (a throttle key,
a neon colour) so the guardrail feedback loop is visible on every offline run. Use inject_errors=False to skip.

The offline Asset agent applies mechanical repairs (add the style descriptors, merge the global negatives, strip
forbidden words, rename Brusskania). A real model writes better prompts; this is NOT the creative engine.
"""
import json
import re
from typing import Any

from crewai import BaseLLM

from style_guide import ALWAYS_FORBIDDEN, KEYWORD_GROUPS, check_prompt
from world_canon import ASSET_FOLDERS

IMPORT_NOTES = {
    "lighthouse": "Scale: author at 1 unit = 1 m (tower about 27 m). Pivot: centre of the base at ground level. Collision: trimesh from a decimated collider copy; keep the door and stair openings clear. Materials: keep the hand-painted albedo, set roughness high.",
    "island": "Scale: 1 unit = 1 m (about 330 m x 140 m). Pivot: centre of the island at sea level. Collision: separate low-poly trimesh collider; steepest walkable rock at most 60 degrees. Materials: matte stone, no metallic.",
    "dock": "Scale: planks about 0.3 m wide, deck at y = 0. Pivot: landward end of the dock. Collision: boxes for the deck and posts, not trimesh. Materials: wet dark timber.",
    "boat": "Scale: about 6-8 m long. Pivot: waterline centre of the hull. Collision: simple convex hull. Materials: teal paint with brass trim; keep brass roughness 0.5.",
    "cliff_terrain": "Scale: modules about 10-20 m, snap on a 10 m grid. Pivot: bottom centre. Collision: trimesh per module. Materials: mossy slate, matte.",
    "sea_rocks": "Scale: 3-15 m tall. Pivot: waterline centre. Collision: convex hull (hazards). Materials: wet dark rock with a little moss.",
    "saint_calder_city": "Scale: a backdrop about 600 m wide, placed 3 km away. Pivot: bottom centre. Collision: none. Materials: emissive amber and gold windows only; keep everything else dark and fogged.",
    "prop": "Scale: real-world metres. Pivot: base centre. Collision: simplified box or convex hull. Materials: grimy hand-painted textures.",
    "character_texture": "Scale: n/a (texture). Pivot: n/a. Collision: n/a. Materials: albedo only, palette-limited.",
}

FIRST_FIX = "#00FFAA"  # neon green used in the deliberately faulty first lighting attempt


def repair_prompt(prompt: str, category: str, guide) -> str:
    p = re.sub(r"brusskania", "Saint Calder", prompt, flags=re.I)
    for label, pattern in ALWAYS_FORBIDDEN.items():
        if label != "retired city name":
            p = re.sub(r",?\s*(in the )?" + pattern + r"[^,.]*", "", p, flags=re.I)
    p = re.sub(r"\bby [A-Z][a-z]+ [A-Z][a-z]+\b", "", p)
    p = re.sub(r"#[0-9A-Fa-f]{6}", "", p)
    for neg in guide.negatives:  # drop any global negative the creator asked for in the positive prompt
        p = re.sub(r"\b" + re.escape(neg.lower().rstrip("s")) + r"s?\b", "", p, flags=re.I)
    low = p.lower()
    add = []
    if not any(w in low for w in KEYWORD_GROUPS["cel shading"]):
        add.append("gritty dark cel-shaded")
    if not any(w in low for w in KEYWORD_GROUPS["ink outlines"]):
        add.append("heavy ink outlines")
    if not any(w in low for w in KEYWORD_GROUPS["muted palette"]):
        add.append("muted, desaturated palette")
    if not any(w in low for w in KEYWORD_GROUPS["grimy hand-painted texture"]):
        add.append("grimy hand-painted textures")
    if category == "saint_calder_city":
        if "gothic" not in low:
            add.append("1800s Gothic cathedral skyline")
        if "amber" not in low and "gold" not in low:
            add.append("warm amber and gold electric glow")
    return re.sub(r"\s+,", ",", re.sub(r"\s{2,}", " ", (p.strip().rstrip(",") + (", " + ", ".join(add) if add else "")))).strip()


class OfflineWorldLLM(BaseLLM):
    model: str = "offline-scripted-world"
    state: dict = {}
    inject_errors: bool = True
    attempts: dict = {}

    def supports_function_calling(self) -> bool:
        return False

    def call(self, messages, tools=None, callbacks=None, available_functions=None,
             from_task=None, from_agent=None, response_model=None) -> Any:
        text = json.dumps(messages) if not isinstance(messages, str) else messages
        retry = "Fix these contract violations" in text
        if "[TASK ASSET_REVIEW]" in text:
            payload = self._asset()
        elif "[TASK BOAT_SPEC]" in text:
            payload = self._boat(faulty=self.inject_errors and not retry)
        elif "[TASK PLAYER_SPEC]" in text:
            payload = self._player()
        elif "[TASK LIGHTING_SPEC]" in text:
            payload = self._lighting(faulty=self.inject_errors and not retry)
        else:
            payload = self._review()
        return "Thought: I now can give a great answer\nFinal Answer: " + json.dumps(payload)

    # ---------------- asset ----------------
    def _asset(self):
        sub, findings, guide = self.state["sub"], self.state["findings"], self.state["guide"]
        revised = repair_prompt(sub.prompt, sub.category, guide)
        negs = [n.strip() for n in sub.negative_prompt.split(",") if n.strip()]
        have = {n.lower() for n in negs}
        negs += [n for n in guide.negatives if n.lower() not in have]
        original_ok = not findings
        checks = [
            {"check": "Style descriptors", "result": "pass" if not any("style descriptors" in f for f in findings) else "fail",
             "evidence": "Prompt covers cel shading plus at least three descriptor groups." if not any("style descriptors" in f for f in findings) else "Descriptor groups missing; added in the revised prompt."},
            {"check": "Palette and colour", "result": "pass" if not any("palette" in f or "colour" in f for f in findings) else "fail",
             "evidence": "No colours outside the style guide palette."},
            {"check": "Era, tone and forbidden references", "result": "pass" if not any("forbidden" in f or "negative" in f.lower() or "artist" in f for f in findings if "Negative prompt" not in f) else "fail",
             "evidence": "No touchstones, artists, retired names or modern items in the positive prompt."},
            {"check": "Negative prompt", "result": "pass" if not any("Negative prompt" in f for f in findings) else "fail",
             "evidence": "Includes every global negative." if not any("Negative prompt" in f for f in findings) else "Global negatives were missing; merged into the revised negative prompt."},
            {"check": "Source image look", "result": "pass" if not any("Image" in f or "image" in f for f in findings) else "fail",
             "evidence": f"Image metrics: {json.dumps(self.state.get('metrics') or 'no source image')}"},
        ]
        return {
            "asset_id": sub.asset_id, "verdict": "APPROVE" if original_ok else "REVISE",
            "style_checks": checks, "issues": findings,
            "revised_prompt": revised, "revised_negative_prompt": ", ".join(negs),
            "godot_target_folder": ASSET_FOLDERS[sub.category],
            "import_notes": [IMPORT_NOTES[sub.category]],
            "summary": ("Submission ties into the style guide; use the prompt as written."
                        if original_ok else f"{len(findings)} style problem(s) found; use the revised prompt and negative prompt."),
        }

    # ---------------- boat ----------------
    def _boat(self, faulty: bool):
        def leg(leg_id, frm, to, tag, feel, lat):
            return {"leg_id": leg_id, "from_zone": frm, "to_zone": to, "length_m": 1500, "feel": feel,
                    "waypoints": [{"waypoint_id": f"WP_{tag}_{i + 1:02d}", "route_m": m, "lateral_m": l, "note": n}
                                  for i, (m, l, n) in enumerate(lat)]}
        return {
            "spec_id": "BOAT_STEAM_LAUNCH_V1", "vessel": "Gothic teal steam launch with brass trim",
            "speed_mps": 8.0,
            "steer_left_action": "move_left", "steer_right_action": "move_right",
            "throttle_actions": ["move_forward"] if faulty else [],
            "other_move_keys_do": "Nothing: W and S have no effect on the boat.",
            "max_turn_rate_deg_s": 35.0, "steer_response_s": 0.35, "rudder_returns_to_centre": True, "drift_factor": 0.15,
            "legs": [
                leg("OUTBOUND", "DOCK_LIGHTHOUSE", "DOCK_PORT", "OUT",
                    "Quiet steam chugging, rain starting, the beacon dark behind and Saint Calder's glow ahead.",
                    [(0, 0.0, "Leave the lighthouse jetty"), (500, -6.0, "Clear the island reef"),
                     (1000, 4.0, "Open Gullwater, rocks to the right"), (1500, 0.0, "Saltgate quays")]),
                leg("RETURN", "DOCK_PORT", "DOCK_LIGHTHOUSE", "RET",
                    "Roaring storm, rocks closing in, Arthur shouting directions over the wind.",
                    [(0, 0.0, "Leave the quays with the burner"), (500, 5.0, "Rocks and buoys"),
                     (1000, -4.0, "Narrows under Bracken Isle"), (1500, 0.0, "Lighthouse jetty")]),
            ],
            "docks": [
                {"zone_id": "DOCK_LIGHTHOUSE", "approach_radius_m": 12.0, "auto_dock": True,
                 "note": "Boat slows to a stop and ties up on entering the zone."},
                {"zone_id": "DOCK_PORT", "approach_radius_m": 12.0, "auto_dock": True,
                 "note": "Boat stops at the Saltgate quays; the player lands to fetch the burner."},
            ],
            "collision_recovery": "On a hazard hit the boat bounces off and is moved to the nearest SAFE point on the route with a small cost; the burner is never lost.",
            "waves_enabled": True,
            "tide_hook": "A Vector2 'water_push' added to the boat's velocity each physics frame, driven by the Wave Creator Agent's WaveSystem from data/world/wave_spec.json.",
            "handling_checks": [
                "Hold A for 5 s: the boat turns at the maximum rate with no spin-out.",
                "Release A and D: the rudder centres and the boat holds a straight line.",
                "Press W and S: nothing happens to speed or heading.",
                "Thread a 12 m gap between two rocks at full speed without hitting either.",
                "Enter DOCK_PORT and DOCK_LIGHTHOUSE off-centre: docking completes automatically.",
                "Alternate A and D quickly: no jitter in the camera or hull.",
            ],
            "open_creator_decisions": [
                "Whether the earlier return-crossing data (6 m/s) should be regenerated at the confirmed 8 m/s.",
                "Whether Arthur, as a passenger, moves around the boat while it is steered.",
            ],
        }

    # ---------------- player ----------------
    def _player(self):
        def g(i, symptom, cause, fix, test):
            return {"check_id": f"MOVE_{i:02d}", "symptom": symptom, "likely_cause": cause, "mitigation": fix, "test": test}
        return {
            "spec_id": "PLAYER_FIRST_PERSON_V1",
            "walk_speed_mps": 3.5, "sprint_speed_mps": 6.0, "accel_time_s": 0.12, "decel_time_s": 0.1, "air_control": 0.3,
            "jump_velocity_mps": 4.5, "mouse_sensitivity_rad_per_px": 0.0025, "mouse_smoothing": False,
            "pitch_limit_deg": 85.0, "gamepad_look_speed_deg_s": 180.0, "move_while_turning": True,
            "capsule_radius_m": 0.3, "capsule_height_m": 1.7, "eye_height_m": 1.6,
            "step_height_m": 0.4, "max_floor_angle_deg": 60.0, "floor_snap_m": 0.5, "uses_delta_time": True,
            "head_bob_amplitude_m": 0.0, "fall_respawn_y_m": -40.0,
            "glitch_checks": [
                g(1, "Player stops dead on a rock slope slightly over 45 degrees", "Default floor angle is 45 degrees and the generated rock is rough", "Raise max_floor_angle to 60 degrees and keep floor_stop_on_slope off", "Walk straight up the island slope at walk and sprint speed with tools/debug_walk.gd; progress must not stall."),
                g(2, "Snagging or stalling on small lips and plank edges", "Trimesh edges higher than the capsule skin", "Step-up: if blocked, test a raised capsule and lift by step_height", "Walk along the gangway and across plank joints; no stall and no visible hop."),
                g(3, "Camera lags or snaps when turning while moving", "Smoothed mouse look or rotating the wrong node", "Rotate the body on yaw and the Head on pitch directly from raw mouse motion, no smoothing", "Walk forward while sweeping the mouse; turning must track the mouse 1:1 and the path must curve smoothly."),
                g(4, "Player wedged in a corner or between two walls", "Collision sliding into opposing normals", "Allow six slides and a small safe_margin; add a nudge-out if velocity stays zero while input is held for 1 s", "Drive into the tunnel corner and the barrier corners holding two keys; the player must slide out."),
                g(5, "Player falls through the island or sea collider", "Trimesh holes or a collider not loaded yet", "Wait one physics frame after colliders are built before enabling movement; respawn below the fall limit", "Run the spawn test 20 times and sprint along every edge of the island; never fall through."),
                g(6, "Speed changes with frame rate", "Movement scaled by frame count instead of delta", "Use delta in all velocity changes and keep physics at a fixed rate", "Cap the game at 30, 60 and 144 fps and time the walk between two points; results must match."),
                g(7, "Camera clips into walls or jitters on steps", "Camera parented to a body that moves in steps", "Raise the Head smoothly (lerp the step offset) and keep the near clip at 0.05 m", "Walk into walls and up the stone steps; the view must not poke through geometry or judder."),
            ],
            "open_creator_decisions": ["Whether to add controller support at Gate 1.", "Whether sprint is allowed inside the lighthouse."],
        }

    # ---------------- lighting ----------------
    def _lighting(self, faulty: bool):
        SIL, AMB, GLD, NAV, SLATE, STONE, BLK = "#B9BEC4", "#C07A1E", "#B8962E", "#1F2A44", "#2C3A40", "#6B6B66", "#0E0E10"
        def src(i, kind, loc, col, e, rng, beh, node, shadow):
            return {"source_id": f"LIGHT_{i}", "kind": kind, "location": loc, "colour": col, "energy": e, "range_m": rng,
                    "behaviour": beh, "godot_node": node, "casts_shadow": shadow, "is_navigation_marker": False}
        return {
            "spec_id": "LIGHTING_RIG_V1",
            "phases": [
                {"phase_id": "ISLAND", "ambient_colour": NAV, "ambient_energy": 0.5, "fog_colour": SLATE, "fog_density": 0.006, "hazard_visibility_m": 130,
                 "clouds": {"trend": "gathering", "coverage": 0.45, "darkness": 0.35, "base_height_m": 600.0, "drift_mps": 2.5, "top_colour": STONE,
                            "underside_colour": SLATE, "moon_gap": True, "low_coverage": 0.0, "low_opacity": 0.0, "low_drift_mps": 0.0, "low_colour": BLK,
                            "note": "Ominous banks rolling in off the sea and piling up behind the Saltgate; the supermoon still hangs clear above the island."},
                 "rain": {"intensity": 0.3, "slant_deg": 0.0, "colour": SIL, "note": "Light rain from the first moment (creator, 23 Oct 2026), steadier once the boat leaves."},
                 "lightning": {"enabled": False, "style": "none", "interval_s": None, "lights_cloud_base": False, "note": "None yet; the storm is still gathering."},
                 "note": "Cold moonlit dusk on the island before the player first sets off; the storm is on its way."},
                {"phase_id": "OUTBOUND", "ambient_colour": NAV, "ambient_energy": 0.45, "fog_colour": SLATE, "fog_density": 0.008, "hazard_visibility_m": 110,
                 "clouds": {"trend": "building", "coverage": 0.7, "darkness": 0.6, "base_height_m": 450.0, "drift_mps": 4.0, "top_colour": SLATE,
                            "underside_colour": NAV, "moon_gap": True, "low_coverage": 0.0, "low_opacity": 0.0, "low_drift_mps": 0.0, "low_colour": BLK,
                            "note": "Darker and fuller; only a few sparse wisps cross the moon, so the light on the water comes and goes."},
                 "rain": {"intensity": 0.35, "slant_deg": 15.0, "colour": SIL, "note": "Starts soon after leaving the island: light at first, then steady."},
                 "lightning": {"enabled": False, "style": "none", "interval_s": None, "lights_cloud_base": False, "note": "Still none: the first flash waits for the burner."},
                 "note": "The crossing to fetch the burner: rain starting, moonlight on the sea, Saint Calder's windows ahead."},
                {"phase_id": "RETURN", "ambient_colour": BLK, "ambient_energy": 0.35, "fog_colour": SLATE, "fog_density": 0.014, "hazard_visibility_m": 70,
                 "clouds": {"trend": "full", "coverage": 0.9, "darkness": 0.85, "base_height_m": 300.0, "drift_mps": 7.0, "top_colour": BLK,
                            "underside_colour": SLATE, "moon_gap": True, "low_coverage": 0.55, "low_opacity": 0.65, "low_drift_mps": 2.0, "low_colour": BLK,
                            "note": "Dense, billowing near-black cloud, low and fast, lit at the edges; the moon shows through a few sparse clouds, cold and bright on the water. Beneath it a second, darker, ragged layer drifts slowly across the sky and over the moon; the lightning lights it through."},
                 "rain": {"intensity": 0.75, "slant_deg": 30.0, "colour": SIL, "note": "Heavy, wind-driven rain across the bow."},
                 "lightning": {"enabled": True, "style": "cloud_to_cloud", "interval_s": [3.0, 9.0], "lights_cloud_base": True,
                               "note": "A forked bolt runs between the clouds and strobes the cloud around it two to four times; for an instant the rocks drop into black silhouette."},
                 "note": "Burner aboard: the storm breaks. Darker skies, lightning between the clouds, the moon the one steady light."},
                {"phase_id": "BEACON_RELIT", "ambient_colour": NAV, "ambient_energy": 0.45, "fog_colour": SLATE, "fog_density": 0.012, "hazard_visibility_m": 140,
                 "clouds": {"trend": "full", "coverage": 0.88, "darkness": 0.82, "base_height_m": 310.0, "drift_mps": 6.5, "top_colour": BLK,
                            "underside_colour": SLATE, "moon_gap": True, "low_coverage": 0.0, "low_opacity": 0.0, "low_drift_mps": 0.0, "low_colour": BLK,
                            "note": "The storm holds near full strength; the beacon's sweep catches the cloud base on each turn."},
                 "rain": {"intensity": 0.7, "slant_deg": 28.0, "colour": SIL, "note": "Still driving hard."},
                 "lightning": {"enabled": True, "style": "cloud_to_cloud", "interval_s": [4.0, 11.0], "lights_cloud_base": True,
                               "note": "Barely fewer flashes than the return; the relit beacon is what changes, not the storm."},
                 "note": "The beacon sweeps the water; the sea is readable again."},
            ],
            "moon": {"state": "full", "look": "A huge, low supermoon, cold silver, hanging over the Gullwater.", "colour": SIL,
                     "light_energy": 0.6, "disc_scale": 2.2, "elevation_deg": 22.0, "azimuth_deg": 0.0,
                     "position_note": "Low in the north, on the far side of the lighthouse from the Saltgate: it lights the crossings from behind the lighthouse and leaves the sky over Saint Calder dark, so the city's windows are the only light there.",
                     "visible_disc": True, "lights_crossings": True,
                     "eclipse_note": "Later the Flighted ship slides across it, leaving a black sphere with a faint silver rim, and the moonlight drops away. Not part of this pass."},
            "lightning": {"colour": FIRST_FIX if faulty else SIL, "peak_energy": 5.0, "flash_duration_s": [0.08, 0.3],
                          "max_flashes_per_second": 2.0, "thunder_delay_s_per_100m": 0.29,
                          "driven_by": "phase_and_route_position", "reveals_hazards": True,
                          "bolt_visible": True, "strobe_pulses": [2, 4], "strobe_gap_s": [0.05, 0.12], "strobe_scope": "local_cloud",
                          "note": "Cold silver-white flash between the clouds with a short afterglow, from the RETURN on; flashes place hazards in black silhouette against the sea."},
            "sources": [
                src("BEACON", "beacon", "Lighthouse lantern room", SIL, 8.0, 400.0, "Rotating beam; dark, then failing flicker, then steady sweep once relit.", "SpotLight3D", False),
                src("ARC_LAMP", "arc_lamp", "Lighthouse dynamo room", SIL, 3.0, 12.0, "Harsh crackling arc with a dynamo hum flicker.", "OmniLight3D", False),
                src("STEAM_GLOW", "steam_glow", "Basement boiler", AMB, 2.0, 8.0, "Slow pulsing furnace glow that rises when coal is fed.", "OmniLight3D", False),
                src("WINDOWS", "window_lamp", "Keeper's cottage windows", AMB, 1.0, 6.0, "Dim warm window light with a slight gas flicker.", "MeshInstance3D emissive", False),
                src("BOAT_LAMP", "boat_lamp", "Bow of the steam launch", GLD, 2.5, 25.0, "Steady brass lantern that sways with the hull; does not reveal hazards beyond its range.", "SpotLight3D", False),
                src("SAINT_CALDER", "saint_calder_lights", "Far shore, about 3 km inland", AMB, 1.5, 3000.0, "Lit windows on emissive cards; each flickers on its own (a test), brighter the closer the player gets.", "MeshInstance3D emissive", False),
            ],
            "beacon": {"sweep_period_s": 8.0, "beam_range_m": 400.0, "colour": SIL, "states": ["dark", "failing flicker", "relit steady sweep"]},
            "saint_calder": {"distance_m": 3000.0, "colours": [AMB, GLD],
                             "technique": "Emissive window cards and a cathedral silhouette billboard, glow scaled by the player's distance and depth-faded by fog; no real lights.",
                             "window_lights": True, "glow_at_lighthouse": 0.2, "glow_at_saltgate": 0.7,
                             "seen_from_lighthouse": "A faint scatter of amber window lights low on the far shore, just visible through the haze.",
                             "seen_from_saltgate": "Rows of lit amber and gold windows climbing the hill behind the quays, the cathedral above them.",
                             "visible_through_fog": True, "flicker": "Test: the windows flicker, each on its own - a few at a time dim and recover, never in step; the cathedral stays steady.",
                             "is_navigation_marker": False,
                             "note": "Scenery only: warm window light in the relative darkness the moon leaves over the city. It must not line up as a goal marker for the crossing."},
            "max_dynamic_lights": 18, "max_shadow_casters": 2,
            "legibility_checks": [
                "Hazards: at RETURN the nearest rock reads as a silhouette at its hazard_visibility_m with no flash.",
                "Lightning: a flash never washes out a hazard to white; hazards read darker than the sea during a flash.",
                "Beacon: dark at the start, then relit; the sweep is visible from DOCK_PORT without being a marker.",
                "Saint Calder: visible through fog from the outbound start, amber and gold only, never brighter than the beacon.",
                "Photosensitivity: record 60 s of RETURN and confirm no more than 3 flashes in any second.",
                "Moon: on both crossings the moonlit sea reads clearly and rocks show as dark shapes against it without a flash.",
                "Rain: at RETURN intensity the rain never hides a hazard inside its hazard_visibility_m.",
            ],
            "open_creator_decisions": ["Keep Saint Calder's window flicker after the vibe test, or make the windows steady."],
        }

    # ---------------- review ----------------
    def _review(self):
        p = lambda c, e: {"check": c, "result": "pass", "evidence": e}
        b, pl, li = self.state["boat"], self.state["player"], self.state["lighting"]
        return {
            "verdict": "PASS",
            "pillar_checks": [
                p("1. The light must return", f"Lighting phases end at BEACON_RELIT; {b.legs[1].leg_id} ends at {b.legs[1].to_zone}."),
                p("2. The storm sets the clock", "Lightning, fog and visibility are driven by phase and route position; no timers in any spec."),
                p("3. Your hands, your eyes", "First-person walking and A/D steering only; beacon and Saint Calder are scenery with is_navigation_marker false."),
                p("4. Dread you can read", f"RETURN hazard_visibility_m {li.phases[2].hazard_visibility_m} with lightning that reveals hazards; {len(pl.glitch_checks)} glitch checks with tests."),
            ],
            "decisions_log_checks": [
                p("One fixed speed, A/D steering", f"speed_mps {b.speed_mps}; throttle_actions empty; W and S do nothing."),
                p("Waves approved, switchable", f"waves_enabled {b.waves_enabled}; tide_hook names the water_push hook the Wave Creator Agent drives."),
                p("No visible timer or markers", "All is_navigation_marker flags false; no timer wording."),
                p("Moon: supermoon until the eclipse is added", f"moon.state '{li.moon.state}', light_energy {li.moon.light_energy}, lights_crossings {li.moon.lights_crossings}."),
                p("Storm builds by phase", "Clouds gather on the island, darken and fill with rain outbound; lightning between the clouds from the RETURN."),
                p("Hazards readable", "legibility_checks cover hazards, lightning, beacon and Saint Calder."),
            ],
            "issues": [],
            "open_creator_decisions": b.open_creator_decisions + li.open_creator_decisions + pl.open_creator_decisions,
            "handoff_summary": ("Boat, Player Movement and Lighting specs for the first traversable Godot level. All deterministic "
                                "checks pass. Steering feel, walking feel, flash safety and hazard readability need creator playtesting. "
                                "Tide and wave behaviour is specified by the Wave Creator Agent in data/world/wave_spec.json."),
        }
