# Music: source and licence

One row per piece. The credit text goes on the itch.io page and in the game's credits (T62), so copy it exactly as the licence asks.

The originals (.m4a, as delivered on 3 Nov 2026) are in `source/` (ignored by Godot); the game plays the Ogg Vorbis copies made from them (ffmpeg, libvorbis q6, cover art and tags dropped). The creator's own music, credited as **KeaneTheory** (creator, 3 Nov 2026; the files' own tags say Cynicelt / Paul Keane).

| File | Title | Composer / source | Licence | Credit text | When it plays |
|---|---|---|---|---|---|
| `landed_at_bracken_isle.ogg` | Landed at Bracken Isle | the creator (tagged "Cynicelt"; the file's title tag reads "Landed at Saltgate") | the creator's own | Music by KeaneTheory | from the start until Ted's briefing line TED_S3_02 ends (fallback: BOAT_CAST_OFF), looping |
| `get_to_saltgate.ogg` | Get to Saltgate | the creator (tagged "Paul Keane") | the creator's own | Music by KeaneTheory | until BURNER_PICKED_UP, looping |
| `get_to_bracken_isle.ogg` | Get to Bracken Isle | the creator (tagged "Cynicelt"; the title tag reads "My Song 11altalt") | the creator's own | Music by KeaneTheory | from BURNER_PICKED_UP to the end, looping; fades for the Failed screen, keeps playing on a win |
