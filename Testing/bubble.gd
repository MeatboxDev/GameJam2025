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

func _ready() -> void:
	area.connect("area_entered", _handle_area_collision)
	var tween: Tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "scale", Vector3.ONE, decel_start_time * 3)

	var timer: SceneTreeTimer = get_tree().create_timer(decel_start_time)
	timer.connect("timeout", _on_timeout)


func _process(delta: float) -> void:
	position.y = position.y + sin(_height_mod) / 256
	_height_mod += delta

	if not is_multiplayer_authority():
		return

	if speed < 0:
		return
	var col: KinematicCollision3D = move_and_collide(direction * speed)
	if col:
		if col.get_collider().is_in_group("Terrain"):
			if col.get_normal().x: direction.x *= -1
			if col.get_normal().y: direction.y *= -1
			if col.get_normal().z: direction.z *= -1
	if not _start_deccel:
		return
	speed -= decel_speed
	rpc("_net_update_position", global_position)

@rpc("unreliable")
func _net_update_position(real_pos: Vector3) -> void:
	global_position = real_pos


@rpc("any_peer", "reliable")
func _net_burst() -> void:
	self.queue_free()


func burst() -> void:
	rpc("_net_burst")
	self.queue_free()
