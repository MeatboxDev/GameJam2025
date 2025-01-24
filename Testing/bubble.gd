extends StaticBody3D

@export var direction: Vector3 = Vector3.ZERO
@export var speed: float = 0.15
@export var decel_speed: float = 0.0005
@export var decel_start_time: float = 0.2

@export var magnitude: float = PI/6

var height_mod: float = 0

var start_deccel: bool = false


func _ready() -> void:
	await get_tree().create_timer(decel_start_time).timeout
	start_deccel = true
	speed = 0.1


func _process(delta: float) -> void:
	position.y = position.y + sin(height_mod) / 256
	height_mod += delta

	if speed < 0: return
	position += direction * speed
	if not start_deccel:
		return
	speed -= decel_speed
