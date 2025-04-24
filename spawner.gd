extends Node3D

var chunk_asset := preload("res://Orbs/orb.tscn")

@export var chunk_size : float
@export var chunks_around : int

var chunks : Dictionary[Vector3i, Node3D]

var player_ref : Node3D

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
	
	var chunk_coord : Vector3i = encode_coordinate(player_ref.position)
	
	var asset : Node3D = chunk_asset.instantiate()
	asset.bounds = chunk_size
	asset.translate(decode_coordinate(chunk_coord))
	add_child(asset)
	chunks[chunk_coord] = asset


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	for x in range(-chunks_around, chunks_around + 1):
		for y in range(-chunks_around, chunks_around + 1):
			for z in range(-chunks_around, chunks_around + 1):
				var chunk_coord := encode_coordinate(player_ref.global_position) + Vector3i(x,y,z)
				
				if !chunks.has(chunk_coord):
						var asset : Node3D = chunk_asset.instantiate()
						asset.bounds = chunk_size
						asset.translate(decode_coordinate(chunk_coord))
						add_child(asset)
						chunks[chunk_coord] = asset
