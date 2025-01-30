class_name InterfaceManager extends Node

var _interfaces := {}
var open_interfaces: Array[Interface]

func _ready() -> void:
	for interface: Interface in get_children().filter(func(c: Node) -> bool: return c is Interface):
		_interfaces[interface.name.to_lower()] = interface
		interface.transition.connect(_on_interface_transition)
		interface.kill.connect(_on_interface_close)


func _on_interface_close(interface: Interface) -> void:
	interface.close()
	open_interfaces.erase(interface)
	if open_interfaces.size() != 0:
		open_interfaces.back().open()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_interface_transition(old: Interface, new_name: String) -> void:
	if open_interfaces.size() != 0 and old != open_interfaces.back():
		return
	open(name)


func open(name: String) -> void:
	var new_interface: Interface = _interfaces[name.to_lower()]
	if !new_interface:
		breakpoint
		return
	
	if open_interfaces.size() != 0:
		open_interfaces.back().hide()

	open_interfaces.push_back(new_interface)
	new_interface.open()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
