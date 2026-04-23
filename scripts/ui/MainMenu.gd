extends Control

@onready var _btn_new: Button = %BtnNewRun
@onready var _btn_grimoire: Button = %BtnGrimoire
@onready var _btn_quit: Button = %BtnQuit


func _ready() -> void:
	_btn_new.pressed.connect(_on_new_run_pressed)
	_btn_grimoire.pressed.connect(_on_grimoire_pressed)
	_btn_quit.pressed.connect(_on_quit_pressed)


func _on_new_run_pressed() -> void:
	GameState.start_new_run()
	await SceneRouter.go_to_world()


func _on_grimoire_pressed() -> void:
	await SceneRouter.go_to_grimoire()


func _on_quit_pressed() -> void:
	get_tree().quit()
