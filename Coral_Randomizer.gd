extends StaticBody3D
var _corals : Array [Node3D] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_corals.append($coral_01)
	_corals.append($coral_02)
	_corals.append($coral_03)
	
	_corals.pick_random().show()
	
	
	pass # Replace with function body.
