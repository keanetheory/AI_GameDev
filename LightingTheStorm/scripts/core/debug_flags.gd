# debug_flags.gd - one answer to "may the on-screen debug aids show?" (backlog T21).
# The lighting phase label and the F5-F8 phase jumps (lighting_rig.gd) and the F9-F11 keys (game_state.gd) are for
# the builder, not the player, and a tester must not mistake the label for a HUD (Pillar 3). They are on in a debug
# build (the editor, a debug export) and always off in a release export. To switch them off in a debug build too,
# for a tester, pass the user argument after "--":  godot --path . -- --no-debug-ui
extends RefCounted

const OFF_ARGUMENT := "--no-debug-ui"


static func allowed() -> bool:
	return OS.is_debug_build() and not OS.get_cmdline_user_args().has(OFF_ARGUMENT)
