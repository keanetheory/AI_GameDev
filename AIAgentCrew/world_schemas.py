"""Pydantic contracts for the Asset, Boat, Player Movement and Lighting agents.

Same pattern as schemas.py: each agent's JSON is validated against one of these models, then by the
deterministic checks in world_validators.py, before the next agent (or the game) may use it.
"""
from typing import Literal

from pydantic import BaseModel, Field

from schemas import Check

HexColour = str  # '#RRGGBB'; checked against the style guide palette in world_validators.py

ASSET_CATEGORIES = ("lighthouse", "island", "dock", "boat", "cliff_terrain", "sea_rocks",
                    "saltgate", "saint_calder_city", "prop", "character_texture")
AssetCategory = Literal["lighthouse", "island", "dock", "boat", "cliff_terrain", "sea_rocks",
                        "saltgate", "saint_calder_city", "prop", "character_texture"]


# ================= Asset agent: reviews one FAL submission =================
class FalSubmission(BaseModel):
    """What the creator writes per asset before sending it to FAL (a *.fal.json file)."""
    asset_id: str = Field(pattern=r"^[a-z0-9_]+$")
    category: AssetCategory
    fal_model: str = Field(description="e.g. a FAL image-to-3D model id")
    prompt: str
    negative_prompt: str = ""
    source_image: str | None = Field(default=None, description="Path to the concept image, if any")
    view_images: dict[str, str] = Field(default_factory=dict, description="Multi-view models: front/back/left -> concept image path")
    notes: str = ""


class AssetReview(BaseModel):
    asset_id: str
    verdict: Literal["APPROVE", "REVISE"]
    style_checks: list[Check] = Field(min_length=4)
    issues: list[str]
    revised_prompt: str = Field(description="A prompt that passes every style check")
    revised_negative_prompt: str
    godot_target_folder: str = Field(description="res:// folder the finished .glb goes in")
    import_notes: list[str] = Field(description="Scale, pivot, collision and material notes for Godot")
    summary: str


# ================= Boat agent =================
class Waypoint(BaseModel):
    waypoint_id: str = Field(pattern=r"^WP_[A-Z]+_\d{2}$")
    route_m: int = Field(ge=0)
    lateral_m: float = Field(description="Offset from the route centreline; negative = left")
    note: str


class RouteLeg(BaseModel):
    leg_id: Literal["OUTBOUND", "RETURN"]
    from_zone: str
    to_zone: str
    length_m: int = Field(ge=100, le=3000)
    waypoints: list[Waypoint] = Field(min_length=3)
    feel: str = Field(description="What the player hears and sees on this leg (lore)")


class DockZone(BaseModel):
    zone_id: Literal["DOCK_LIGHTHOUSE", "DOCK_PORT"]
    approach_radius_m: float = Field(gt=0)
    auto_dock: bool = Field(description="Docking is automatic inside the zone")
    note: str


class BoatSpec(BaseModel):
    spec_id: str
    vessel: str
    speed_mps: float = Field(gt=0, description="One fixed speed; never changed by input")
    steer_left_action: str
    steer_right_action: str
    throttle_actions: list[str] = Field(description="Must be empty: there is no throttle")
    other_move_keys_do: str = Field(description="What W and S do while steering with A and D")
    max_turn_rate_deg_s: float = Field(gt=0)
    steer_response_s: float = Field(gt=0, description="Time to reach full turn rate; smooths key presses")
    rudder_returns_to_centre: bool
    drift_factor: float = Field(ge=0, le=1, description="Sideways slip in turns; 0 = on rails")
    legs: list[RouteLeg] = Field(min_length=2, max_length=2)
    docks: list[DockZone] = Field(min_length=2, max_length=2)
    collision_recovery: str
    waves_enabled: bool = Field(description="The waves on/off switch. Waves are approved (2026-10-20); False gives a crossing with a visual sea and no push")
    tide_hook: str = Field(description="Where a future tide force would plug into the boat controller")
    handling_checks: list[str] = Field(min_length=5)
    open_creator_decisions: list[str]


# ================= Player Movement agent =================
class GlitchCheck(BaseModel):
    check_id: str = Field(pattern=r"^MOVE_\d{2}$")
    symptom: str
    likely_cause: str
    mitigation: str
    test: str = Field(description="How to reproduce and verify it, e.g. a scripted run")


class PlayerMovementSpec(BaseModel):
    spec_id: str
    walk_speed_mps: float = Field(gt=0)
    sprint_speed_mps: float = Field(gt=0)
    accel_time_s: float = Field(ge=0, description="Time to reach full speed")
    decel_time_s: float = Field(ge=0)
    air_control: float = Field(ge=0, le=1)
    jump_velocity_mps: float = Field(gt=0)
    mouse_sensitivity_rad_per_px: float = Field(gt=0)
    mouse_smoothing: bool = Field(description="Must be false: smoothing makes turning feel laggy")
    pitch_limit_deg: float = Field(gt=0, lt=90)
    gamepad_look_speed_deg_s: float = Field(gt=0)
    move_while_turning: bool = Field(description="True: moving and turning are independent and simultaneous")
    capsule_radius_m: float = Field(gt=0)
    capsule_height_m: float = Field(gt=0)
    eye_height_m: float = Field(gt=0)
    step_height_m: float
    max_floor_angle_deg: float
    floor_snap_m: float = Field(ge=0)
    uses_delta_time: bool = Field(description="Movement must not depend on frame rate")
    head_bob_amplitude_m: float = Field(ge=0, description="Keep tiny or zero for comfort")
    fall_respawn_y_m: float
    glitch_checks: list[GlitchCheck] = Field(min_length=7)
    open_creator_decisions: list[str]


# ================= Lighting agent =================
class CloudSpec(BaseModel):
    trend: Literal["gathering", "building", "full", "breaking"] = Field(description="How the sky is changing in this phase")
    coverage: float = Field(ge=0, le=1, description="Share of the sky under cloud")
    darkness: float = Field(ge=0, le=1, description="0 = moonlit grey cloud, 1 = near-black storm cloud")
    base_height_m: float = Field(gt=0, description="Height of the cloud base above the sea")
    drift_mps: float = Field(ge=0, description="How fast the cloud moves across the sky")
    top_colour: HexColour
    underside_colour: HexColour
    moon_gap: bool = Field(description="The cloud thins to sparse wisps across the moon, so it shows through")
    low_coverage: float = Field(ge=0, le=1, description="Second, lower layer of darker cloud: share of the sky (0 = none)")
    low_opacity: float = Field(ge=0, le=1, description="How solid the low layer is; below 1 so lightning shows through it")
    low_drift_mps: float = Field(ge=0, description="How fast the low layer moves across the sky")
    low_colour: HexColour
    note: str


class RainSpec(BaseModel):
    intensity: float = Field(ge=0, le=1, description="0 = dry, 1 = the heaviest rain in the game")
    slant_deg: float = Field(ge=0, le=60, description="How far the wind blows the rain off vertical")
    colour: HexColour
    note: str


class PhaseLightning(BaseModel):
    enabled: bool
    style: Literal["none", "cloud_to_cloud", "cloud_to_sea"] = Field(description="Where the flashes run")
    interval_s: tuple[float, float] | None = Field(description="Min and max gap between flashes; null when disabled")
    lights_cloud_base: bool = Field(description="A flash lights the underside of the cloud it runs through")
    note: str


class LightPhase(BaseModel):
    phase_id: Literal["ISLAND", "OUTBOUND", "RETURN", "BEACON_RELIT"]
    ambient_colour: HexColour
    ambient_energy: float = Field(ge=0, le=1.5)
    fog_colour: HexColour
    fog_density: float = Field(ge=0, le=0.05)
    hazard_visibility_m: int = Field(ge=20, description="Distance at which hazards stay readable")
    clouds: CloudSpec
    rain: RainSpec
    lightning: PhaseLightning
    note: str


class MoonSpec(BaseModel):
    state: Literal["absent", "eclipsed", "full"] = Field(description="'full' until the Flighted ship eclipses it")
    look: str = Field(description="The vibe, e.g. a huge low supermoon")
    colour: HexColour
    light_energy: float = Field(ge=0, le=2.0, description="Moonlight (DirectionalLight3D) energy")
    disc_scale: float = Field(ge=1.0, le=4.0, description="Apparent size of the disc compared with an ordinary moon")
    elevation_deg: float = Field(ge=5, le=80)
    azimuth_deg: float = Field(ge=0, lt=360, description="Compass bearing from the lighthouse: 0 = north (Godot -Z), 180 = south (+Z, the Saltgate)")
    position_note: str = Field(description="Where it sits and what that does to the scene")
    visible_disc: bool
    lights_crossings: bool = Field(description="Moonlight is strong enough to light the outbound and return crossings")
    eclipse_note: str = Field(description="How the later eclipse (the Flighted ship) will change it")


class LightningSpec(BaseModel):
    colour: HexColour
    peak_energy: float = Field(gt=0, le=8.0)
    flash_duration_s: tuple[float, float]
    max_flashes_per_second: float = Field(gt=0, le=3.0, description="Photosensitivity safety cap")
    thunder_delay_s_per_100m: float = Field(gt=0)
    driven_by: Literal["phase_and_route_position"] = Field(description="Never elapsed time (storm split)")
    reveals_hazards: bool = Field(description="A flash lights hazards in silhouette; it must never hide them")
    bolt_visible: bool = Field(description="A forked bolt is drawn in the sky during the flash")
    strobe_pulses: tuple[int, int] = Field(description="Min and max flickers of the cloud around the strike in one flash")
    strobe_gap_s: tuple[float, float] = Field(description="Min and max time between those flickers")
    strobe_scope: Literal["local_cloud"] = Field(
        description="The flickers stay in the cloud around the strike; only the one scene-wide flash counts "
                    "towards max_flashes_per_second")
    note: str


LightKind = Literal["beacon", "arc_lamp", "window_lamp", "steam_glow", "boat_lamp", "saint_calder_lights"]


class LightSource(BaseModel):
    source_id: str = Field(pattern=r"^LIGHT_[A-Z_]+$")
    kind: LightKind
    location: str
    colour: HexColour
    energy: float = Field(ge=0)
    range_m: float = Field(gt=0)
    behaviour: str = Field(description="Sweep, flicker, hum, failing, relit, and so on")
    godot_node: str = Field(description="Godot node type, e.g. SpotLight3D, OmniLight3D, MeshInstance3D emissive")
    casts_shadow: bool
    is_navigation_marker: bool = Field(description="Must be false: guidance comes from Arthur and Ted, not markers")


class BeaconSpec(BaseModel):
    sweep_period_s: float = Field(gt=0)
    beam_range_m: float = Field(gt=0)
    colour: HexColour
    states: list[str] = Field(min_length=3, description="e.g. dark, failing/flickering, relit")


class SaintCalderSpec(BaseModel):
    distance_m: float = Field(gt=500)
    colours: list[HexColour]
    technique: str = Field(description="How it is built: emissive window cards, billboard, sprite points")
    window_lights: bool = Field(description="The city's windows are lit")
    glow_at_lighthouse: float = Field(ge=0, le=1, description="How strongly it reads from the lighthouse (0-1)")
    glow_at_saltgate: float = Field(ge=0, le=1, description="How strongly it reads from the Saltgate quays (0-1)")
    seen_from_lighthouse: str
    seen_from_saltgate: str
    visible_through_fog: bool
    flicker: str
    is_navigation_marker: bool
    note: str


class LightingSpec(BaseModel):
    spec_id: str
    phases: list[LightPhase] = Field(min_length=4, max_length=4)
    moon: MoonSpec
    lightning: LightningSpec
    sources: list[LightSource] = Field(min_length=5)
    beacon: BeaconSpec
    saint_calder: SaintCalderSpec
    max_dynamic_lights: int = Field(ge=1, le=24)
    max_shadow_casters: int = Field(ge=0, le=4)
    legibility_checks: list[str] = Field(min_length=4)
    open_creator_decisions: list[str]
