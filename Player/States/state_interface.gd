extends State

func on_set() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func on_leave() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func update() -> void:
	pass

func physics_update() -> void:
	pass

func input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		transition.emit(self, "Idle")
