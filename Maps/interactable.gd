extends Node3D

enum INTERACTIONS {
	NULL = 0,
	CREATE_SERVER = 1,
	CLOSE_SERVER = 2,
	JOIN_SERVER = 3
}

var is_focused: bool = false:
	get():
		return is_focused
	set(val):
		is_focused = val
		if val: _on_focus()
		else: _on_focus_lost()

@export var _interaction: INTERACTIONS
@export  var _lobby_controller :LobbyController

@onready var INTERACTIONS_ARRAY := [
	func() -> void: print("Empty interaction!"),
	_lobby_controller.create_server,
	_lobby_controller.close_server,
	_lobby_controller.join_server
]

@onready var _interaction_info_tween: Tween = null
@onready var _interaction_info: Sprite3D = $InteractableInformation
@onready var _interaction_area: Area3D = $InteractableArea

func _on_focus() -> void:
	_interaction_info.visible = true
	_interaction_info_tween.kill()
	_interaction_info_tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_interaction_info_tween.tween_property(_interaction_info, "scale", Vector3.ONE, 0.33)

func _on_focus_lost() -> void:
	_interaction_info_tween = get_tree().create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	_interaction_info_tween.tween_property(_interaction_info, "scale", Vector3.ONE * 0.01, 0.33)
	_interaction_info_tween.tween_callback(func() -> void:
		_interaction_info.visible = false
	)

func interact() -> void:
	INTERACTIONS_ARRAY[_interaction].call()

func _ready() -> void:
	assert(_interaction, "Interaction not set!")
	assert(_lobby_controller, "Lobby Controller not set!")
	_interaction_area.add_to_group("Interactable")
	_on_focus_lost()
