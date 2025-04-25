extends Node3D

var chunk_asset := preload("res://Orbs/orb.tscn")

@export var chunk_size : float
@export var chunks_around : int
@export var chunks_remove_distance : int

var chunks : Dictionary[Vector3i, Node3D]

var player_ref : Node3D
var player_pos : Vector3

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

func _ready() -> void:
	player_ref = $Freecam3D
	player_pos = player_ref.global_position

func _remove_chunk(chunk_coord: Vector3i) -> void:
	if chunks.has(chunk_coord):
		chunks[chunk_coord].queue_free()
		chunks.erase(chunk_coord)

func _add_chunk(chunk_coord: Vector3i) -> void:
	if !chunks.has(chunk_coord):
		var asset : Node3D = chunk_asset.instantiate()
		asset.bounds = chunk_size
		asset.translate(decode_coordinate(chunk_coord))
		add_child(asset)
		chunks[chunk_coord] = asset

func _remove_old_chunks() -> void:
	for x in [-chunks_remove_distance, chunks_remove_distance]:
		for y in range(-chunks_remove_distance, chunks_remove_distance + 1):
			for z in range(-chunks_remove_distance, chunks_remove_distance + 1):
				var chunk_coord : Vector3i = encode_coordinate(player_pos) + Vector3i(x,y,z)
				if chunks.has(chunk_coord):
					call_deferred("_remove_chunk", chunk_coord)
	for x in range(-chunks_remove_distance, chunks_remove_distance + 1):
		for y in [-chunks_remove_distance, chunks_remove_distance]:
			for z in range(-chunks_remove_distance, chunks_remove_distance + 1):
				var chunk_coord : Vector3i = encode_coordinate(player_pos) + Vector3i(x,y,z)
				if chunks.has(chunk_coord):
					call_deferred("_remove_chunk", chunk_coord)
	for x in range(-chunks_remove_distance, chunks_remove_distance + 1):
		for y in range(-chunks_remove_distance, chunks_remove_distance + 1):
			for z in [-chunks_remove_distance, chunks_remove_distance]:
				var chunk_coord : Vector3i = encode_coordinate(player_pos) + Vector3i(x,y,z)
				if chunks.has(chunk_coord):
					call_deferred("_remove_chunk", chunk_coord)

func _add_chunks() -> void:
	for x in range(-chunks_around, chunks_around + 1):
		for y in range(-chunks_around, chunks_around + 1):
			for z in range(-chunks_around, chunks_around + 1):
				var chunk_coord := encode_coordinate(player_pos) + Vector3i(x,y,z)
				if !chunks.has(chunk_coord):
					call_deferred("_add_chunk", chunk_coord)


var tick_count : int = 0
var frame_interval_destroy : int = 20
var frame_interval_create : int = 19

var thread_destroy : Thread
var thread_create : Thread

func _physics_process(_delta: float) -> void:
	player_pos = player_ref.global_position
	
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
