extends Area3D

var interactables: Array[Node3D] = []


func _on_area_entered(area: Area3D) -> void:
	if not area.is_in_group("Interactable"): return
	interactables.append(area.get_parent())
	
	
func _on_area_exited(area: Area3D) -> void:
	if not area.is_in_group("Interactable"): return
	area.get_parent().is_focused = false
	interactables.erase(area.get_parent())


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	interactables.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return a.position.distance_to(position) < b.position.distance_to(position)
	)
	if interactables.size() > 0:
		for i in interactables:
			i.is_focused = false
		interactables.front().is_focused = true

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_E and event.pressed and interactables.size() > 0:
		interactables.front().interact()
