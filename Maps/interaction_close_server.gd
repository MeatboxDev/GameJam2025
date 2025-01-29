class_name Interaction extends Node

@export var _lobby_controller: LobbyController

func _ready() -> void:
	assert(_lobby_controller, "Lobby Controller not set")

func interact() -> void:
	_lobby_controller.create_server()
