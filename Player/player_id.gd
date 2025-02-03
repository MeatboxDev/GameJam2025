extends Sprite3D

@export var _node: Node
@export var _signal: StringName

@onready var _label: Label = $Viewport/Label

func _on_signal(msg: String) -> void:
	_label.text = msg


func _ready() -> void:
	assert(_node, "If you're not setting a node, why am I here?")
	assert(_label, "If you're not setting a label, how are we displaying the information?")
	_node.connect(_signal, _on_signal)
