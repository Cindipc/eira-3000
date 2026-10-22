extends L3Interactable

## Rebelde androide atrapado en el Nucleo. Eira lo libera con E (+200).

@export var robot_scene: PackedScene = null
@export var rebel_name: String = "Rebelde"

var _bars: Node3D = null
var _model: Node3D = null
var _light: OmniLight3D = null

func _ready() -> void:
	super._ready()
	prompt = "[E] Liberar a " + rebel_name
	_build_visual()

func _build_visual() -> void:
	var root := Node3D.new()
	root.name = "Visual"
	add_child(root)

	var mat_cage := L3Kit.mat(Color(0.14, 0.15, 0.18), 0.9, 0.4)
	var mat_cell := L3Kit.mat(Color(0.10, 0.20, 0.16), 0.5, 0.6, Color(0.1, 0.7, 0.4), 1.2)

	L3Kit.box(root, "Pad", Vector3(0, 0.05, 0), Vector3(2.6, 0.1, 2.6), mat_cell)
	_bars = Node3D.new()
	_bars.name = "Bars"
	root.add_child(_bars)
	for i in 4:
		var x := -0.9 + float(i) * 0.6
		L3Kit.box(_bars, "Bar_%d" % i, Vector3(x, 1.1, 0), Vector3(0.08, 2.2, 0.08), mat_cage)
	L3Kit.box(root, "TopFrame", Vector3(0, 2.2, 0), Vector3(2.2, 0.12, 0.12), mat_cage)

	if robot_scene != null:
		var inst := robot_scene.instantiate() as Node3D
		if inst != null:
			inst.name = "Rebel"
			inst.scale = Vector3.ONE * 0.9
			inst.position = Vector3(0, 0.1, 0)
			root.add_child(inst)
			_model = inst

	_light = L3Kit.light(root, "CellLight", Vector3(0, 2.0, 0), Color(0.3, 1.0, 0.55), 2.0, 7.0)

func on_activate() -> void:
	enabled = false
	if _bars:
		var tw := create_tween()
		tw.tween_property(_bars, "position:y", 2.4, 0.6)
	if _model:
		var tw2 := create_tween()
		tw2.tween_property(_model, "position:y", 0.6, 0.8).set_trans(Tween.TRANS_BACK)
		tw2.parallel().tween_property(_model, "rotation:y", TAU, 0.8)
	GameState.notify("%s liberado" % rebel_name, Color(0.4, 1.0, 0.7))
	var d := get_tree().get_first_node_in_group("l3_director")
	if d and d.has_method("on_rebel_rescued"):
		d.call("on_rebel_rescued", self)
