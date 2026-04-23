extends Control

signal attack_pressed
signal defend_pressed
signal skill_pressed
signal flee_pressed

var _p_data: DemonData
var _w_data: DemonData
var _skill_spent: bool = false

@onready var player_bar: ProgressBar = %PlayerHPBar
@onready var wild_bar: ProgressBar = %WildHPBar
@onready var player_label: Label = %PlayerNameLabel
@onready var wild_label: Label = %WildNameLabel
@onready var player_stat: Label = %PlayerStatLine
@onready var wild_stat: Label = %WildStatLine
@onready var log_box: RichTextLabel = %BattleLog
@onready var btn_attack: Button = %BtnAttack
@onready var btn_defend: Button = %BtnDefend
@onready var btn_skill: Button = %BtnSkill
@onready var btn_flee: Button = %BtnFlee
@onready var error_panel: PanelContainer = %ErrorPanel


func _ready() -> void:
	btn_attack.pressed.connect(func(): attack_pressed.emit())
	btn_defend.pressed.connect(func(): defend_pressed.emit())
	btn_skill.pressed.connect(func(): skill_pressed.emit())
	btn_flee.pressed.connect(func(): flee_pressed.emit())
	if error_panel:
		error_panel.visible = false


func setup(p_data: DemonData, w_data: DemonData, p_hp: int, w_hp: int) -> void:
	_p_data = p_data
	_w_data = w_data
	player_label.text = p_data.display_name if p_data else "???"
	wild_label.text = w_data.display_name if w_data else "???"
	set_player_hp(p_hp, p_data.max_hp if p_data else 1)
	set_wild_hp(w_hp, w_data.max_hp if w_data else 1)
	_refresh_stat_lines(p_hp, w_hp)
	_skill_spent = false
	if p_data and p_data.signature_skill:
		btn_skill.visible = true
		btn_skill.text = p_data.signature_skill.display_name
		btn_skill.disabled = false
	else:
		btn_skill.visible = false
	log_box.clear()
	append_log("Battle link established.")
	append_log("Review stats, then choose an action.")


func set_skill_used() -> void:
	_skill_spent = true
	btn_skill.disabled = true


func _refresh_stat_lines(p_hp: int, w_hp: int) -> void:
	if _p_data:
		player_stat.text = (
			"ATK %d · DEF %d · HP %d / %d" % [_p_data.attack, _p_data.defense, p_hp, _p_data.max_hp]
		)
	else:
		player_stat.text = ""
	if _w_data:
		wild_stat.text = (
			"ATK %d · DEF %d · HP %d / %d" % [_w_data.attack, _w_data.defense, w_hp, _w_data.max_hp]
		)
	else:
		wild_stat.text = ""


func set_player_hp(current: int, max_hp: int) -> void:
	player_bar.max_value = max_hp
	player_bar.value = clampi(current, 0, max_hp)
	_refresh_stat_lines(current, int(wild_bar.value))


func set_wild_hp(current: int, max_hp: int) -> void:
	wild_bar.max_value = max_hp
	wild_bar.value = clampi(current, 0, max_hp)
	_refresh_stat_lines(int(player_bar.value), current)


func append_log(line: String) -> void:
	log_box.append_text(line + "\n")


func set_buttons_enabled(on: bool) -> void:
	btn_attack.disabled = not on
	btn_defend.disabled = not on
	btn_flee.disabled = not on
	if btn_skill.visible:
		btn_skill.disabled = _skill_spent or not on


func show_no_demons_error() -> void:
	_show_error("No demons in your Grimoire. Cannot battle.\nStart a new run from the main menu.")
	set_buttons_enabled(false)
	var t := get_tree().create_timer(2.0)
	t.timeout.connect(func(): SceneRouter.go_to_main_menu())


func show_no_enemy_error() -> void:
	_show_error("No enemy data. Returning to menu.")
	set_buttons_enabled(false)
	await get_tree().create_timer(1.5).timeout
	await SceneRouter.go_to_main_menu()


func _show_error(msg: String) -> void:
	if error_panel:
		error_panel.visible = true
		var l := error_panel.get_node_or_null("Margin/VBox/ErrorLabel")
		if l is Label:
			(l as Label).text = msg
	append_log(msg)
