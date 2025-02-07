extends Interface

@onready var _join_good_btn: Button = $Control/HBoxContainer/JoinGood
@onready var _join_bad_btn: Button = $Control/HBoxContainer/JoinBad

func _on_join_good_pressed() -> void:
	SignalBus.change_team_good.emit(multiplayer.get_unique_id())
	kill.emit(self)

func _on_join_bad_pressed() -> void:
	SignalBus.change_team_bad.emit(multiplayer.get_unique_id())
	kill.emit(self)

func _ready() -> void:
	_join_good_btn.pressed.connect(_on_join_good_pressed)
	_join_bad_btn.pressed.connect(_on_join_bad_pressed)

func open() -> void:
	$Control.visible = true

func close() -> void:
	$Control.visible = false

func show() -> void:
	pass

func hide() -> void:
	pass
