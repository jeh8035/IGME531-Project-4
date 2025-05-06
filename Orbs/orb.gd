extends MultiMeshInstance3D

@export var mesh : Mesh
@export var count : int

var bounds : float

var data : PackedFloat32Array

var thread : Thread

func _ready() -> void:
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	data.resize(count * 12)

func finish() -> void:
	visible = true
	multimesh.instance_count = floori(data.size() / 12.0)
	multimesh.visible_instance_count = multimesh.instance_count
	multimesh.buffer = data

func set_bounds(new_bounds : float) -> void:
	bounds = new_bounds
	material_override.set_shader_parameter("voronoi_scale", bounds * (1.0/3.0))
	
	var larger_bounds := bounds + bounds * (1.0/3.0)
	custom_aabb = AABB(Vector3(-larger_bounds/2.0, -larger_bounds/2.0 ,-larger_bounds/2.0), Vector3(larger_bounds, larger_bounds, larger_bounds))

func regenerate_points_threaded() -> void:
	if thread:
		thread.wait_to_finish()
	thread = Thread.new()
	thread.start(regenerate_points)
	
func regenerate_points() -> void:
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
	call_deferred("finish")

func hide_mm() -> void:
	visible = false
