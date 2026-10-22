extends L3Interactable

## Sistema central del Nucleo. Eira accede con su sangre y las tres
## opciones del destino de humanos y androides se encienden.

@export var enabled_before_access: bool = false

var _screen: MeshInstance3D = null
var _slot: MeshInstance3D = null
var _light: OmniLight3D = null
var _ring: Node3D = null
var _accessed := false

func _ready() -> void:
	super._ready()
	prompt = "[E] Usar tu sangre para acceder al sistema central"
	_build_visual()

func _build_visual() -> void:
	var root := Node3D.new()
	root.name = "Visual"
	add_child(root)

	var mat_frame := L3Kit.mat(Color(0.12, 0.12, 0.16), 0.9, 0.3)
	var mat_screen := L3Kit.mat(Color(0.04, 0.10, 0.16), 0.4, 0.25, Color(0.0, 0.7, 1.0), 2.4)
	var mat_blood := L3Kit.mat(Color(0.25, 0.02, 0.04), 0.3, 0.4, Color(1.0, 0.15, 0.2), 2.6)

	L3Kit.cyl(root, "Base", Vector3(0, 0.3, 0), 1.4, 0.6, mat_frame)
	L3Kit.box(root, "Column", Vector3(0, 1.5, 0), Vector3(1.0, 2.0, 0.8), mat_frame)
	_screen = L3Kit.box(root, "Screen", Vector3(0, 2.1, 0.45), Vector3(1.4, 1.0, 0.1), mat_screen)
	_slot = L3Kit.box(root, "BloodSlot", Vector3(0, 1.25, 0.55), Vector3(0.5, 0.1, 0.2), mat_blood)
	L3Kit.label(root, "Label", "SISTEMA CENTRAL", Vector3(0, 3.0, 0), 40, Color(0.6, 0.95, 1.0))

	_ring = Node3D.new()
	_ring.name = "Ring"
	_ring.position = Vector3(0, 2.4, 0)
	root.add_child(_ring)
	var torus := TorusMesh.new()
	torus.inner_radius = 1.1
	torus.outer_radius = 1.35
	var mesh := MeshInstance3D.new()
	mesh.name = "RingMesh"
	mesh.mesh = torus
	mesh.material_override = mat_screen
	_ring.add_child(mesh)

	_light = L3Kit.light(root, "Glow", Vector3(0, 2.2, 0), Color(0.2, 0.8, 1.0), 3.0, 12.0)

func _process(delta: float) -> void:
	super._process(delta)
	if _ring:
		_ring.rotation.y += delta * 0.7
	if _light:
		_light.light_energy = 2.4 + sin(Time.get_ticks_msec() * 0.004) * 1.0

func unlock() -> void:
	enabled_before_access = true
	enabled = true
	if _light:
		_light.light_energy = 5.0
		_light.light_color = Color(0.2, 1.0, 0.6)
	if _screen:
		var m := _screen.material_override as StandardMaterial3D
		if m:
			m.emission = Color(0.2, 1.0, 0.5)

func reset_access() -> void:
	## Deja el terminal listo para un nuevo acceso (bucle de la linea temporal).
	_accessed = false
	enabled = false
	enabled_before_access = false
	reset_use()
	if _screen:
		var m := _screen.material_override as StandardMaterial3D
		if m:
			m.emission = Color(0.0, 0.7, 1.0)
	if _light:
		_light.light_energy = 3.0
		_light.light_color = Color(0.2, 0.8, 1.0)

func on_activate() -> void:
	if _accessed or not enabled_before_access:
		return
	_accessed = true
	enabled = false
	if _slot:
		var m := _slot.material_override as StandardMaterial3D
		if m:
			m.emission = Color(1.0, 0.4, 0.3)
			m.emission_energy_multiplier = 6.0
	var narrator := get_tree().get_first_node_in_group("narrator")
	if narrator and narrator.has_method("say"):
		narrator.call("say", "Eira: mi sangre... es la clave. El nucleo me reconoce.", 5.0)
	GameState.notify("Sistema central accesible", Color(0.4, 1.0, 0.7))
	var d := get_tree().get_first_node_in_group("l3_director")
	if d and d.has_method("on_core_accessed"):
		d.call("on_core_accessed")
