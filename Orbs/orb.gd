extends MultiMeshInstance3D

@export var mesh : Mesh

@export var bounds : float

@export var count : int

var data : PackedFloat32Array

func finish() -> void:
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = floori(data.size() / 12.0)
	multimesh.visible_instance_count = multimesh.instance_count
	multimesh.buffer = data

func _ready() -> void:
	for i : int in count:
		data.append_array([
			1, 0, 0, randf_range(-bounds/2, bounds/2),
			0, 1, 0, randf_range(-bounds/2, bounds/2),
			0, 0, 1, randf_range(-bounds/2, bounds/2)
		])
	finish()
	
	
