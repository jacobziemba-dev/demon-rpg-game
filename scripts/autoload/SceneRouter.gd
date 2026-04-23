extends Node

## All gameplay navigation: [member MAIN_ENTRY] and world are separate from [res://scenes/battle/Battle.tscn].
## Encounters set [member GameState.pending_wild] then [method change_scene_to] loads the battle scene
## (Pokémon-style: overworld unloads, combat is its own screen).

const MAIN_ENTRY := "res://scenes/Main.tscn"


func go_to_main_menu() -> void:
	await SceneTransition.change_scene_to(MAIN_ENTRY, 0.2, 0.2)


func go_to_world(path: String = "res://scenes/world/World.tscn") -> void:
	await SceneTransition.change_scene_to(path, 0.2, 0.25)


func go_to_battle() -> void:
	await SceneTransition.change_scene_to("res://scenes/battle/Battle.tscn", 0.22, 0.22)


func go_to_grimoire() -> void:
	await SceneTransition.change_scene_to("res://scenes/ui/Grimoire.tscn", 0.18, 0.2)


func begin_battle_from_world(player_global_pos: Vector2, world_scene_path: String, wild: DemonData) -> void:
	if wild == null:
		push_warning("begin_battle_from_world: wild demon is null")
		return
	GameState.mark_return_after_battle(player_global_pos)
	GameState.return_world_path = world_scene_path
	GameState.pending_wild = wild
	await go_to_battle()


func end_battle_win() -> void:
	var wild := GameState.pending_wild
	GameState.pending_wild = null
	if wild:
		GameState.capture_wild(wild)
	await SceneTransition.change_scene_to(GameState.return_world_path, 0.2, 0.25)


func end_battle_flee() -> void:
	GameState.pending_wild = null
	await SceneTransition.change_scene_to(GameState.return_world_path, 0.2, 0.25)


func end_battle_loss() -> void:
	GameState.pending_wild = null
	GameState.permadeath_reset()
	await go_to_main_menu()
