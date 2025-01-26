extends StaticBody3D

const BUBBLE_SCALE := Vector3.ONE * 0.5
const BUBBLE_LIFE_DURATION := 5.0
const BUBBLE_FLASH_DURATION := 1.0
const BUBBLE_FLASH_TIMES := 18

@export var is_good: bool = false
@export var direction: Vector3 = Vector3.ZERO
@export var speed: float = 0.15
@export var decel_speed: float = 0.0005
@export var decel_start_time: float = 0.2
@export var magnitude: float = PI / 6

var _flash_times := 0
var _height_mod := 0.0
var _start_deccel := false

@onready var area: Area3D = $Area
@onready var bubble_popping: AudioStreamPlayer3D = $BubblePoppingStream
@onready var pop_particles: CPUParticles3D = $PopParticles


func _handle_body_entered(body: Node3D) -> void:
	var collider: Node3D = body
	if not collider.is_in_group("Player"):
		return
	var norm: Vector3 = (body.global_position - global_position).normalized()
	if norm.y > .3:
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
		if par.is_good != is_good:
			par.rpc("burst")
			rpc("burst")
			return
		var new_speed: float = (par.speed + speed) / 2
		direction = (position - par.position.move_toward(position, 1))
		speed = new_speed


func _on_timeout() -> void:
	_start_deccel = true
	collision_layer = 1
	collision_mask = 1


func _flash_out() -> void:
	if _flash_times == 0:
		rpc("burst")
		return
	_flash_times -= 1
	visible = !visible
	get_tree().create_timer(BUBBLE_FLASH_DURATION / BUBBLE_FLASH_TIMES).timeout.connect(_flash_out)

func _ready() -> void:
	multiplayer.allow_object_decoding = true
	name += "BUBBLE"
	if is_multiplayer_authority():
		area.connect("area_entered", _handle_area_collision)
		area.connect("body_exited", _handle_body_exited)
		area.connect("body_entered", _handle_body_entered)
		get_tree().create_timer(BUBBLE_LIFE_DURATION - BUBBLE_FLASH_DURATION).timeout.connect(
			func() -> void:
				_flash_times = BUBBLE_FLASH_TIMES
				_flash_out()
		)
	var tween: Tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "scale", BUBBLE_SCALE, decel_start_time * 3)

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


func _physics_process(delta: float) -> void:
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
	bubble_popping.stream = preload("res://Assets/SoundEffects/shooting_bubble.wav")
	bubble_popping.play(0.14)
	bubble_popping.pitch_scale = randf_range(0.95, 1.05)
	remove_child(bubble_popping)
	get_tree().get_current_scene().add_child(bubble_popping)
	bubble_popping.position = global_position

	remove_child(pop_particles)
	get_tree().get_current_scene().add_child(pop_particles)
	pop_particles.position = global_position
	pop_particles.restart()
	pop_particles.material_override = (
		$BubbleGood.material_override if is_good else $BubbleBad.material_override
	)

	get_tree().create_timer(bubble_popping.stream.get_length()).timeout.connect(
		bubble_popping.queue_free
	)
	get_tree().create_timer(pop_particles.lifetime).timeout.connect(pop_particles.queue_free)
	self.queue_free()
