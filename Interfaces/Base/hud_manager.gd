class_name HudManager extends Node

@export var _initial_hud: Hud

var current_hud: Hud
var _huds := {}


func _ready() -> void:
	for hud: Hud in get_children().filter(func(c: Node) -> bool: return c is Hud):
		_huds[hud.name.to_lower()] = hud
		hud.transition.connect(_on_hud_transition)

	if _initial_hud:
		current_hud = _initial_hud


func _process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if not current_hud:
		return
	current_hud.update()


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if not current_hud:
		return
	current_hud.physics_update()


func _on_hud_transition(
	old_hud: Hud,
	new_hud_name: String,
) -> void:
	if old_hud != current_hud:
		return

	var new_hud: Hud = _huds[new_hud_name.to_lower()]
	if !new_hud:
		breakpoint
		return

	if current_hud:
		current_hud.on_leave()

	current_hud = new_hud
	new_hud.on_set()


func _input(event: InputEvent) -> void:
	if current_hud:
		current_hud.input(event)
