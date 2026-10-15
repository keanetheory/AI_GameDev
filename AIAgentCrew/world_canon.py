"""Canon for the Asset, Boat, Player Movement and Lighting agents.

Sources: the Lore Build (geography.md, sys_eclipse.md, reg_saltgate.md, reg_saint_calder.md, style_guide.md)
and the crossing rules already in canon.py. The style guide itself is read live by style_guide.py.
"""
from canon import PILLARS, RETURN_CROSSING_RULES

ASSET_FOLDERS = {
    "lighthouse": "res://Assets/Models/lighthouse/",
    "island": "res://Assets/Models/island/",
    "dock": "res://Assets/Models/dock/",
    "boat": "res://Assets/Models/boat/",
    "cliff_terrain": "res://Assets/Models/cliff_terrain/",
    "sea_rocks": "res://Assets/Models/sea_rocks/",
    "saltgate": "res://Assets/Models/saltgate/",
    "saint_calder_city": "res://Assets/Models/saint_calder_city/",
    "prop": "res://Assets/Models/props/",
    "character_texture": "res://Assets/Textures/",
}

WORLD_FACTS = [
    "Bracken Isle is a rocky island about 330 m x 140 m, 1-2 km offshore, a 10-minute steam-launch crossing from the mainland.",
    "The island has ONE dock (DOCK_LIGHTHOUSE) on the side facing the Saltgate, one path to the lighthouse and a lockable gate.",
    "The Saltgate is Saint Calder's abandoned harbour directly across the Gullwater. Its quays (DOCK_PORT) are where the "
    "player lands to fetch the replacement beacon burner. The port's own light is almost completely gone in the eclipse.",
    "Jagged rocks ring the island and the Saltgate approach; many are just below the surface. One clear channel in normal light.",
    "Saint Calder is inland behind the Saltgate (a road of about 1.5 km joins them), so it is only ever seen in the distance: "
    "a warm amber and gold electric glow, a Gothic cathedral as the brightest silhouette, Greymantle dark on the horizon.",
    "The eclipse: a perfect black sphere with a faint silver rim covers the moon. Moonlight is absent or eclipsed. Tides turn "
    "aggressive and storms begin. Waves are NOT approved yet (see the Tide / Wave agent reminder).",
    "The steam launch is a gothic teal boat with brass trim. Audio: quiet chugging outbound, wind, rain and roaring storm on the return.",
    "The lighthouse runs on an arc lamp driven by a steam engine and dynamo. Tonight the beacon has failed; relighting it is the goal.",
]

BOAT_RULES = [
    "The boat has ONE fixed speed (no throttle) and ONE steering axis.",
    "The player steers left and right with the A and D keys. W and S do nothing to the boat (there is no throttle or brake).",
    "Input action names are move_left and move_right, the same actions the on-foot player uses.",
    "The route is DOCK_LIGHTHOUSE -> DOCK_PORT (OUTBOUND) and DOCK_PORT -> DOCK_LIGHTHOUSE (RETURN). Docking is automatic inside a dock zone.",
    "The return is harder than the outbound: closer rocks, lower visibility, a narrower route.",
    "Collisions recover to a nearby safe point; the burner is never permanently lost.",
    "Waves and tides are NOT part of the boat yet. waves_enabled must be false and the spec names the hook where a tide force "
    "will plug in later.",
    "CREATOR DECISION (confirmed): the fixed speed is 3 m/s for now and will be tuned by playtesting. The earlier "
    "return-crossing data (6 m/s) is out of date on this point; note it, do not raise it as a question.",
    "CREATOR DECISION (confirmed): W and S do nothing because the boat has no throttle. The port is the Saltgate quays (DOCK_PORT).",
]

PLAYER_FACTS = [
    "First person, on foot. CharacterBody3D in Godot 4.3 with a CapsuleShape3D and a Head node carrying the Camera3D.",
    "Input actions: move_forward, move_back, move_left, move_right (W A S D), jump (Space), sprint (Shift). Mouse look; Esc frees the mouse.",
    "KNOWN ISSUES ALREADY FOUND (an AI-generated island collider is a rough trimesh): the player stopped dead on slopes "
    "slightly over 45 degrees and snagged on small lips. The current fix is a 60 degree floor angle, 0.5 m floor snap, "
    "step-up of 0.4 m and 6 slides. The first spawn is on the pier at (0, 1.2, -0.5).",
    "The level is large (island scaled x45, about 27 m lighthouse) and the sea is a 2000 m plane at y = -2.25.",
    "Moving and turning must be independent and simultaneous. Turning must never feel laggy, snap or drift.",
]

LIGHTING_FACTS = [
    "Phases: ISLAND (on the island before the crossing), OUTBOUND, RETURN, BEACON_RELIT.",
    "Moon: absent or eclipsed. If hinted at all it is a black sphere with a faint silver rim (#B9BEC4).",
    "Storm light is cold, wet and high-contrast. Electric arc light and steam light are the only strong sources in the eclipse.",
    "Lightning: a brief cold silver-white flash that lights hazards in silhouette. It must never hide a hazard, and must never "
    "strobe (photosensitivity cap: no more than 3 flashes per second). Lightning is driven by phase and route position, never elapsed time.",
    "Lighthouse: the beacon (failing at the start, relit at the end), the arc lamp and dynamo room, steam furnace glow in the "
    "basement boiler, and warm window light. Sources are amber (#C07A1E) for steam and silver (#B9BEC4) for arc light.",
    "Saint Calder: far away, only a glow. Amber (#C07A1E) and gold (#B8962E) only; a Gothic cathedral is the brightest silhouette. "
    "It is scenery, never a navigation marker (Pillar 3: guidance comes from Ted and Jeff).",
    "Hazards must stay readable at the minimum visibility on every phase. The return has lower visibility than the outbound.",
    "Performance: the game targets a laptop GPU. Few dynamic lights, very few shadow casters.",
]


def _bullets(items) -> str:
    return "\n".join(f"- {i}" for i in items)


def world_canon_block(extra: list[str] | None = None) -> str:
    parts = ["LIGHTING THE STORM - WORLD CANON", "Pillars:", _bullets(PILLARS), "World facts:", _bullets(WORLD_FACTS),
             "Return-crossing rules (from canon.py):", _bullets(RETURN_CROSSING_RULES)]
    for block in extra or []:
        parts.append(block)
    return "\n".join(parts)


def boat_canon() -> str:
    return "BOAT CANON:\n" + _bullets(BOAT_RULES)


def player_canon() -> str:
    return "PLAYER CANON:\n" + _bullets(PLAYER_FACTS)


def lighting_canon() -> str:
    return "LIGHTING CANON:\n" + _bullets(LIGHTING_FACTS)
