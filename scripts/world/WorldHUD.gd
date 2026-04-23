extends CanvasLayer

## Floating lore / toast messages while exploring.

@onready var _lore: RichTextLabel = %LoreToast
@onready var _timer: Timer = $ToastTimer


func _ready() -> void:
	add_to_group("world_hud")
	_lore.visible = false
	_timer.one_shot = true
	_timer.timeout.connect(_hide_toast)


func show_lore(text: String, seconds: float = 4.5) -> void:
	if text.is_empty():
		return
	_lore.text = "[i]%s[/i]" % text
	_lore.visible = true
	_timer.start(seconds)


func _hide_toast() -> void:
	_lore.visible = false
