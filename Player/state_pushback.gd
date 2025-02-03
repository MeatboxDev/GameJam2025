extends State

const JUMP_FORCE := 30.0
const DECELERATION := 4.0

@export var body: CharacterBody3D

var _push_timer: SceneTreeTimer

func _on_push_timeout() -> void:
	transition.emit(self, "idle")


func on_set() -> void:
	assert(body)
	_push_timer = get_tree().create_timer(0.35)
	_push_timer.timeout.connect(_on_push_timeout)


func on_leave() -> void:
	_push_timer.timeout.disconnect(_on_push_timeout)


func update() -> void:
	pass


func physics_update() -> void:
	body.velocity = body.velocity.move_toward(Vector3.ZERO, 1.0)
	body.move_and_slide()
	var col := body.get_last_slide_collision()
	if col:
		_handle_collisions(col)


func _handle_collisions(col: KinematicCollision3D) -> void:
	for i: int in col.get_collision_count():
		var collider := col.get_collider(i)
		if collider.is_in_group("Bubble"):
			_handle_bubble_collision(collider, col.get_normal(i))


func _handle_bubble_collision(collider: Node3D, _normal: Vector3) -> void:
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
	pass # TODO: Implement
