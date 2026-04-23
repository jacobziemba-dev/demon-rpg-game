extends Node

## Global run state: party, grimoire, battle handoff, encounter cooldown.

signal party_changed
signal grimoire_changed

const STARTER_DEMON_PATH := "res://data/demons/starter_demon.tres"

var party: Array = [] ## Array[Dictionary] — { "data": DemonData, "hp": int }
var grimoire: Array[DemonData] = []

## Index of the demon used in battle ([method get_active_demon]).
var active_party_index: int = 0

var pending_wild: DemonData = null
var return_world_path: String = "res://scenes/world/World.tscn"

var _return_position: Vector2 = Vector2.ZERO
var _consume_return_next: bool = false

var encounter_blocked_until_ms: int = 0


func _ready() -> void:
	_ensure_movement_actions()


func _ensure_movement_actions() -> void:
	_add_axis_action("move_left", KEY_A)
	_add_axis_action("move_left", KEY_LEFT)
	_add_axis_action("move_right", KEY_D)
	_add_axis_action("move_right", KEY_RIGHT)
	_add_axis_action("move_up", KEY_W)
	_add_axis_action("move_up", KEY_UP)
	_add_axis_action("move_down", KEY_S)
	_add_axis_action("move_down", KEY_DOWN)


func _add_axis_action(action: String, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	var has := false
	for existing in InputMap.action_get_events(action):
		if existing is InputEventKey and (existing as InputEventKey).physical_keycode == ev.physical_keycode:
			has = true
			break
	if not has:
		InputMap.action_add_event(action, ev)


func _clamp_active_party_index() -> void:
	if party.is_empty():
		active_party_index = 0
		return
	active_party_index = clampi(active_party_index, 0, party.size() - 1)


func cycle_active_party(delta: int) -> void:
	if party.is_empty():
		return
	active_party_index = posmod(active_party_index + delta, party.size())
	party_changed.emit()


func start_new_run() -> void:
	party.clear()
	grimoire.clear()
	pending_wild = null
	active_party_index = 0
	_consume_return_next = false
	_return_position = Vector2.ZERO
	encounter_blocked_until_ms = 0
	var starter: DemonData = load(STARTER_DEMON_PATH) as DemonData
	if starter:
		_add_party_member(starter, starter.max_hp)
	_clamp_active_party_index()
	party_changed.emit()
	grimoire_changed.emit()


func _add_party_member(data: DemonData, hp: int) -> void:
	party.append({"data": data, "hp": hp})


func get_active_demon() -> Dictionary:
	if party.is_empty():
		return {}
	_clamp_active_party_index()
	return party[active_party_index]


func update_active_hp(hp: int) -> void:
	if party.is_empty():
		return
	_clamp_active_party_index()
	var data: DemonData = party[active_party_index]["data"] as DemonData
	if data == null:
		return
	party[active_party_index]["hp"] = clampi(hp, 0, data.max_hp)
	party_changed.emit()


func has_battle_ready_party() -> bool:
	return not party.is_empty()


func add_to_grimoire(d: DemonData) -> void:
	if d == null:
		return
	grimoire.append(d)
	grimoire.sort_custom(func(a: DemonData, b: DemonData) -> bool:
		return a.display_name.to_lower() < b.display_name.to_lower()
	)
	grimoire_changed.emit()


func capture_wild(d: DemonData) -> void:
	if d == null:
		return
	add_to_grimoire(d)
	_add_party_member(d, d.max_hp)
	_clamp_active_party_index()
	party_changed.emit()


func mark_return_after_battle(world_pos: Vector2) -> void:
	_return_position = world_pos
	_consume_return_next = true


func consume_return_position_if_any() -> Variant:
	if not _consume_return_next:
		return null
	_consume_return_next = false
	var p := _return_position
	_return_position = Vector2.ZERO
	return p


func apply_post_battle_cooldown(seconds: float = 2.0) -> void:
	encounter_blocked_until_ms = Time.get_ticks_msec() + int(seconds * 1000.0)


func can_trigger_encounter() -> bool:
	return Time.get_ticks_msec() >= encounter_blocked_until_ms


func permadeath_reset() -> void:
	party.clear()
	grimoire.clear()
	pending_wild = null
	active_party_index = 0
	_consume_return_next = false
	_return_position = Vector2.ZERO
	encounter_blocked_until_ms = 0
	party_changed.emit()
	grimoire_changed.emit()
