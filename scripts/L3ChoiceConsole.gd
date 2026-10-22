extends L3Interactable

## Consola de la decision final. Hay tres: humanos, androides y libertad.
## Solo la libertad libera a los androides y termina el juego.

enum Option { HUMANS, ANDROIDS, FREEDOM }

@export var option: int = Option.FREEDOM
@export var option_label: String = "LIBERTAD"

var revealed := false

var _screen: MeshInstance3D = null
var _light: OmniLight3D = null
var _label3d: Label3D = null

func _ready() -> void:
	super._ready()
	one_shot = false
	enabled = false
	visible = false
	_build_visual()

func _build_visual() -> void:
	var root := Node3D.new()
	root.name = "Visual"
	add_child(root)

	var mat_frame := L3Kit.mat(Color(0.12, 0.12, 0.15), 0.9, 0.3)
	var mat_screen := L3Kit.mat(Color(0.05, 0.06, 0.09), 0.4, 0.25, Color(0.6, 0.2, 0.2), 1.6)

	L3Kit.cyl(root, "Base", Vector3(0, 0.15, 0), 0.8, 0.3, mat_frame)
	L3Kit.box(root, "Column", Vector3(0, 0.9, 0), Vector3(0.7, 1.2, 0.6), mat_frame)
	_screen = L3Kit.box(root, "Screen", Vector3(0, 1.6, 0.2), Vector3(1.1, 0.7, 0.12), mat_screen)
	_label3d = L3Kit.label(root, "Label", option_label, Vector3(0, 2.25, 0), 44, Color(1.0, 0.6, 0.6))
	_light = L3Kit.light(root, "Glow", Vector3(0, 1.6, 0.5), Color(1.0, 0.35, 0.3), 1.5, 7.0)

func _process(delta: float) -> void:
	super._process(delta)
	if not revealed:
		return
	var t := Time.get_ticks_msec() * 0.001
	if _screen:
		_screen.rotation.y = sin(t * 0.9) * 0.25
	if _light:
		_light.light_energy = 2.2 + sin(t * 3.0) * 0.9

func can_interact() -> bool:
	return revealed and enabled

func reveal(tint: Color = Color(0.35, 1.0, 0.6)) -> void:
	if revealed:
		return
	revealed = true
	visible = true
	enabled = true
	prompt = "[E] Elegir: " + option_label
	if _screen:
		var m := _screen.material_override as StandardMaterial3D
		if m:
			m.emission = tint
			m.emission_energy_multiplier = 3.0
	if _light:
		_light.light_color = tint
		_light.light_energy = 3.0
	if _label3d:
		_label3d.modulate = tint

func on_activate() -> void:
	var d := get_tree().get_first_node_in_group("l3_director")
	if d and d.has_method("on_choice"):
		d.call("on_choice", option)
