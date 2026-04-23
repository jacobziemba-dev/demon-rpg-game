extends CharacterBody2D

@export var move_speed: float = 220.0

var _moving: bool = false


func _physics_process(_delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir.length_squared() > 0.01:
		input_dir = input_dir.normalized()
	_moving = input_dir.length_squared() > 0.01
	velocity = input_dir * move_speed
	move_and_slide()


func is_actually_moving() -> bool:
	return _moving


func get_foot_global_y() -> float:
	return global_position.y
