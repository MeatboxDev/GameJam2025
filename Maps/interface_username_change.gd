extends Interface

@onready var _control_node: Control = $NameInterface
@onready var _confirm_button: Button = $NameInterface/NameContainer/ConfirmButton
@onready var _close_button: Button = $NameInterface/NameContainer/CloseButton
@onready var _username_input: TextEdit = $NameInterface/NameContainer/UserInput

func open() -> void:
	print("Changing username...")
	_control_node.visible = true

func close() -> void:
	_control_node.visible = false

func show() -> void:
	pass

func hide() -> void:
	pass

func _ready() -> void:
	_confirm_button.pressed.connect(func() -> void:
		var config := ConfigFile.new()
		var username := _username_input.text
		config.set_value("Userdata", "username", username)
		config.save("user://userdata.cfg")
		
		kill.emit(self)
		
		# TODO: Username change signal possibly
	)
	
	_close_button.pressed.connect(func() -> void: kill.emit(self))
