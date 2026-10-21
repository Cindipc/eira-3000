extends Node3D

@export var target: Node3D
@export var follow_dist := 0.25
@export var side := 1.15
@export var height := 0.0
@export var smooth := 8.0
@export var rot_smooth := 10.0
@export var teleport_dist := 6.0
@export var hide_meshes: Array[String] = ["Object_9"]

func _ready() -> void:
	if target == null:
		_resolve_target()
	if target != null and is_instance_valid(target):
		rotation.y = target.rotation.y
	_hide_extras()

func _resolve_target() -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p == null:
		call_deferred("_resolve_target")
		return
	target = p.get_node_or_null("Visual") as Node3D

func _hide_extras() -> void:
	for n in find_children("*", "MeshInstance3D", true, false):
		if hide_meshes.has(n.name):
			(n as MeshInstance3D).visible = false

func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		_resolve_target()
		if target == null or not is_instance_valid(target):
			return
	var t := target.global_transform
	var desired := t.origin - t.basis.z * follow_dist + t.basis.x * side + Vector3.UP * height
	var dist := global_position.distance_to(desired)
	if dist > teleport_dist:
		global_position = desired
	else:
		global_position = global_position.lerp(desired, clampf(smooth * delta, 0.0, 1.0))
	rotation.y = lerp_angle(rotation.y, target.rotation.y, clampf(rot_smooth * delta, 0.0, 1.0))
