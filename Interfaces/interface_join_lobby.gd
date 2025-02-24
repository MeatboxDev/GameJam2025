extends Interface

@export var _bubbly_server: Bubbly
@export var _lobby_controller: Node

@onready var _control_node: Control = $JoinInterface
@onready var _join_button: Button = $JoinInterface/MenuLabelContainer/JoinContainer/JoinButton
@onready var _close_button: Button = $JoinInterface/MenuLabelContainer/JoinContainer/CloseButton
@onready var _join_ip_edit: TextEdit = $JoinInterface/MenuLabelContainer/JoinContainer/InputContainer/JoinIp
@onready var _join_port_edit: TextEdit = $JoinInterface/MenuLabelContainer/JoinContainer/InputContainer/JoinPort
@onready var _feedback_label: Label = $JoinInterface/MenuLabelContainer/Feedback

func open() -> void:
	_control_node.visible = true
	_feedback_label.visible = false
	_join_ip_edit.grab_focus()

func close() -> void:
	_control_node.visible = false
	_join_ip_edit.clear()
	_join_port_edit.clear()

func show() -> void:
	pass

func hide() -> void:
	pass

func _on_close_pressed() -> void:
	kill.emit(self)

func _join_button_pressed() -> void:
	var ip: String = (_bubbly_server.IP_ADDRESS if _join_ip_edit.text == "" else _join_ip_edit.text)
	var port: int = _bubbly_server.PORT if _join_port_edit.text == "" else (_join_port_edit.text).to_int()
	_feedback_label.visible = true
	_feedback_label.text = "Connecting to " + ip + ":" + str(port)
	var err := _bubbly_server.connect_to_server(ip, port)
	if err != OK:
		_feedback_label.visible = true
		_feedback_label.text = "Insert a valid IP address!"
		get_tree().create_timer(3.0).timeout.connect(func() -> void:
			_feedback_label.visible = false
		)
		return
	
	_join_button.pressed.disconnect(_join_button_pressed)
	_close_button.pressed.disconnect(_on_close_pressed)
	var res: bool = await _bubbly_server.connection_result
	_close_button.pressed.connect(_on_close_pressed)
	_join_button.pressed.connect(_join_button_pressed)
	
	if res:
		_lobby_controller.clear_players()
		kill.emit(self)
	else:
		_feedback_label.visible = true
		_feedback_label.text = "Connection failed!"
		get_tree().create_timer(3.0).timeout.connect(func() -> void:
			_feedback_label.visible = false
		)

func _ready() -> void:
	assert(_bubbly_server, "Bubbly server not found!")
	assert(_lobby_controller, "Lobby controller not found!")
	
	_join_button.pressed.connect(_join_button_pressed)
	_close_button.pressed.connect(_on_close_pressed)
