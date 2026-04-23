extends Node2D

## Turn-based battle: Attack, Defend, optional Skill, Flee; enemy uses [BattleAI].

const FLEE_SUCCESS_CHANCE: float = 0.68

var _player_data: DemonData
var _wild_data: DemonData
var _player_hp: int = 0
var _wild_hp: int = 0
var _busy: bool = false
var _temp_def_bonus: int = 0
var _skill_used: bool = false

@onready var ui: Control = $CanvasLayer/UI
@onready var player_sprite: Sprite2D = $ShakeRoot/PlayerSide/PlayerSprite
@onready var enemy_sprite: Sprite2D = $ShakeRoot/EnemySide/EnemySprite
@onready var shake_root: Node2D = $ShakeRoot


func _ready() -> void:
	if not GameState.has_battle_ready_party():
		ui.show_no_demons_error()
		return
	if GameState.pending_wild == null:
		ui.show_no_enemy_error()
		return
	var slot: Dictionary = GameState.get_active_demon()
	_player_data = slot.get("data") as DemonData
	_player_hp = int(slot.get("hp", _player_data.max_hp))
	_wild_data = GameState.pending_wild
	_wild_hp = _wild_data.max_hp
	_setup_sprites()
	ui.setup(_player_data, _wild_data, _player_hp, _wild_hp)
	ui.attack_pressed.connect(_on_attack_pressed)
	ui.defend_pressed.connect(_on_defend_pressed)
	ui.skill_pressed.connect(_on_skill_pressed)
	ui.flee_pressed.connect(_on_flee_pressed)


func _setup_sprites() -> void:
	if _player_data and _player_data.portrait:
		player_sprite.texture = _player_data.portrait
	if _wild_data and _wild_data.portrait:
		enemy_sprite.texture = _wild_data.portrait


func _damage_from_values(attacker_atk: int, defender: DemonData, defender_hp: int) -> int:
	var raw: int = attacker_atk - defender.defense
	var dmg: int = maxi(1, raw)
	return maxi(0, defender_hp - dmg)


func _flash_sprite(spr: CanvasItem) -> void:
	if spr == null:
		return
	var t := create_tween()
	t.tween_property(spr, "modulate", Color(1, 0.4, 0.4, 1), 0.06)
	t.tween_property(spr, "modulate", Color.WHITE, 0.12)


func _shake() -> void:
	if shake_root == null:
		return
	var orig := shake_root.position
	var t := create_tween()
	for i in range(4):
		var o := Vector2(randf_range(-4, 4), randf_range(-3, 3))
		t.tween_property(shake_root, "position", orig + o, 0.04)
	t.tween_property(shake_root, "position", orig, 0.05)


func _check_wild_defeated() -> bool:
	if _wild_hp > 0:
		return false
	ui.append_log("Enemy deleted. Download complete.")
	GameState.update_active_hp(_player_hp)
	await SceneRouter.end_battle_win()
	return true


func _check_player_defeated() -> bool:
	if _player_hp > 0:
		return false
	ui.append_log("Your demon was corrupted. Run terminated.")
	await get_tree().create_timer(1.0).timeout
	await SceneRouter.end_battle_loss()
	return true


func _enemy_turn() -> void:
	ui.append_log("%s attacks!" % _wild_data.display_name)
	await get_tree().create_timer(0.35).timeout
	var atk_bonus: int = BattleAI.enemy_attack_bonus(_wild_data, _wild_hp, _wild_data.max_hp)
	var eff_atk: int = _wild_data.attack + atk_bonus
	var mitigated: int = _player_data.defense + _temp_def_bonus
	_temp_def_bonus = 0
	var raw: int = eff_atk - mitigated
	var dmg: int = maxi(1, raw)
	_player_hp = maxi(0, _player_hp - dmg)
	_flash_sprite(player_sprite)
	_shake()
	ui.set_player_hp(_player_hp, _player_data.max_hp)
	if atk_bonus > 0:
		ui.append_log(
			(
				"Desperate strike! (%d damage) Your HP: %d / %d"
				% [dmg, _player_hp, _player_data.max_hp]
			)
		)
	else:
		ui.append_log("You took %d. Your HP: %d / %d" % [dmg, _player_hp, _player_data.max_hp])


func _on_attack_pressed() -> void:
	if _busy:
		return
	if _player_data == null or _wild_data == null:
		return
	_busy = true
	ui.set_buttons_enabled(false)
	ui.append_log("%s attacks!" % _player_data.display_name)
	await get_tree().create_timer(0.35).timeout
	_wild_hp = _damage_from_values(_player_data.attack, _wild_data, _wild_hp)
	_flash_sprite(enemy_sprite)
	_shake()
	ui.set_wild_hp(_wild_hp, _wild_data.max_hp)
	if await _check_wild_defeated():
		return
	await get_tree().create_timer(0.45).timeout
	await _enemy_turn()
	if await _check_player_defeated():
		return
	_busy = false
	ui.set_buttons_enabled(true)


func _on_defend_pressed() -> void:
	if _busy:
		return
	_busy = true
	ui.set_buttons_enabled(false)
	_temp_def_bonus = 2
	ui.append_log("%s defends (+2 block vs the next hit)." % _player_data.display_name)
	await get_tree().create_timer(0.4).timeout
	await _enemy_turn()
	if await _check_player_defeated():
		return
	_busy = false
	ui.set_buttons_enabled(true)


func _on_skill_pressed() -> void:
	if _busy or _skill_used:
		return
	var sk: SkillData = _player_data.signature_skill if _player_data else null
	if sk == null:
		return
	_busy = true
	ui.set_buttons_enabled(false)
	ui.append_log("%s uses %s!" % [_player_data.display_name, sk.display_name])
	await get_tree().create_timer(0.35).timeout
	var atk: int = _player_data.attack + sk.power_bonus
	_wild_hp = _damage_from_values(atk, _wild_data, _wild_hp)
	_flash_sprite(enemy_sprite)
	_shake()
	ui.set_wild_hp(_wild_hp, _wild_data.max_hp)
	_skill_used = true
	ui.set_skill_used()
	if await _check_wild_defeated():
		return
	await get_tree().create_timer(0.45).timeout
	await _enemy_turn()
	if await _check_player_defeated():
		return
	_busy = false
	ui.set_buttons_enabled(true)


func _on_flee_pressed() -> void:
	if _busy:
		return
	_busy = true
	ui.set_buttons_enabled(false)
	if randf() < FLEE_SUCCESS_CHANCE:
		ui.append_log("Jack-out successful — returning to the underworld.")
		GameState.update_active_hp(_player_hp)
		await get_tree().create_timer(0.55).timeout
		await SceneRouter.end_battle_flee()
		return
	ui.append_log("Jack-out failed — trace locked! Enemy gets a free swing.")
	await get_tree().create_timer(0.55).timeout
	await _enemy_turn()
	if await _check_player_defeated():
		return
	_busy = false
	ui.set_buttons_enabled(true)
