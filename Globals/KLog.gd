class_name KLog extends Node

enum LEVEL { CRITICAL, ERROR, WARN, INFO, DEBUG }
static var log_level := LEVEL.DEBUG
static var debug_signals := false

## Prints a message in red starting with CRIT: and stops the program
static func critical(msg: String) -> void:
	print_rich("`color=red`CRIT: " + msg + "`/color`")
	breakpoint


## Prints a message in red starting with ERROR
static func error(msg: String) -> void:
	if log_level >= LEVEL.ERROR:
		print_rich("[color=red]ERROR: " + msg + "[/color]")


## Prints a message in yellow starting with WARN
static func warning(msg: String) -> void:
	if log_level >= LEVEL.WARN:
		print_rich("[color=yellow]WARN: " + msg + "[/color]")


## Prints a message in cyan starting with INFO
static func info(msg: String) -> void:
	if log_level >= LEVEL.INFO:
		print_rich("[color=cyan]INFO: " + msg + "[/color]")


## Prints a message in green starting with DEBUG
static func debug(msg: String) -> void:
	if log_level >= LEVEL.DEBUG:
		print_rich("[color=green]DEBUG: " + msg + "[/color]")
