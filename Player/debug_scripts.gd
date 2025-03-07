extends Control

@onready var vars_container: VBoxContainer = $Variables

var player_object: Node:
	get(): return player_object
	set(val):
		player_object = val
		_get_variables_from_object()

var vars: Dictionary[StringName, Dictionary] = {
	"max_speed": {"min": 0.0, "max": 100.0},
	"gravity": {"min": 0.0, "max": 5.0},
	"jump_force": {"min": 0.0, "max": 100.0},
	"jump_duration": {"min": 0.0, "max": 1.0},
	"deceleration": {"min": 0.0, "max": 10.0},
	"acceleration": {"min": 0.0, "max": 10.0},
}

func _handle_slider_change(val: Variant, l: Label, v: StringName) -> void:
	l.text = v + ": " + str((round(val * 100) / 100) if val is float else val)
	player_object.set(v, val)

func _get_variables_from_object() -> void:
	for v: StringName in vars:
		var box: HBoxContainer = HBoxContainer.new()
		var l: Label = Label.new()
		var slider: HSlider = HSlider.new()
		var value: Variant = player_object.get(v)
		l.text = v + ": " + str(value)
		slider.min_value = vars[v]["min"]
		slider.value = player_object.get(v)
		slider.max_value = vars[v]["max"]
		slider.step = (slider.max_value - slider.max_value) / 25.0
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.value_changed.connect(_handle_slider_change.bind(l, v))
		box.add_child(l)
		box.add_child(slider)
		vars_container.add_child(box)


func _ready() -> void:
	SignalBus.current_player_change.connect(func(pl: Player) -> void: player_object = pl)
