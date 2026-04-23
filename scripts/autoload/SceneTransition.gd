extends CanvasLayer

## Full-screen fade before/after [method SceneTree.change_scene_to_file] (Pokémon-style handoff
## between the overworld scene and the dedicated combat scene).
var _rect: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.color = Color(0, 0, 0, 0)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.offset_left = 0.0
	_rect.offset_top = 0.0
	_rect.offset_right = 0.0
	_rect.offset_bottom = 0.0
	add_child(_rect)


func change_scene_to(path: String, fade_out: float = 0.2, fade_in: float = 0.2) -> void:
	if path.is_empty():
		return
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_rect, "color", Color(0, 0, 0, 1), fade_out)
	await tw.finished
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("SceneTransition: failed to load %s (err %d)" % [path, err])
		tw = create_tween()
		tw.tween_property(_rect, "color", Color(0, 0, 0, 0), fade_in)
		await tw.finished
		_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
	# New scene is live; unhide the frame before drawing.
	await get_tree().process_frame
	tw = create_tween()
	tw.tween_property(_rect, "color", Color(0, 0, 0, 0), fade_in)
	await tw.finished
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
