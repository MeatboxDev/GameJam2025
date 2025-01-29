extends State

const JUMP_FORCE := 30.0
const DECELERATION := 4.0

@export var body: CharacterBody3D


func on_set() -> void:
	assert(body)


func on_leave() -> void:
	pass


func update() -> void:
	pass


func physics_update() -> void:
	if not body.is_on_floor():
		transition.emit(self, "jumping")  # TODO: Create and change to a falling state

	body.velocity = Vector3(
		move_toward(body.velocity.x, 0, DECELERATION),
		body.velocity.y,
		move_toward(body.velocity.z, 0, DECELERATION),
	)
	if Input.is_key_pressed(KEY_SPACE):
		transition.emit(self, "jumping")

	body.move_and_slide()


func input(_event: InputEvent) -> void:
	if _event is InputEventKey:
		match _event.keycode:
			KEY_W, KEY_A, KEY_S, KEY_D:
				transition.emit(self, "running")
