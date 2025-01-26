extends StaticBody3D

@export var is_good: bool = false
@export var direction: Vector3 = Vector3.ZERO
@export var speed: float = 0.15
@export var decel_speed: float = 0.0005
@export var decel_start_time: float = 0.2
@export var magnitude: float = PI / 6

var _height_mod: float = 0
var _start_deccel: bool = false

@onready var area: Area3D = $Area

func _handle_body_entered(body: Node3D) -> void:
	var collider: Node3D = body
	if not collider.is_in_group("Player"):
		return
	var norm: Vector3 = (body.global_position - global_position).normalized()
	if norm.y > .5:
		body.rpc("stomp")
	else:
		body.rpc("pushback", self)
	rpc("burst")


func _handle_body_exited(_body: Node3D) -> void:
	if collision_layer != 0:
		return
	collision_layer = 1
	collision_mask = 1


func _handle_area_collision(_area: Area3D) -> void:
	var par: Node3D = _area.get_parent()
	if par == null:
		return

	if par.is_in_group("Bubble") and not par.is_in_group("BossBubble"):
		var new_speed: float = (par.speed + speed) / 2
		direction = (position - par.position.move_toward(position, 1))
		speed = new_speed


func _on_timeout() -> void:
	_start_deccel = true
	collision_layer = 1
	collision_mask = 1

func _ready() -> void:
	multiplayer.allow_object_decoding = true
	name += "BUBBLE"
	if is_multiplayer_authority():
		area.connect("area_entered", _handle_area_collision)
		area.connect("body_exited", _handle_body_exited)
		area.connect("body_entered", _handle_body_entered)
	var tween: Tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "scale", Vector3.ONE, decel_start_time * 3)

	var timer: SceneTreeTimer = get_tree().create_timer(decel_start_time)
	timer.connect("timeout", _on_timeout)


@rpc("reliable")
func net_pushback(collider: Node3D) -> void:
	collider.pushback(self)


@rpc("reliable")
func net_stomp(collider: Node3D) -> void:
	collider.stomp()


func _check_for_players(col: KinematicCollision3D) -> void:
	if col == null:
		return
	for c in col.get_collision_count():
		var collider: Node3D = col.get_collider(c)
		if collider == null:
			return
		if not collider.is_in_group("Player"):
			return
		var norm: Vector3 = col.get_normal(c)
		if norm.y > 0 and abs(norm.y) > abs(norm.x) and abs(norm.y) > abs(norm.z):
			rpc("net_stomp", collider)
			collider.stomp()
			rpc("burst")
			return
		rpc("net_pushback", collider)
		collider.pushback(self)
		rpc("burst")


func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	position.y = position.y + sin(_height_mod) / 256
	_height_mod += delta

	speed = max(speed, 0)
	var col: KinematicCollision3D = move_and_collide(direction * speed, false, 0, true)
	if col:
		for c: int in col.get_collision_count():
			if col.get_collider(c).is_in_group("Terrain"):
				if col.get_normal().x:
					direction.x *= -1
				if col.get_normal().y:
					direction.y *= -1
				if col.get_normal().z:
					direction.z *= -1

	rpc("_net_update_position", global_position)
	if not _start_deccel:
		return
	speed -= decel_speed


@rpc("unreliable")
func _net_update_position(real_pos: Vector3) -> void:
	global_position = real_pos


@rpc("any_peer", "call_local", "reliable")
func burst() -> void:
	self.queue_free()
