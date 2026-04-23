# Glitched Grimoire — CLAUDE.md

Developer reference for AI assistants working on this codebase.

## Project overview

**Glitched Grimoire** is a turn-based RPG built in **Godot 4.6** using **GDScript**. The gameplay loop is Pokémon-style: explore an overworld, trigger random encounters, battle demons, and capture them. The aesthetic is cyberpunk / digital corruption.

- **Engine**: Godot 4.6, rendering method: Mobile, target: 1280×720
- **Entry scene**: `res://scenes/Main.tscn`
- **No build step, no package manager** — open in Godot editor and press F5 to run

---

## Directory structure

```
scripts/
  autoload/       # Global singletons (loaded before any scene)
  battle/         # Battle logic, UI, and AI
  data/           # Resource class definitions (DemonData, SkillData)
  ui/             # Main menu and grimoire screen
  world/          # Player, encounter zones, world HUD, lore triggers
scenes/
  Main.tscn       # Entry point (hosts main menu)
  battle/
    Battle.tscn
  ui/
    MainMenu.tscn
    Grimoire.tscn
  world/
    World.tscn
    Player.tscn
    WorldOverlay.tscn
data/
  demons/         # .tres files — one per demon definition
  skills/         # .tres files — one per skill definition
addons/
  godot_mcp/      # MCP/Claude tooling addon — do not modify
```

---

## Architecture: autoload singletons

Three singletons are registered in `project.godot` and are globally accessible by name:

### GameState (`scripts/autoload/GameState.gd`)
Central run state for the current playthrough.

- `party: Array` — list of `{ "data": DemonData, "hp": int }` dicts
- `grimoire: Array[DemonData]` — all captured demons (alphabetically sorted)
- `active_party_index: int` — which party member is in the lead slot
- `pending_wild: DemonData` — set before entering a battle, read by BattleController
- `return_world_path: String` — world scene to reload after battle ends

Key signals: `party_changed`, `grimoire_changed`

Key methods:
| Method | Purpose |
|--------|---------|
| `start_new_run()` | Clears state, loads starter demon |
| `get_active_demon() -> Dictionary` | Returns current lead party slot |
| `update_active_hp(hp)` | Writes HP back to party after battle |
| `capture_wild(d)` | Adds demon to grimoire + party |
| `permadeath_reset()` | Clears everything on loss |
| `can_trigger_encounter()` | Checks encounter cooldown timer |
| `apply_post_battle_cooldown(secs)` | Blocks encounters for N seconds |

### SceneRouter (`scripts/autoload/SceneRouter.gd`)
All scene navigation goes through here. **Never call `get_tree().change_scene_to_file()` directly.**

| Method | Goes to |
|--------|---------|
| `go_to_main_menu()` | `scenes/Main.tscn` |
| `go_to_world(path)` | World scene (default `World.tscn`) |
| `go_to_battle()` | `scenes/battle/Battle.tscn` |
| `go_to_grimoire()` | `scenes/ui/Grimoire.tscn` |
| `begin_battle_from_world(pos, world_path, wild)` | Saves return position, sets pending_wild, transitions to battle |
| `end_battle_win()` | Captures wild, returns to world |
| `end_battle_flee()` | Returns to world, no capture |
| `end_battle_loss()` | Permadeath reset, returns to main menu |

All methods are `async` — always `await` them.

### SceneTransition (`scripts/autoload/SceneTransition.gd`)
Fade-in/fade-out overlay. Called only by SceneRouter; do not call directly.

---

## Data model

### DemonData (`scripts/data/DemonData.gd`)
```gdscript
class_name DemonData
extends Resource

@export var id: String
@export var display_name: String
@export var portrait: Texture2D
@export var max_hp: int
@export var attack: int
@export var defense: int
@export var signature_skill: SkillData
```

### SkillData (`scripts/data/SkillData.gd`)
```gdscript
class_name SkillData
extends Resource

@export var id: String
@export var display_name: String
@export var power_bonus: int   # added to attack when skill is used
```

**Important**: Runtime HP is never stored in `DemonData`. It lives in the party slot dict `{ "data": DemonData, "hp": int }` inside `GameState.party`. `DemonData` is a static resource definition only.

---

## Battle system

File: `scripts/battle/BattleController.gd`

### Damage formula
```
damage = max(1, attacker_atk - defender_def)
new_hp  = max(0, defender_hp - damage)
```

### Actions
| Action | Effect |
|--------|--------|
| Attack | Player attacks with base `attack` stat |
| Defend | Grants `_temp_def_bonus = 2` absorbed on the very next enemy hit |
| Skill | Once per battle; uses `attack + signature_skill.power_bonus` |
| Flee | 68% success; on failure enemy gets a free attack |

### Enemy AI (`scripts/battle/BattleAI.gd`)
- Stateless `RefCounted` class
- Grants a flat attack bonus when enemy HP ≤ 33% of max (desperate strike)

### Battle outcomes
- **Win**: `SceneRouter.end_battle_win()` — wild captured → added to grimoire and party
- **Flee**: `SceneRouter.end_battle_flee()` — return to world, no capture
- **Loss**: `SceneRouter.end_battle_loss()` — permadeath reset, back to main menu

The `_busy: bool` flag in `BattleController` prevents queuing multiple actions during animation delays.

---

## Encounter flow

1. Player walks into an `EncounterZone` (Area2D) — timer starts, ticking every **0.85 s**
2. Each tick checks: player is in group `"player"`, player is moving (`is_actually_moving()`), `GameState.can_trigger_encounter()`, `randf() < encounter_chance_per_tick` (default **0.22**)
3. A random demon path is chosen from `wild_paths` and loaded
4. `SceneRouter.begin_battle_from_world(player_pos, world_scene_path, wild)` is called
5. After battle resolves, world is restored to saved player position
6. A **2-second post-battle cooldown** prevents an immediate re-trigger

---

## GDScript conventions

- **Node caching**: use `@onready var foo = $Path` — never cache in `_init()`
- **Async**: all timed waits use `await get_tree().create_timer(x).timeout`; all navigation uses `await SceneRouter.*`
- **Signals**: declare at top of file, connect in `_ready()`, emit from the owning class only
- **Resource classes**: always declare `class_name` at the top; use `@export` for every inspectable field
- **Non-fatal errors**: use `push_warning("context: message")`, not `print()`
- **Groups**: player node must be in group `"player"` for encounter and world systems to find it

---

## Adding content

### New demon
1. In the Godot editor: right-click `data/demons/` → New Resource → select `DemonData`
2. Fill in all `@export` fields including a portrait texture and optionally a `SkillData` resource
3. Save as `data/demons/<name>.tres`

### New skill
1. Right-click `data/skills/` → New Resource → select `SkillData`
2. Fill fields, save as `data/skills/<name>.tres`
3. Assign to a demon's `signature_skill` field

### Add demon to wild encounter pool
Open `scenes/world/World.tscn` → select the `EncounterZone` node → append the new `.tres` path to the `wild_paths` array in the Inspector.

### New scene / screen
1. Create the scene file in the appropriate `scenes/` subdirectory
2. Add a navigation method to `SceneRouter.gd` that calls `SceneTransition.change_scene_to(...)`
3. Wire up any back-button to the appropriate `SceneRouter.*` method

---

## Testing

There is no automated test framework. Test manually by running from the Godot editor (F5):

- Walk into the encounter zone and verify a battle starts
- Complete a battle (win, flee, loss) and confirm correct world/menu return
- Check HP is saved correctly to `GameState` after battle
- Verify grimoire updates after capturing a demon
- Confirm the party bar cycles correctly in the world HUD

---

## Version control

- Branch: work on feature branches, merge to `main`
- `.gitignore`: excludes `.godot/` (engine cache) and `/android/`
- `.gitattributes`: enforces LF line endings for all text files
- `.editorconfig`: UTF-8 charset, auto EOL

---

## Addons

`addons/godot_mcp/` — MCP (Model Context Protocol) integration that enables Claude AI tooling within the Godot editor. Loaded as an autoload (`MCPRuntime`). **Do not modify addon files** unless specifically working on the MCP integration itself.
