extends StaticBody3D

var speed := 0.0
var direction := Vector3.ZERO


func _process(delta: float) -> void:
	direction = direction.move_toward(Vector3.ZERO, delta)
	move_and_collide(direction * speed)
