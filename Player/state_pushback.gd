extends State

@export var body: CharacterBody3D

var _push_timer: SceneTreeTimer

func _on_push_timeout() -> void:
	transition.emit(self, "idle")


func on_set() -> void:
	assert(body)
	_push_timer = get_tree().create_timer(body.pushback_time)
	_push_timer.timeout.connect(_on_push_timeout)


func on_leave() -> void:
	_push_timer.timeout.disconnect(_on_push_timeout)


func update() -> void:
	pass


func physics_update() -> void:
	body.velocity = body.velocity.move_toward(Vector3.ZERO, 1.0)
	body.move_and_slide()
	body.handle_collisions()


func input(_event: InputEvent) -> void:
	pass # TODO: Implement
