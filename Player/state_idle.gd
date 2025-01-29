extends State


func on_set() -> void:
	pass


func on_leave() -> void:
	pass


func update() -> void:
	pass


func physics_update() -> void:
	pass  # TODO: Add gravity lmao


func input(_event: InputEvent) -> void:
	if _event is InputEventKey:
		match _event.keycode:
			KEY_W, KEY_A, KEY_S, KEY_D:
				transition.emit(self, "running")
