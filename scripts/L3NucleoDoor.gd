extends L3Interactable

## Entrada al interior del Nucleo Central. Transiciona de la ciudad al
## interior del nivel 3.

@export var interior_spawn: Node3D = null

var _door_light: OmniLight3D = null
var _door_mesh: MeshInstance3D = null

func _ready() -> void:
	super._ready()
	prompt = "[E] Entrar al Nucleo Central"
	_build_visual()

func _build_visual() -> void:
	var root := Node3D.new()
	root.name = "Visual"
	add_child(root)

	var mat_frame := L3Kit.mat(Color(0.12, 0.12, 0.16), 0.9, 0.35)
	var mat_door := L3Kit.mat(Color(0.05, 0.14, 0.22), 0.5, 0.25, Color(0.0, 0.8, 1.0), 3.0)

	L3Kit.box(root, "FrameL", Vector3(-1.6, 2.2, 0), Vector3(0.5, 4.4, 0.6), mat_frame)
	L3Kit.box(root, "FrameR", Vector3(1.6, 2.2, 0), Vector3(0.5, 4.4, 0.6), mat_frame)
	L3Kit.box(root, "FrameT", Vector3(0, 4.5, 0), Vector3(3.8, 0.5, 0.6), mat_frame)
	_door_mesh = L3Kit.box(root, "Door", Vector3(0, 2.2, 0), Vector3(2.7, 4.2, 0.2), mat_door)
	L3Kit.label(root, "Label", "NÚCLEO CENTRAL", Vector3(0, 5.1, 0), 44, Color(0.5, 0.9, 1.0))
	_door_light = L3Kit.light(root, "DoorLight", Vector3(0, 2.4, 1.2), Color(0.1, 0.8, 1.0), 4.0, 14.0)

func _process(delta: float) -> void:
	super._process(delta)
	if _door_light:
		_door_light.light_energy = 3.2 + sin(Time.get_ticks_msec() * 0.003) * 1.4
	if _door_mesh:
		_door_mesh.scale.y = 1.0 + sin(Time.get_ticks_msec() * 0.002) * 0.012

func on_activate() -> void:
	enabled = false
	var n := get_tree().get_first_node_in_group("narrator")
	if n and n.has_method("fade_to_black"):
		n.call("fade_to_black", 0.8)
	await get_tree().create_timer(0.95).timeout
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player and interior_spawn:
		player.global_position = interior_spawn.global_position
		player.set("velocity", Vector3.ZERO)
		if player.has_method("set_respawn_point"):
			player.call("set_respawn_point", interior_spawn.global_position)
		if player.has_method("cinematic_camera"):
			player.call("cinematic_camera", interior_spawn.rotation.y, -0.1)
	var nova := get_tree().get_first_node_in_group("nova")
	if nova and interior_spawn:
		(nova as Node3D).global_position = interior_spawn.global_position + Vector3(1.2, 0, -0.6)
	if n and n.has_method("fade_from_black"):
		n.call("fade_from_black", 0.9)
	var d := get_tree().get_first_node_in_group("l3_director")
	if d and d.has_method("on_entered_interior"):
		d.call("on_entered_interior")
