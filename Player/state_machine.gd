class_name StateMachine extends Node

@export var _initial_state: State

var _current_state: State
var _states := {}


func _ready() -> void:
	for state: State in get_children().filter(func(c: Node) -> bool: return c is State):
		_states[state.name.to_lower()] = state
		state.transition.connect(_on_state_transition)

	if _initial_state:
		_current_state = _initial_state


func _process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if not _current_state:
		return
	_current_state.update()


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if not _current_state:
		return
	_current_state.physics_update()


func _on_state_transition(
	old_state: State,
	new_state_name: String,
) -> void:
	if old_state != _current_state:
		return

	var new_state: State = _states[new_state_name.to_lower()]
	if !new_state:
		breakpoint
		return

	if _current_state:
		_current_state.on_leave()

	print("Transitioned to " + new_state.name)
	_current_state = new_state
	new_state.on_set()


func _input(event: InputEvent) -> void:
	if _current_state:
		_current_state.input(event)
