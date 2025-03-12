class_name CaptureBubble extends Area3D

# Edit these values to change how the bubble grows and dies
const MAX_SCALE := Vector3.ONE * 5

const HP := 30

var _hp := HP

## [b][color=red]Server Function[/color][/b]
## Bursts the [Bubble] that entered the capture [Bubble]
## Inflates the [CaptureBubble]
## If [member CaptureBubble._hp] below zero burst this bubble and give the Bubble's team a point 
func _handle_bubble_enter(bubble: Bubble) -> void:
	assert(Server.is_server(), "_handle_bubble_enter running on client not allowed")
	bubble.rpc("burst")
	rpc("_inflate")
	if _hp <= 0:
		SignalBus.point_for_team.emit(bubble.team)
		_burst()


## [b][color=red]Server Function[/color][/b]
func _handle_body_entered(body: Node3D) -> void:
	assert(Server.is_server(), "_handle_body_entered running on client not allowed")
	if body.is_in_group("Bubble"):
		_handle_bubble_enter(body.get_parent())


@rpc("authority", "call_local", "reliable")
func _inflate() -> void:
	scale += MAX_SCALE / HP
	_hp -= 1


@rpc("authority", "call_local", "reliable")
func _rpc_burst() -> void:
	self.queue_free()


func _burst() -> void:
	assert(Server.is_server(), "_handle_bubble_enter running on client not allowed")
	rpc("_rpc_burst")
	SignalBus.capture_bubble_burst.emit()


func _ready() -> void:
	if not is_multiplayer_authority(): return
	area_entered.connect(_handle_body_entered)
