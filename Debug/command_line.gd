extends Node

@onready var output: Label = $Output

@onready var input: LineEdit = $Input

var command_dictionary: Dictionary[String, Callable] = {
	"connect": _connect,
	"disconnect": _disconnect,
	"host": _host,
	"print_player_instances": _print_player_instances,
}


func _connect(arguments: Array[String]) -> void:
	var ip: String = arguments[0] if arguments.size() > 0 else "127.0.0.1"
	var port: String = arguments[1] if arguments.size() > 1 else "12354"
	SignalBus.connect_to_server.emit(ip, port)


func _disconnect(_arguments: Array[String]) -> void:
	SignalBus.disconnect_from_server.emit()


func _host(arguments: Array[String]) -> void:
	var ip: String = arguments[0] if arguments.size() > 0 else "127.0.0.1"
	var port: String = arguments[1] if arguments.size() > 1 else "12354"
	SignalBus.create_server.emit(ip, port)


func _print_player_instances(_arguments: Array[String]) -> void:
	SignalBus.print_player_instances.emit()


func _input_command(command: String, arguments: Array[String]) -> void:
	assert(command_dictionary[(command.strip_edges())], "Command not found, this should never happen")
	command_dictionary[(command.strip_edges())].call(arguments)


func _process_input(inpt: String) -> void:
	var stdin: PackedStringArray = inpt.split(" ")
	var command: String = stdin[0]
	var arguments: Array[String] = (stdin.slice(1, stdin.size() - 1) as Array[String]) if stdin.size() > 1 else ([] as Array[String])
	if command_dictionary.has(stdin[0]):
		_input_command(command, arguments)
	else:
		KLog.error("Command " + command + " not found")


func _ready() -> void:
	input.text_submitted.connect(_process_input)
