extends State

@export var body: CharacterBody3D


func on_set() -> void:
	assert(body)


func on_leave() -> void:
	pass


func update() -> void:
	pass


func physics_update() -> void:
	if not body.is_on_floor():
		transition.emit(self, "falling")

	body.velocity = Vector3(
		move_toward(body.velocity.x, 0, body.deceleration),
		body.velocity.y,
		move_toward(body.velocity.z, 0, body.deceleration),
	)
	if Input.is_key_pressed(KEY_SPACE):
		transition.emit(self, "jumping")

	body.move_and_slide()
	body.handle_collisions()


func input(_event: InputEvent) -> void:
	if _event is InputEventKey and _event.keycode == KEY_F1 and _event.pressed:
		transition.emit(self, "Interface")
	if _event is InputEventKey:
		match _event.keycode:
			KEY_W, KEY_A, KEY_S, KEY_D:
				transition.emit(self, "running")
