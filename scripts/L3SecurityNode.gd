extends L3Interactable

## Sistema de seguridad del Nucleo Central. Eira lo desactiva con E.

@export var node_index: int = 0

var _core: MeshInstance3D = null
var _light: OmniLight3D = null
var _ring: Node3D = null
var _disabled := false

func _ready() -> void:
	super._ready()
	prompt = "[E] Desactivar sistema de seguridad"
	_build_visual()

func _build_visual() -> void:
	var root := Node3D.new()
	root.name = "Visual"
	add_child(root)

	var mat_panel := L3Kit.mat(Color(0.10, 0.11, 0.14), 0.9, 0.35)
	var mat_hot := L3Kit.mat(Color(0.25, 0.05, 0.05), 0.4, 0.4, Color(1.0, 0.2, 0.12), 3.5)
	var mat_tech := L3Kit.mat(Color(0.04, 0.14, 0.22), 0.6, 0.35, Color(0.0, 0.8, 1.0), 2.0)

	L3Kit.cyl(root, "Base", Vector3(0, 0.2, 0), 0.75, 0.4, mat_panel)
	L3Kit.box(root, "Pillar", Vector3(0, 1.3, 0), Vector3(0.45, 2.2, 0.45), mat_panel)
	_core = L3Kit.sphere(root, "Core", Vector3(0, 2.7, 0), 0.38, mat_hot)
	_light = L3Kit.light(root, "CoreLight", Vector3(0, 2.7, 0), Color(1.0, 0.25, 0.12), 4.0, 8.0)
	_ring = Node3D.new()
	_ring.name = "Ring"
	_ring.position = Vector3(0, 2.7, 0)
	root.add_child(_ring)
	var torus := TorusMesh.new()
	torus.inner_radius = 0.62
	torus.outer_radius = 0.78
	var ring_mesh := MeshInstance3D.new()
	ring_mesh.name = "RingMesh"
	ring_mesh.mesh = torus
	ring_mesh.material_override = mat_tech
	_ring.add_child(ring_mesh)

func _process(delta: float) -> void:
	super._process(delta)
	if _ring:
		_ring.rotation.y += delta * 1.4
		_ring.rotation.x = sin(Time.get_ticks_msec() * 0.002) * 0.4
	if _light and not _disabled:
		_light.light_energy = 3.0 + sin(Time.get_ticks_msec() * 0.006) * 1.6

func on_activate() -> void:
	if _disabled:
		return
	_disabled = true
	enabled = false
	if _core:
		var m := _core.material_override as StandardMaterial3D
		if m:
			m.albedo_color = Color(0.05, 0.3, 0.12)
			m.emission = Color(0.2, 1.0, 0.4)
			m.emission_energy_multiplier = 3.0
	if _light:
		_light.light_color = Color(0.3, 1.0, 0.5)
		_light.light_energy = 1.2
	GameState.notify("Sistema de seguridad desactivado", Color(0.4, 1.0, 0.6))
	var d := get_tree().get_first_node_in_group("l3_director")
	if d and d.has_method("on_security_disabled"):
		d.call("on_security_disabled", self)
