extends CharacterBody3D

const NW := preload("res://Networking/network.gd")

const JUMP_SOUNDS := [
	preload("res://Assets/SoundEffects/salto_1.wav"),
	preload("res://Assets/SoundEffects/salto_2.wav")
]

const HURT_SOUNDS := [
	preload("res://Assets/SoundEffects/herida_1.wav"),
	preload("res://Assets/SoundEffects/herida_2.wav"),
	preload("res://Assets/SoundEffects/herida_3.wav"),
]

const BUBBLE_GOOD: PackedScene = preload("res://Testing/bubble_purple.tscn")
const BUBBLE_BAD: PackedScene = preload("res://Testing/bubble_pink.tscn")
const DEG_45: float = PI / 4.0
const DEG_N45: float = -DEG_45
const XZ = preload("res://Networking/xyz_to_xz.gd")

@export var body_rotation_strength: float = 10.0
@export var decel_speed: float = 3.0
@export var impulse_max_speed: float = 75.0
@export var jump_force: float = 50.0
@export var jump_speed_boost: float = 5
@export var max_speed: float = 20.0
@export var p_cam_sensitivity: float = 0.003
@export var speed: float = 1.5
@export var gravity: float = 0.98

var is_good: bool = true
var is_alive: bool = true
var color: Color

var health: float = 100:
	get():
		return health
	set(val):
		if val < 0:
			rpc("_trigger_defeat")
		health = val

var _last_player_hurt_sound: AudioStream = null
var _up: bool = Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W)
var _down: bool = Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S)
var _right: bool = Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)
var _left: bool = Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)
var _movement: Vector3 = Vector3.ZERO

@onready var voice_pitch := randf_range(0.92, 1.03)
@onready var audio_player: AudioStreamPlayer3D = $Head/AudioStreamPlayer3D
@onready var bubble_blowing_player: AudioStreamPlayer3D = $Head/BubbleBlowingAudioPlayer
@onready var body_mesh: Node = $Body
@onready var head_node: Node = $Head
@onready var head_mesh: Node = $Head/HeadMesh
@onready var spring_arm: SpringArm3D = $Head/SpringArm3D
@onready var p_cam: Camera3D = $Head/SpringArm3D/PlayerCamera
@onready var bubble_cast: ShapeCast3D = $BubbleCast

@rpc("any_peer", "call_local", "reliable")
func trigger_respawn() -> void:
	collision_layer = 1
	collision_mask = 1

	var tween: Tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector3.ONE, 1)
	tween.tween_callback(func() -> void:
		audio_player.stop()
	)

	is_alive = true
	audio_player.stream = preload("res://Assets/SoundEffects/respawn.wav")
	audio_player.play()


@rpc("any_peer", "call_local", "reliable")
func _trigger_defeat() -> void:
	collision_layer = 2
	collision_mask = 2

	var tween: Tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "scale", Vector3.ONE * 0.01, 1)
	is_alive = false

	_up = false
	_down = false
	_left = false
	_right = false

	pushback_pos(position - p_cam.basis.z * 2)

	var resp_cam: Camera3D = get_tree().current_scene.find_child("RespawnCamera")
	if resp_cam:
		p_cam.top_level = true
		var tween_2: Tween = get_tree().create_tween()
		tween_2.set_ease(Tween.EASE_IN_OUT)
		tween_2.set_trans(Tween.TRANS_BACK)
		tween_2.tween_property(p_cam, "global_transform", resp_cam.global_transform, 1.5)
	SignalBus.player_defeat.emit(self)


func get_all_children(in_node: Node3D, arr: Array[Node3D]) -> Array[Node3D]:
	arr.push_back(in_node)
	for child in in_node.get_children():
		arr = get_all_children(child, arr)
	return arr


func _ready() -> void:
	name = str(get_multiplayer_authority())
	p_cam.current = is_multiplayer_authority()

	if is_multiplayer_authority():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	for c: Node3D in get_all_children(self, []).filter(
		func(n: Node3D) -> bool: return n is MeshInstance3D
	):
		var new_material: StandardMaterial3D = StandardMaterial3D.new()
		new_material.albedo_color = color
		c.material_override = new_material


func _calculate_horizontal_movement() -> void:
	_movement = Vector3.ZERO

	if _up and not _down:
		_movement += Vector3.FORWARD * speed
	if _down and not _up:
		_movement += Vector3.BACK * speed
	if _right and not _left:
		_movement += Vector3.RIGHT * speed
	if _left and not _right:
		_movement += Vector3.LEFT * speed

	if _movement.z < 0:
		body_mesh.rotate_y(angle_difference(body_mesh.rotation.y, head_node.rotation.y) / 10.0)
	if _movement.x:
		var body_head_diff: float = angle_difference(
			body_mesh.rotation.y + sign(_movement.x) * DEG_45, head_node.rotation.y
		)
		body_mesh.rotate_y(body_head_diff / 10.0)

	# If velocity is over 3 times the max in the XZ axys, just lock it to that
	if XZ.xz_length(velocity) > impulse_max_speed:
		velocity = XZ.normalize_xz(velocity, impulse_max_speed)
		# TODO: Add a little bit of strafing here
		return

	# First we check to see if we're over the limit in the XZ axys without doing any movement
	# if we are, deccelerate at a custom pace, and do nothing more
	if round(XZ.xz_length(velocity)) > max_speed or not is_alive:
		velocity = XZ.move_toward_xz(velocity, Vector3.ZERO, decel_speed / 4)
		return

	velocity += _movement.rotated(Vector3.UP, head_node.rotation.y)
	if XZ.xz_length(velocity) > max_speed:
		velocity = XZ.normalize_xz(velocity, max_speed)

	if (
		is_on_floor() and (not (_up or _down or _left or _right))
		or ((_up and _down) or (_right and _left))
	):
		velocity = XZ.move_toward_xz(velocity, Vector3.ZERO, decel_speed)


func pushback_pos(pos: Vector3) -> void:
	velocity.x = -(pos.x - move_toward(position.x, pos.x, 1)) * max_speed
	velocity.z = -(pos.z - move_toward(position.z, pos.z, 1)) * max_speed


@rpc("any_peer", "reliable", "call_local")
func pushback(node: Node3D) -> void:
	velocity.x = -(node.position.x - move_toward(position.x, node.position.x, 1)) * max_speed
	velocity.z = -(node.position.z - move_toward(position.z, node.position.z, 1)) * max_speed

	var to_play: AudioStream = _last_player_hurt_sound
	while to_play == _last_player_hurt_sound:
		to_play = HURT_SOUNDS.pick_random()
	audio_player.stream = to_play
	audio_player.play()
	audio_player.pitch_scale = voice_pitch
	_last_player_hurt_sound = to_play
	if node.is_good != is_good:
		health -= 33.33


@rpc("any_peer", "reliable", "call_local")
func stomp() -> void:
	# If not pressing anything, halt and bounce up
	if not (_up or _down or _left or _right):
		velocity = Vector3(0, jump_force * 1.5, 0)
		move_and_slide()
		force_update_transform()
		return
	velocity *= jump_speed_boost
	velocity.y = jump_force


func _check_for_bubbles() -> void:
	var col: KinematicCollision3D = get_last_slide_collision()
	if col == null:
		return
	for c in col.get_collision_count():
		var collider: Node3D = col.get_collider(c)
		if collider == null:
			return
		if not collider.is_in_group("Bubble"):
			return
		if col.get_normal(c).y != 0:
			stomp()
		else:
			pushback(collider)
		if not collider.is_in_group("BossBubble"):
			collider.rpc("burst")


@rpc("any_peer", "call_local", "reliable")
func _net_jump() -> void:
	if not JUMP_SOUNDS.has(audio_player.stream) and audio_player.playing:
		return
	audio_player.stream = JUMP_SOUNDS.pick_random()
	audio_player.max_db = 1
	audio_player.play(0.1)
	audio_player.pitch_scale = voice_pitch + randf_range(-0.03, 0.01)


func _jump() -> void:
	velocity.y += jump_force
	rpc("_net_jump")


func _process(_delta: float) -> void:
	if not is_alive:
		p_cam.top_level = true
		var resp_cam: Camera3D = get_tree().current_scene.find_child("RespawnCamera")
		if resp_cam:
			p_cam.global_position = resp_cam.position
			p_cam.global_rotation = resp_cam.rotation

	if not is_multiplayer_authority() or not is_alive:
		return

	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y -= gravity

	if is_on_floor() and Input.is_key_pressed(KEY_SPACE):
		_jump()

	_calculate_horizontal_movement()
	# _check_for_bubbles()
	move_and_slide()
	if XZ.xz_length(velocity):
		p_cam.fov = clamp(p_cam.fov + _delta * 100, 75, 100)
	else:
		p_cam.fov = clamp(p_cam.fov - _delta * 100, 75, 100)

	if global_position.y < -10 and is_alive:
		rpc("_trigger_defeat")
		return

	rpc("remote_set_position", global_position)
	rpc("remote_set_head_rotation", head_node.rotation, spring_arm.rotation, velocity)


@rpc("any_peer", "unreliable")
func remote_set_position(real_pos: Vector3) -> void:
	global_position = real_pos


@rpc("any_peer", "call_local", "reliable")
func _net_shoot_bubble() -> void:
	bubble_blowing_player.stream = preload("res://Assets/SoundEffects/shooting_bubble.wav")
	bubble_blowing_player.play(0.14)
	bubble_blowing_player.pitch_scale = randf_range(0.95, 1.05)
	_shoot_bubble()


@rpc("any_peer", "unreliable")
func remote_set_head_rotation(
	real_rotation: Vector3, real_spring_rotation: Vector3, real_velocity: Vector3
) -> void:
	velocity = real_velocity
	head_node.rotation = real_rotation
	head_mesh.rotation = real_rotation
	spring_arm.rotation = real_spring_rotation


func _process_keyboard(ev: InputEventKey) -> void:
	match ev.keycode:
		KEY_W, KEY_UP:
			_up = ev.pressed
		KEY_A, KEY_LEFT:
			_left = ev.pressed
		KEY_S, KEY_DOWN:
			_down = ev.pressed
		KEY_D, KEY_RIGHT:
			_right = ev.pressed
		KEY_C:
			if ev.is_released():
				return
			SignalBus.player_change_team.emit(multiplayer.get_unique_id())


func _process_mouse_motion(ev: InputEventMouseMotion) -> void:
	if not is_alive:
		return
	var move_x: float = ev.relative.x
	var move_y: float = ev.relative.y
	var head_body_diff: float

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	head_node.rotate_y(-move_x * p_cam_sensitivity)
	spring_arm.rotate_x(-move_y * p_cam_sensitivity)
	spring_arm.rotation.x = clamp(spring_arm.rotation.x, -1, 1.5)
	head_mesh.rotation.x = spring_arm.rotation.x

	head_body_diff = angle_difference(head_node.rotation.y, body_mesh.rotation.y)
	if abs(head_body_diff) > .7:
		body_mesh.rotate_y(sign(head_body_diff) * (-abs(head_body_diff) + .7))


func _shoot_bubble() -> void:
	var arr: Array = bubble_cast.collision_result
	for x: Dictionary in arr:
		var obj: Node3D = x["collider"]
		if obj.is_in_group("Terrain"):
			return

	var bubble: Node3D = (BUBBLE_GOOD if is_good else BUBBLE_BAD).instantiate()

	bubble.position = bubble_cast.global_position - (p_cam.global_basis.z * 2)
	bubble.direction = (-p_cam.global_basis.z)
	bubble.scale = Vector3.ONE * 0.01
	var mesh: MeshInstance3D = bubble.find_child("BubbleGood" if is_good else "BubbleBad")
	var new_mat: StandardMaterial3D = (
		load("res://Materials/bubble_material_good.tres")
		if is_good
		else load("res://Materials/bubble_material_bad.tres")
	)
	new_mat.albedo_color = color * 3
	mesh.material_override = new_mat

	var dot: float = bubble.direction.normalized().dot(velocity.normalized())
	if dot > .5 or dot < -.5:
		bubble.speed *= 1 + bubble.direction.normalized().dot(velocity.normalized()) / 2
	if velocity.y != 0:
		bubble.speed *= 1 + abs(velocity.normalized().y)
	bubble.set_multiplayer_authority(1)
	get_tree().get_current_scene().add_child(bubble)


func _process_mouse_button(ev: InputEventMouseButton) -> void:
	if ev.pressed && ev.button_index == MOUSE_BUTTON_LEFT:
		rpc("_net_shoot_bubble")


func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if not is_alive:
		return
	if event is InputEventKey:
		_process_keyboard(event)
	if event is InputEventMouseMotion:
		_process_mouse_motion(event)
	if event is InputEventMouseButton:
		_process_mouse_button(event)

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		toggle_mouse_capture()


func toggle_mouse_capture() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
