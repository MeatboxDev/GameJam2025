extends Node

signal place_good_boss
signal burst_good_boss

signal place_bad_boss
signal burst_bad_boss

signal player_defeat(player: CharacterBody3D)
signal player_change_team(player: int)

signal interface_open
signal interface_closed

signal username_change(new_name: String)
signal respawn_player(player: CharacterBody3D)

signal spawn_bubble(bubble_information: Dictionary)
signal burst_bubble(number: int)
signal clear_bubbles

func _test_connectionless(s: Signal) -> void:
	if s.get_connections().size() == 1: 
		KLog.warning(s.get_name() + " was emited but has no connections!")


func _ready() -> void:
	if KLog.debug_signals:
		for s: Dictionary in get_signal_list().filter(func(s: Dictionary) -> bool: return s.name != "ready"):
			var sig: Signal = get(s.name)
			sig.connect(func() -> void: _test_connectionless(sig))
