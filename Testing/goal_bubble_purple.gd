extends StaticBody3D

const MAX_SIZE: float = 1.5

@export var is_good: bool = false

@onready var explosion_area: ShapeCast3D = $Explosion
@onready var explosion_stream: AudioStreamPlayer3D = $ExplosionPlayer
@onready var area: Area3D = $Area


func _trigger_boss_burst() -> void:
	var arr: Array = explosion_area.collision_result
	for x: Dictionary in arr:
		var obj: Node3D = x["collider"]
		if obj == null:
			continue
		if not obj.is_in_group("Player"):
			continue
		obj.velocity = -(position - position.move_toward(obj.position, 1)) * 30
		obj.velocity.y = abs(obj.velocity.y)
		obj.move_and_slide()
	if is_good:
		SignalBus.burst_good_boss.emit()
	else:
		SignalBus.burst_bad_boss.emit()

	var stream := explosion_stream
	stream.stream = preload("res://Assets/SoundEffects/shooting_bubble.wav")
	stream.play(0.13)
	stream.pitch_scale = 1
	remove_child(stream)
	get_tree().get_current_scene().add_child(stream)
	get_tree().create_timer(stream.stream.get_length()).timeout.connect(stream.queue_free)

	self.queue_free()


@rpc("any_peer", "call_local", "reliable")
func _net_boss_grow() -> void:
	self.scale += Vector3.ONE * 0.1
	position.y += 0.025 * self.scale.y
	if self.scale.x > MAX_SIZE:
		_trigger_boss_burst()


func _handle_enter(_area: Node3D) -> void:
	if not _area.is_in_group("Bubble"):
		return
	var par: Node3D = _area.get_parent()
	if par == null:
		return
	if par.is_good == is_good:
		par.rpc("burst")
		return
	par.rpc("burst")
	rpc("_net_boss_grow")


func _ready() -> void:
	scale = Vector3.ONE * 0.5
	if not is_multiplayer_authority():
		return
	if is_good:
		SignalBus.place_good_boss.emit()
	else:
		SignalBus.place_bad_boss.emit()
	area.connect("area_entered", _handle_enter)
