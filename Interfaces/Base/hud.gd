class_name Hud extends Node

signal transition(_old_state: Hud, _state: Hud)


func on_set() -> void:
	KLog.warning("Function on_set not implemented")
	print_stack()


func on_leave() -> void:
	KLog.warning("Function on_leave not implemented")
	print_stack()


func update() -> void:
	KLog.warning("Function update not implemented")
	print_stack()


func physics_update() -> void:
	KLog.warning("Function physics_update not implemented")
	print_stack()
