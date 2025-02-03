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
		transition.emit(self, "falling")

	body.velocity = Vector3(
		move_toward(body.velocity.x, 0, DECELERATION),
		body.velocity.y,
		move_toward(body.velocity.z, 0, DECELERATION),
	)
	if Input.is_key_pressed(KEY_SPACE):
		transition.emit(self, "jumping")

	body.move_and_slide()
	var col := body.get_last_slide_collision()
	if col:
		_handle_collisions(col)


func _handle_collisions(col: KinematicCollision3D) -> void:
	for i: int in col.get_collision_count():
		var collider := col.get_collider(i)
		if collider.is_in_group("Bubble"):
			_handle_bubble_collision(collider, col.get_normal(i))


func _handle_bubble_collision(collider: Node3D, normal: Vector3) -> void:
	if normal.y > 0.5:
		body.velocity.y = JUMP_FORCE
		collider.queue_free()
	else:
		var dir := Vector2(
		collider.global_position.x, collider.global_position.z
		) - Vector2(
		collider.global_position.x, collider.global_position.z
		).move_toward(Vector2(
		body.global_position.x, body.global_position.z
		), 1.0)
		body.velocity = -Vector3(dir.x * 30.0, body.velocity.y, dir.y * 30.0)
		transition.emit(self, "pushback")


func input(_event: InputEvent) -> void:
	if _event is InputEventKey:
		match _event.keycode:
			KEY_W, KEY_A, KEY_S, KEY_D:
				transition.emit(self, "running")
