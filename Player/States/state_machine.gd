class_name StateMachine extends Node

@export var _initial_state: State

var current_state: State
var _states := {}

func _on_interface_open() -> void:
	current_state.transition.emit(current_state, "Interface")


func _on_interface_close() -> void:
	current_state.transition.emit(current_state, "Idle")


func _ready() -> void:
	SignalBus.interface_open.connect(_on_interface_open)
	SignalBus.interface_closed.connect(_on_interface_close)
	
	for state: State in get_children().filter(func(c: Node) -> bool: return c is State):
		_states[state.name.to_lower()] = state
		state.transition.connect(_on_state_transition)

	if _initial_state:
		current_state = _initial_state


func _process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if not current_state:
		return
	current_state.update()


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if not current_state:
		return
	current_state.physics_update()


func _on_state_transition(
	old_state: State,
	new_state_name: String,
) -> void:
	if old_state != current_state:
		return

	var new_state: State = _states[new_state_name.to_lower()]
	if !new_state:
		breakpoint
		return

	if current_state:
		current_state.on_leave()

	current_state = new_state
	new_state.on_set()
	KLog.debug("Player transitioned state to " + new_state_name)


func _input(event: InputEvent) -> void:
	if current_state:
		current_state.input(event)
