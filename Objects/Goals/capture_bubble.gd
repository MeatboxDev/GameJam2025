extends Area3D

# Edit these values to change how the bubble grows and dies
const MAX_SCALE := Vector3.ONE * 5
const HP := 30
var _hp := HP

func _handle_body_entered(body: Node3D) -> void:
	KLog.debug("Groups " + str(body.get_groups()))
	if body.is_in_group("Bubble"):
		body.get_parent().burst()
		_inflate()
		if _can_burst():
			_burst()
			SignalBus.point_for_team.emit(body.get_parent().team)
	elif body.is_in_group("Player"):
		KLog.debug("Get out of here player!!")


func _inflate() -> void:
	scale += MAX_SCALE / HP
	_hp -= 1


func _can_burst() -> bool:
	return _hp <= 0


func _burst() -> void:
	self.queue_free()
	SignalBus.capture_bubble_burst.emit()

func _ready() -> void:
	area_entered.connect(_handle_body_entered)
