extends Area2D

## Random encounter while player moves inside this area (tall grass / corrupted zone).

@export var zone_label: String = ""
@export var encounter_chance_per_tick: float = 0.22
@export var tick_interval: float = 0.85
@export var world_scene_path: String = "res://scenes/world/World.tscn"
@export var wild_paths: PackedStringArray = PackedStringArray(
	[
		"res://data/demons/wild_glitch.tres",
		"res://data/demons/wild_spam.tres",
	]
)

var _player_count: int = 0
var _timer: Timer


func _ready() -> void:
	var hl := get_node_or_null("HazardLabel") as Label
	if hl and not zone_label.is_empty():
		hl.text = zone_label
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_timer = Timer.new()
	_timer.wait_time = tick_interval
	_timer.one_shot = false
	_timer.timeout.connect(_on_tick)
	add_child(_timer)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_count += 1
		if _player_count == 1:
			_timer.start()


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_count = maxi(0, _player_count - 1)
		if _player_count == 0:
			_timer.stop()


func _on_tick() -> void:
	if _player_count <= 0:
		return
	if not GameState.can_trigger_encounter():
		return
	if not GameState.has_battle_ready_party():
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	if player.has_method("is_actually_moving") and not player.is_actually_moving():
		return
	if randf() > encounter_chance_per_tick:
		return
	if wild_paths.is_empty():
		return
	var path := wild_paths[randi() % wild_paths.size()]
	var wild: DemonData = load(path) as DemonData
	if wild == null:
		push_warning("EncounterZone: could not load demon at %s" % path)
		return
	GameState.apply_post_battle_cooldown(2.0)
	await SceneRouter.begin_battle_from_world(player.global_position, world_scene_path, wild)
