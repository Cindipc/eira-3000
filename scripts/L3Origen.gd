extends L3Interactable

## ORIGEN: la primera conciencia del Proyecto Eira. Se escucha con E.

@export var lines: Array[String] = [
	"ORIGEN: fui la primera conciencia creada por el Proyecto Eira.",
	"ORIGEN: Kael teme lo que no puede controlar. Tu no eres una herramienta.",
	"ORIGEN: los androides solo esperan a alguien que los libere.",
	"ORIGEN: cuando el nucleo caiga, elige con el corazon, Eira.",
]

var _index := 0
var _core: MeshInstance3D = null
var _rings: Array[Node3D] = []

func _ready() -> void:
	super._ready()
	prompt = "[E] Escuchar a ORIGEN"
	_build_visual()

func _build_visual() -> void:
	var root := Node3D.new()
	root.name = "Visual"
	add_child(root)

	var mat_core := L3Kit.mat(Color(0.35, 0.25, 0.55), 0.2, 0.15, Color(0.7, 0.5, 1.0), 3.2)
	var mat_ring := L3Kit.mat(Color(0.25, 0.15, 0.4), 0.5, 0.3, Color(0.6, 0.4, 1.0), 2.2)

	_core = L3Kit.sphere(root, "Core", Vector3(0, 1.4, 0), 0.3, mat_core)
	for i in 3:
		var ring := Node3D.new()
		ring.name = "Ring_%d" % i
		ring.position = Vector3(0, 1.4, 0)
		ring.rotation_degrees = Vector3(90 + i * 22, i * 40, 0)
		root.add_child(ring)
		var torus := TorusMesh.new()
		torus.inner_radius = 0.55 + float(i) * 0.12
		torus.outer_radius = 0.66 + float(i) * 0.12
		var mesh := MeshInstance3D.new()
		mesh.name = "RingMesh"
		mesh.mesh = torus
		mesh.material_override = mat_ring
		ring.add_child(mesh)
		_rings.append(ring)
	L3Kit.light(root, "Glow", Vector3(0, 1.4, 0), Color(0.65, 0.45, 1.0), 3.0, 9.0)
	L3Kit.label(root, "Label", "ORIGEN", Vector3(0, 2.3, 0), 36, Color(0.75, 0.6, 1.0))

func _process(delta: float) -> void:
	super._process(delta)
	var t := Time.get_ticks_msec() * 0.001
	for i in _rings.size():
		_rings[i].rotation.y += delta * (0.6 + float(i) * 0.35)
		_rings[i].rotation.z = sin(t * 0.8 + float(i)) * 0.25
	if _core:
		_core.scale = Vector3.ONE * (1.0 + sin(t * 2.2) * 0.08)

func on_activate() -> void:
	if lines.is_empty():
		return
	var line: String = lines[_index % lines.size()]
	_index += 1
	var narrator := get_tree().get_first_node_in_group("narrator")
	if narrator and narrator.has_method("say"):
		narrator.call("say", line, 5.0)
	GameState.notify("ORIGEN te habla", Color(0.7, 0.5, 1.0))
