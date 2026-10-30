# Placeholder audio: source and licence

Every file here is **synthesised by `tools/make_placeholder_audio.py`** (numpy: shaped noise and sine partials, fixed random seed, 22,050 Hz mono 16-bit). No third-party recordings or samples were used, so there is nothing to license from anyone. The project releases the generated files as **CC0 (public domain)**. Re-run the script to regenerate them exactly.

| File | What it is | Used as |
|---|---|---|
| `wind_loop.wav` | 12 s seamless loop: band-limited noise with slow gusts and a faint whistle | wind layer (Ambience bus) |
| `rain_loop.wav` | 8 s seamless loop: high noise hiss, droplet ticks and a low patter | rain layer (Ambience bus) |
| `machinery_loop.wav` | 8 s seamless loop: boiler rumble, 50 Hz dynamo hum and harmonics, a faint whine, steam hiss, a slow beat | boiler and dynamo, a 3D source in the basement |
| `engine_loop.wav` | 4 s seamless loop: a steam launch chugging four times a second | the boat's engine while under way |
| `bell.wav` | 5 s: a struck bell from inharmonic partials with beating | buoy bells (3D) |
| `foghorn.wav` | 4.5 s: two detuned low harmonic voices, slow attack | the passenger ship's foghorn at SHIP_FAIL (3D, from the ship) |
| `ship_impact.wav` | 6 s: a crack, a sub thump, falling steel groan and rubble | the ship striking the rock (3D, from the ship) |
| `knock.wav` | 1.6 s: three knuckle raps on a heavy wooden door | the player knocking at the front door (3D, at the door) |

These are stand-ins for Gate 1 (Technical Strategy: placeholder audio is acceptable). Replace them one by one with real recordings and record the new source and licence here. The mix is in `data/world/audio_spec.json`.

I could not listen to these: they were checked numerically (peak, level, spectrum, loop seams) and not by ear. The creator should judge them.
