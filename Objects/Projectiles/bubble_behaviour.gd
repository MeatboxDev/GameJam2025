extends StaticBody3D

var team: int = -1
var speed := 0.0
var direction := Vector3.ZERO
var decceleration := 0.05
var number := 0

@onready var _escape_area: Area3D = $EscapeArea

func _on_player_exit(body: Node3D) -> void:
	if not body.is_in_group("Player"):
		return
	rpc("_make_solid")


func _ready() -> void:
	if not is_multiplayer_authority():
		return
	_escape_area.body_exited.connect(_on_player_exit)
	get_tree().create_timer(0.05).timeout.connect(func() -> void: 
		rpc("_make_solid")
	)


func _process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
		
	speed = move_toward(speed, 0, decceleration)
	var col := move_and_collide(direction * speed, false, -32, false, 32)
	
	if col and speed:
		for i: int in col.get_collision_count():
			var collider := col.get_collider(i)
			if collider.is_in_group("Bubble"):
				speed /= 2.0
				collider.speed = speed
				collider.direction = direction
				direction *= -1
			elif collider.is_in_group("Player"):
				pass # I hate this singular line of code, fuck this
			else:
				var norm := col.get_normal(i)
				if norm.x: 
					direction.x *= -1
				if norm.y: 
					direction.y *= -1
				if norm.z: 
					direction.z *= -1


@rpc("any_peer", "reliable", "call_local")
func burst() -> void:
	SignalBus.burst_bubble.emit(number)


@rpc("authority", "reliable", "call_local")
func _make_solid() -> void:
	collision_layer = 2 | 4
	collision_mask = 2 | 4
	$BubbleMesh.material_override = StandardMaterial3D.new()
	$BubbleMesh.material_override.albedo_color = Color.RED
