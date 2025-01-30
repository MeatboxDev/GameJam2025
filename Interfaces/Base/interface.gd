class_name Interface extends Node

signal kill(interface: Interface)
signal transition(old: Interface, new_name: String)

func open() -> void:
	assert(false, "Not implemented open")

func close() -> void:
	assert(false, "Not implemented close")

func show() -> void:
	assert(false, "Not implemented show")

func hide() -> void:
	assert(false, "Not implemented hide")
