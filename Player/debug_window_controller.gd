extends Control

@export var window_title: String

@export var content_scene: PackedScene

@onready var window_title_label: Label = $Order/Controlers/WindowTitle

@onready var drag: Button = $Order/Controlers/Drag

@onready var toggle: Button = $Order/Controlers/Toggle

var content: Control

var dragging: bool = false

var offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	assert(content_scene, "No content scene set for window")
	content = content_scene.instantiate()
	$Order.add_child(content)
	
	window_title_label.text = window_title
	toggle.text = "-" if content.visible else "+"
	toggle.pressed.connect(func() -> void:
		content.visible = !content.visible
		toggle.text = "-" if content.visible else "+"
		size = (Vector2.RIGHT * 500) if content.visible else Vector2.ZERO
	)
	drag.button_down.connect(func() -> void:
		dragging = true
		offset = position - get_viewport().get_mouse_position()
	)
	drag.button_up.connect(func() -> void: dragging = false )

func _process(_delta: float) -> void:
	if dragging:
		position = offset + get_viewport().get_mouse_position()
