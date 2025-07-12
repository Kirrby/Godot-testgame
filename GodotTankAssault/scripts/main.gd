extends Node2D

const TANK_SCENE = preload("res://scenes/tank.tscn")
const BULLET_SCENE = preload("res://scenes/bullet.tscn")

@onready var round_end_timer = $RoundEndTimer
@onready var hud = $HUD
@onready var camera = $Camera2D
var arena: TileMapLayer

func _ready():
	_create_map()
	# If we are a client, after loading the scene, we tell the server we are ready.
	if not multiplayer.is_server():
		NetworkManager.client_ready_to_receive_players.rpc_id(1)
	# The server spawns players for itself when it starts.
	else:
		NetworkManager.add_player(multiplayer.get_unique_id())


@rpc("any_peer","call_local")
func spawn_player(peer_id):
	if get_node_or_null("Players/" + str(peer_id)):
		print("Tank for peer", peer_id, "already exists. Skip.")
		return
	print("Spawning tank for peer:", peer_id)
	var tank = TANK_SCENE.instantiate()
	tank.name = str(peer_id)
	tank.add_to_group("tanks")
	if multiplayer.is_server():
		tank.set_multiplayer_authority(peer_id)
	$Players.add_child(tank)
	tank.position = Vector2(randi_range(100, 800), randi_range(100, 630))


@rpc("any_peer", "reliable")
func server_request_shoot(shooter_id, bullet_position, bullet_velocity):
	# This function is called by a client, but runs on the server.
	# The server then broadcasts the command to all peers to spawn the bullet.
	broadcast_spawn_bullet.rpc(shooter_id, bullet_position, bullet_velocity)

@rpc("any_peer","call_local","reliable")
func broadcast_spawn_bullet(shooter_id, bullet_position, bullet_velocity):
	var bullet = BULLET_SCENE.instantiate()
	bullet.position = bullet_position
	bullet.init(shooter_id, bullet_velocity)
	add_child(bullet)

@rpc("any_peer", "call_local")
func remove_player(peer_id):
	var tank = get_node_or_null("Players/" + str(peer_id))
	if tank:
		tank.queue_free()

func _on_round_end_timer_timeout():
	get_tree().reload_current_scene()

@rpc("any_peer", "call_local")
func spawn_explosion_rpc(position):
	var explosion = preload("res://scenes/explosion.tscn").instantiate()
	explosion.position = global_position
	add_child(explosion)
	#camera.shake()

func _create_tileset_in_code() -> TileSet:
	var new_tileset = TileSet.new()
	var source = TileSetAtlasSource.new()
	new_tileset.add_source(source, 0)
	new_tileset.add_physics_layer()
	new_tileset.set_physics_layer_collision_layer(0, 1)

	var placeholder_tex = PlaceholderTexture2D.new()
	placeholder_tex.size = Vector2i(16, 16)
	source.texture = placeholder_tex
	source.texture_region_size = Vector2i(16, 16)
	
	source.create_tile(Vector2i.ZERO)
	
	var tile_data = source.get_tile_data(Vector2i.ZERO, 0)
	var polygon = PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), 
		Vector2(8, 8), Vector2(-8, 8)
	])
	tile_data.set_collision_polygons_count(0, 1)
	tile_data.set_collision_polygon_points(0, 0, polygon)
	
	return new_tileset

const MAP_DATA = [
"############################################################",
"#............#.........................#...................#",
"#............#.........####............#...................#",
"#............#.................................####........#",
"#............................#####.........................#",
"#....####..................................................#",
"#.....................................###..................#",
"#.................###......................##..............#",
"#....####...........................................####...#",
"#..........................................................#",
"#.......####.......................####....................#",
"#..........................................................#",
"#.............................##...........................#",
"#............####..........................................#",
"#..........................................####............#",
"#..........................................................#",
"#.........................#.........................#......#",
"#.........................#.........................#......#",
"#..........................................................#",
"#.............#####...........................#####........#",
"#..........................................................#",
"#.....######........................######.................#",
"#..........................................................#",
"#..........................................................#",
"#....######.............####.................#####.........#",
"#..........................................................#",
"#...................##..................##.................#",
"#.........#####............................................#",
"#...............................................#####......#",
"#....................#####.................#####...........#",
"#..........................................................#",
"#..######.......................................######.....#",
"#..........................................................#",
"#..............####.......................####.............#",
"#..........................................................#",
"#.................####...........####......................#",
"#..........................................................#",
"#..........................................................#",
"#..........######............................######........#",
"############################################################"
]

func _create_map():
	arena = TileMapLayer.new()
	arena.tile_set = _create_tileset_in_code()
	add_child(arena)

	var wall_source_id = 0
	var wall_atlas_coords = Vector2i(0, 0)

	for y in range(len(MAP_DATA)):
		for x in range(MAP_DATA[y].length()):
			var tile_char = MAP_DATA[y][x]
			if tile_char == "#":
				arena.set_cell(Vector2i(x, y), wall_source_id, wall_atlas_coords)


#func _create_map():
	#arena = TileMapLayer.new()
	#arena.tile_set = _create_tileset_in_code()
	#arena.z_index = -1 # Draw behind tanks
	#add_child(arena)
#
	#var map_width = 70
	#var map_height = 40
	#var wall_source_id = 0
	#var wall_atlas_coords = Vector2i(0, 0)
#
	#for x in range(map_width):
		#arena.set_cell(Vector2i(x, 0), wall_source_id, wall_atlas_coords)
		#arena.set_cell(Vector2i(x, map_height - 1), wall_source_id, wall_atlas_coords)
	#for y in range(map_height):
		#arena.set_cell(Vector2i(0, y), wall_source_id, wall_atlas_coords)
		#arena.set_cell(Vector2i(map_width - 1, y), wall_source_id, wall_atlas_coords)
