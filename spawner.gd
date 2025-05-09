extends Node3D

@export var chunk_asset = preload("res://Orbs/orb.tscn")

@export var chunk_size : float
@export var chunks_around : int
@export var chunks_remove_distance : int

@export var spawn_mesh : Mesh

var chunks : Dictionary[Vector3i, Node3D]

var player_ref : Freecam3D
var player_pos : Vector3

var asset_pool : Array[Node3D]
var asset_pool_index : int = 0

var hyperspace_enabled : bool = false

func _ready() -> void:
	player_ref = $Freecam3D
	player_pos = player_ref.global_position
	
	spawn_mesh.surface_get_material(0).set_shader_parameter("voronoi_scale", chunk_size * (1.0/3.0))
	
	for i : int in pow(chunks_remove_distance * 2, 3):
		var asset : Node3D = chunk_asset.instantiate()
		asset.mesh = spawn_mesh
		asset.set_bounds(chunk_size)
		add_child(asset)
		asset_pool.append(asset)
		asset.visible = false

func encode_coordinate(coordinate : Vector3) -> Vector3i:
	return Vector3i(
		roundi(coordinate.x / chunk_size),
		roundi(coordinate.y / chunk_size),
		roundi(coordinate.z / chunk_size),
	)

func decode_coordinate(key : Vector3i) -> Vector3:
	return Vector3(
		(key.x) * chunk_size,
		(key.y) * chunk_size,
		(key.z) * chunk_size
	)

func _remove_chunk(chunk_coord: Vector3i) -> void:
	if chunks.has(chunk_coord):
		var asset : Node3D = chunks[chunk_coord]
		chunks.erase(chunk_coord)
		asset.hide_mm()
		asset_pool.append(asset)

func _add_chunk(chunk_coord: Vector3i) -> void:
	if !chunks.has(chunk_coord):
		var asset : Node3D = asset_pool.pop_back()
		asset.global_position = decode_coordinate(chunk_coord)
		asset.regenerate_points_threaded()
		chunks[chunk_coord] = asset

func _remove_old_chunks() -> void:
	for x in [-chunks_remove_distance, chunks_remove_distance]:
		for y in range(-chunks_remove_distance, chunks_remove_distance + 1):
			for z in range(-chunks_remove_distance, chunks_remove_distance + 1):
				var chunk_coord : Vector3i = encode_coordinate(player_pos) + Vector3i(x,y,z)
				if chunks.has(chunk_coord):
					_remove_chunk.call_deferred(chunk_coord)
	for x in range(-chunks_remove_distance, chunks_remove_distance + 1):
		for y in [-chunks_remove_distance, chunks_remove_distance]:
			for z in range(-chunks_remove_distance, chunks_remove_distance + 1):
				var chunk_coord : Vector3i = encode_coordinate(player_pos) + Vector3i(x,y,z)
				if chunks.has(chunk_coord):
					_remove_chunk.call_deferred(chunk_coord)
	for x in range(-chunks_remove_distance, chunks_remove_distance + 1):
		for y in range(-chunks_remove_distance, chunks_remove_distance + 1):
			for z in [-chunks_remove_distance, chunks_remove_distance]:
				var chunk_coord : Vector3i = encode_coordinate(player_pos) + Vector3i(x,y,z)
				if chunks.has(chunk_coord):
					_remove_chunk.call_deferred(chunk_coord)

func _add_chunks() -> void:
	for x in range(-chunks_around, chunks_around + 1):
		for y in range(-chunks_around, chunks_around + 1):
			for z in range(-chunks_around, chunks_around + 1):
				var chunk_coord := encode_coordinate(player_pos) + Vector3i(x,y,z)
				if !chunks.has(chunk_coord):
					_add_chunk.call_deferred(chunk_coord)


var tick_count : int = 0
var frame_interval_destroy : int = 20
var frame_interval_create : int = 19

var thread_destroy : Thread
var thread_create : Thread

func _physics_process(_delta: float) -> void:
	player_pos = player_ref.global_position
	
	if hyperspace_enabled:
		spawn_mesh.surface_get_material(0).set_shader_parameter("warp_stretch", pow(player_ref.velocity.length() / player_ref.target_speed, 5.0) * 0.25)
		spawn_mesh.surface_get_material(0).set_shader_parameter("velocity_dir", player_ref.velocity)
	else:
		spawn_mesh.surface_get_material(0).set_shader_parameter("warp_stretch", 0.0)
		spawn_mesh.surface_get_material(0).set_shader_parameter("velocity_dir", Vector3(0.0, 0.0, 0.0))
	
	if tick_count % frame_interval_destroy == 0:
		if thread_destroy:
			thread_destroy.wait_to_finish()
		thread_destroy = Thread.new()
		thread_destroy.start(_remove_old_chunks)

	if tick_count % frame_interval_create == 0:
		if thread_create:
			thread_create.wait_to_finish()
		thread_create = Thread.new()
		thread_create.start(_add_chunks)

	tick_count += 1

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("hyperspace"):
		hyperspace_enabled = !hyperspace_enabled
		if hyperspace_enabled:
			player_ref.target_speed = 30.0
		else:
			player_ref.velocity /= 2.0
			player_ref.target_speed = 10.0
