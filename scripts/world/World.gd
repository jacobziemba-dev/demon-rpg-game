extends Node2D

@onready var player: CharacterBody2D = $Player


func _ready() -> void:
	if not GameState.has_battle_ready_party():
		await SceneRouter.go_to_main_menu()
		return
	var saved: Variant = GameState.consume_return_position_if_any()
	if saved is Vector2:
		player.global_position = saved as Vector2
	elif has_node("SpawnPoint"):
		player.global_position = get_node("SpawnPoint").global_position
