extends CharacterBody3D

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

var _up: bool = Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W)
var _down: bool = Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S)
var _right: bool = Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)
var _left: bool = Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)
var _movement: Vector3 = Vector3.ZERO

@onready var stomp_area: Area3D = $StompArea
@onready var push_area: Area3D = $PushArea
@onready var body_mesh: Node = $Body
@onready var head_node: Node = $Head
@onready var head_mesh: Node = $Head/HeadMesh
@onready var spring_arm: SpringArm3D = $Head/SpringArm3D
@onready var p_cam: Camera3D = $Head/SpringArm3D/PlayerCamera
@onready var bubble_cast: ShapeCast3D = $BubbleCast


func _ready() -> void:
	name = str(get_multiplayer_authority())
	p_cam.current = is_multiplayer_authority()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	for c: Node3D in $Model.get_children():
		for mesh: MeshInstance3D in c.get_children():
			var new_material: StandardMaterial3D = StandardMaterial3D.new()
			new_material.albedo_color = "0000ff" if is_good else "ff0000"
			mesh.material_override = new_material


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
	if round(XZ.xz_length(velocity)) > max_speed:
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


func _pushback(node: Node3D) -> void:
	if not node.is_in_group("BossBubble"):
		node.burst()
	velocity.x = -(node.position.x - move_toward(position.x, node.position.x, 1)) * max_speed
	velocity.z = -(node.position.z - move_toward(position.z, node.position.z, 1)) * max_speed


func _stomp(node: Node3D) -> void:
	if not node.is_in_group("BossBubble"):
		node.burst()

	# If not pressing anything, halt and bounce up
	if not (_up or _down or _left or _right):
		velocity = Vector3(0, jump_force * 1.5, 0)
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
		var norm: Vector3 = col.get_normal(c)
		if norm.y != 0:
			return _stomp(collider)
		return _pushback(collider)


func _process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return

	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y -= gravity

	if is_on_floor() and Input.is_key_pressed(KEY_SPACE):
		velocity.y += jump_force

	_calculate_horizontal_movement()
	_check_for_bubbles()
	move_and_slide()

	rpc("remote_set_position", global_position)
	rpc("remote_set_head_rotation", head_node.rotation, spring_arm.rotation, velocity)


@rpc("unreliable")
func remote_set_position(real_pos: Vector3) -> void:
	global_position = real_pos


@rpc("unreliable")
func remote_set_head_rotation(
	real_rotation: Vector3, real_spring_rotation: Vector3, real_velocity: Vector3
) -> void:
	velocity = real_velocity
	head_node.rotation = real_rotation
	head_mesh.rotation = real_rotation
	spring_arm.rotation = real_spring_rotation


@rpc("any_peer", "reliable")
func _net_shoot_bubble() -> void:
	_shoot_bubble()


func toggle_mouse_capture() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


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

	if ev.pressed:
		match ev.keycode:
			KEY_ESCAPE:
				toggle_mouse_capture()


func _process_mouse_motion(ev: InputEventMouseMotion) -> void:
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
	var bubble: Node3D = (BUBBLE_GOOD if is_good else BUBBLE_BAD).instantiate()
	get_tree().get_root().add_child(bubble)

	bubble_cast.position = head_node.position + (-p_cam.global_basis.z) * 3
	bubble_cast.force_update_transform()
	bubble_cast.force_shapecast_update()
	var arr: Array = bubble_cast.collision_result
	for x: Dictionary in arr:
		var obj: Node3D = x["collider"]
		if not obj.is_in_group("Terrain"):
			continue
		bubble.queue_free()
		return

	bubble.position = position + bubble_cast.position
	bubble.direction = (-p_cam.global_basis.z)
	bubble.scale = Vector3.ONE * 0.01
	bubble.speed += (bubble.direction.normalized().dot(velocity.normalized())) / 2
	bubble.set_multiplayer_authority(get_multiplayer_authority())


func _process_mouse_button(ev: InputEventMouseButton) -> void:
	if ev.pressed && ev.button_index == MOUSE_BUTTON_LEFT:
		rpc("_net_shoot_bubble")
		_shoot_bubble()


func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event is InputEventKey:
		_process_keyboard(event)
	if event is InputEventMouseMotion:
		_process_mouse_motion(event)
	if event is InputEventMouseButton:
		_process_mouse_button(event)
