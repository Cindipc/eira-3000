extends L3Interactable

## Archivo secreto del Nucleo. Eira lo lee con E (+300).

@export var title: String = "ARCHIVO SECRETO"
@export var content: String = "Proyecto Eira: el nucleo tambien fue disenado para decidir por nosotros. Kael solo lo llevo al limite."

var _panel: MeshInstance3D = null
var _light: OmniLight3D = null
var _read := false

func _ready() -> void:
	super._ready()
	prompt = "[E] Leer archivo secreto"
	_build_visual()

func _build_visual() -> void:
	var root := Node3D.new()
	root.name = "Visual"
	add_child(root)

	var mat_frame := L3Kit.mat(Color(0.16, 0.15, 0.20), 0.85, 0.35)
	var mat_screen := L3Kit.mat(Color(0.05, 0.12, 0.18), 0.4, 0.3, Color(0.3, 0.9, 1.0), 2.6)

	L3Kit.box(root, "Stand", Vector3(0, 0.4, 0), Vector3(0.16, 0.8, 0.16), mat_frame)
	_panel = L3Kit.box(root, "Panel", Vector3(0, 1.05, 0), Vector3(0.9, 0.6, 0.08), mat_screen)
	L3Kit.label(root, "Label", title, Vector3(0, 1.55, 0), 34, Color(0.6, 0.95, 1.0))
	_light = L3Kit.light(root, "Glow", Vector3(0, 1.1, 0.4), Color(0.3, 0.8, 1.0), 2.2, 6.0)

func _process(delta: float) -> void:
	super._process(delta)
	if _read:
		return
	if _panel:
		_panel.rotation.y = sin(Time.get_ticks_msec() * 0.0012) * 0.35
	if _light:
		_light.light_energy = 1.8 + sin(Time.get_ticks_msec() * 0.004) * 0.8

func on_activate() -> void:
	_read = true
	enabled = false
	var narrator := get_tree().get_first_node_in_group("narrator")
	if narrator and narrator.has_method("say"):
		narrator.call("say", content, 5.5)
	GameState.notify("Archivo secreto del Proyecto Eira", Color(0.5, 0.9, 1.0))
	if _panel:
		var m := _panel.material_override as StandardMaterial3D
		if m:
			m.albedo_color = Color(0.05, 0.2, 0.12)
			m.emission = Color(0.2, 1.0, 0.5)
	if _light:
		_light.light_color = Color(0.3, 1.0, 0.5)
	var d := get_tree().get_first_node_in_group("l3_director")
	if d and d.has_method("on_secret_file"):
		d.call("on_secret_file", self)
