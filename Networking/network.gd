extends Node

var multiplayer_peer = ENetMultiplayerPeer.new()

# # Called when the node enters the scene tree for the first time.
# func _ready() -> void:
# 	var upnp = UPNP.new()
# 	var discover_result = upnp.discover()

# 	if discover_result == UPNP.UPNP_RESULT_SUCCESS:
# 		if upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
# 			var map_result_tcp = upnp.add_port_mapping(1221, 1221, "godot_tcp", "TCP", 0)
# 			var map_result_udp = upnp.add_port_mapping(1221, 1221, "godot_udp", "UDP", 0)
# 			if not map_result_tcp == UPNP.UPNP_RESULT_SUCCESS:
# 				upnp.add_port_mapping(1221, 1221, "", "TCP")
# 			if not map_result_udp == UPNP.UPNP_RESULT_SUCCESS:
# 				upnp.add_port_mapping(1221, 1221, "", "UDP")

# 	var external_ip = upnp.query_external_address()

# 	print(external_ip)

# 	upnp.delete_port_mapping(1221, "TCP")
# 	upnp.delete_port_mapping(1221, "UDP")

const PORT = 1221

var connected_peer_ids = []

func _on_host_pressed() -> void:
	$Control/VBoxContainer/Status.text = "Server"
	multiplayer_peer.create_server(1221)
	multiplayer.multiplayer_peer = multiplayer_peer
	$Control/VBoxContainer/Id.text = str(multiplayer.get_unique_id())
	
	$Control/VBoxContainer/join.visible = false
	$Control/VBoxContainer/host.visible = false

	add_player_character(1)

	multiplayer.peer_connected.connect(
		func (id):
			rpc("add_new_connections", id)
			rpc_id(id, "add_previous_characters", connected_peer_ids)
			add_player_character(id)
	)

@rpc
func add_new_connections(id):
	add_player_character(id)

@rpc
func add_previous_characters(ids):
	for peer_id in ids:
		add_player_character(peer_id)

func _on_join_pressed() -> void:
	$Control/VBoxContainer/Status.text = "Client"
	multiplayer_peer.create_client("localhost", PORT)
	multiplayer.multiplayer_peer = multiplayer_peer
	$Control/VBoxContainer/Id.text = str(multiplayer.get_unique_id())

	$Control/VBoxContainer/join.visible = false
	$Control/VBoxContainer/host.visible = false

func add_player_character(id):
	connected_peer_ids.append(id)
	var p_instance = preload("res://Networking/test_character.tscn").instantiate()
	p_instance.set_multiplayer_authority(id)
	p_instance.position.y = 10;
	add_child(p_instance)
