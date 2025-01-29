extends Node

var chatter: CharacterBody3D

@onready var chat : VBoxContainer = $ChatBox/Chat
@onready var input_box: TextEdit = $ChatBox/InputBox


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ENTER and event.pressed:
		if input_box.has_focus() and input_box.text == "":
			input_box.release_focus()
			return
		if input_box.has_focus():
			var text := input_box.text.replace("\n", "")
			rpc("_add_chat_msg", input_box.text)
			input_box.clear()
			input_box.release_focus()
		else:
			input_box.grab_focus()
			get_viewport().set_input_as_handled()


@rpc("any_peer", "reliable", "call_local")
func _add_chat_msg(msg: String) -> void:
	var chat_msg := Label.new()
	chat_msg.text = msg
	chat.add_child(chat_msg)
