extends MultiMeshInstance3D

@export var mesh : Mesh

@export var bounds : float

@export var count : int

var data : PackedFloat32Array

func _ready() -> void:
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	data.resize(count * 12)

func finish() -> void:
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh

func regenerate_points() -> void:
	visible = true
	for i : int in count:
		var size : float = randf_range(0.1, 4.0);
		data[i * 12] = size
		data[i * 12 + 1] = 0
		data[i * 12 + 2] = 0
		data[i * 12 + 3] = randf_range(-bounds/2, bounds/2)
		data[i * 12 + 4] = 0
		data[i * 12 + 5] = size
		data[i * 12 + 6] = 0
		data[i * 12 + 7] = randf_range(-bounds/2, bounds/2)
		data[i * 12 + 8] = 0
		data[i * 12 + 9] = 0
		data[i * 12 + 10] = size
		data[i * 12 + 11] = randf_range(-bounds/2, bounds/2)
	multimesh.instance_count = floori(data.size() / 12.0)
	multimesh.visible_instance_count = multimesh.instance_count
	multimesh.buffer = data

func hide_mm() -> void:
	visible = false
