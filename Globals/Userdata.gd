extends Node

@onready var config: ConfigFile = ConfigFile.new()

func _ready() -> void:
	config.load("user://userdata.cfg")
