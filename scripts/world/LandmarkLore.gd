extends Area2D

## Step into the area to show a short world message (ancient code fragment / sign).

@export_multiline var lore: String = "…"
@export var cooldown_seconds: float = 6.0

var _until_ms: int = 0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if lore.is_empty():
		return
	var now := Time.get_ticks_msec()
	if now < _until_ms:
		return
	_until_ms = now + int(cooldown_seconds * 1000.0)
	var hud := get_tree().get_first_node_in_group("world_hud")
	if hud and hud.has_method("show_lore"):
		hud.show_lore(lore)
