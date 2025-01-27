extends Node

@export var spawn_points: Array[Node3D]

@onready var _lobby_interface: Control = $LobbyInterface


func _ready() -> void:
#	assert(spawn_points.size() > 0, "You need to specify at least one spawn point")
	assert(_lobby_interface, "Lobby interface is missing")
