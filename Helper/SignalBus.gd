extends Node

signal place_good_boss
signal burst_good_boss

signal place_bad_boss
signal burst_bad_boss

signal player_defeat(player: CharacterBody3D)
signal player_change_team(player: int)

signal interface_open()
signal interface_closed()

signal username_change(new_name: String)
