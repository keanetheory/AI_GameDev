---
id: sys_steam_power
type: power_system
name: Steam Power & Electric Light
category: technology
access: widespread
rarity: common
status: draft
---

# Steam Power & Electric Light

## How It Works (input → effect)
- **Lighting:** coal fires a boiler, which drives a steam engine and dynamo, which power electric arc lamps.
  - All lights in Corvaine are steam-driven, including Saint Calder's windows.
- **Steam launches:** small boats powered by mini steam engines.
- **Printing:** crude but clear printed posters and documents.

## Limits
- Requires a steady coal supply and a working burner in the arc lamp.
- Burners can fail, as the lighthouse's has before the game begins. Nobody notices until the boiler is fed and the dynamo runs but the beacon stays dark; Ted finds the broken burner when he inspects the lamp, after the sailors arrive.

## Costs
Coal, plus the labour of shovelling it into the engine.

## Counters
No coal or a broken burner means no light.

## Effects on Society
- **The city:** glows with electric light.
- **The coast:** depends on it for the lighthouse.
- **Warfare:** do firearms exist? TBD. Garrisons still wear chain mail, which needs an explanation.

## Gameplay Translation
| Ability | Input/Resource | Effect | Cost | Cooldown/Limit |
|---|---|---|---|---|
| Stoke the engine | Coal, shovel | Raises steam to power the beacon | Time, effort | Must be maintained |
| Fit the burner | Replacement burner for the arc lamp (under 1 ft tall) | Restores the beacon | Requires the Saltgate trip | One-time |
| Pilot steam launch | Coal, engine | Crosses the Gullwater | Fuel; storm makes handling hard | n/a |

## VFX & SFX Direction
- **vfx_colors:** ["#F2EFE6", "#C07A1E"]
- **vfx_shapes:**
  - Harsh white arc-lamp glare with flicker and crackle
  - Steam plumes
  - Firebox glow
- **sfx:** boiler roar, piston thump, dynamo whine, arc crackle, hiss of steam valves

## Asset Prompts
- **burner_prop:** "Small 1800s electric arc lamp burner under a foot tall, brass and iron housing, carbon rod electrodes, thick glass, cloth-wrapped wiring, gritty dark cel-shaded style, heavy ink outlines, prop design sheet"
