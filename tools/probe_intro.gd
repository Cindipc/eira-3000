extends RefCounted

var tree: SceneTree
var frames := 0
var errors: Array[String] = []
var config := {}

func configure(cfg: Dictionary) -> void:
	config = cfg

func run(p_tree: SceneTree) -> void:
	tree = p_tree
	var ps := load("res://scenes/Intro.tscn") as PackedScene
	if ps == null:
		print("[intro] FAIL: no se pudo cargar Intro.tscn")
		return
	var intro: Node = ps.instantiate()
	if tree.current_scene:
		var old := tree.current_scene
		tree.current_scene = null
		tree.root.remove_child(old)
		old.queue_free()
	tree.root.add_child(intro)
	tree.current_scene = intro
	print("[intro] instanciado: ", intro.get_class())
	for i in 6:
		await tree.process_frame
	print("[intro] nodos raiz: ", intro.get_child_count())
	var ui := intro.get_node_or_null("IntroUI")
	print("[intro] UI: ", ui != null)
	var cam := intro.get_node_or_null("IntroCamera") as Camera3D
	if cam:
		print("[intro] camara pos=%s actual=%s" % [str(cam.position), str(cam.current)])
	print("[intro] set2026=", intro.get_node_or_null("Set2026") != null,
		" set3000=", intro.get_node_or_null("Set3000") != null)
	# avanza hasta que la introducción cambie de escena (o se agote el tiempo)
	var skip := str(config.get("skip", "0")) == "1"
	var done := false
	var fired := false
	for i in 12000:
		await tree.process_frame
		if skip and not fired and i == 30:
			var ev := InputEventKey.new()
			ev.pressed = true
			ev.keycode = KEY_ESCAPE
			Input.parse_input_event(ev)
			fired = true
		var cur := tree.current_scene
		if cur != null and cur != intro:
			done = true
			break
	if done:
		print("[intro] OK: la introducción terminó en %s" % str(tree.current_scene.scene_file_path))
		if skip:
			print("[intro] OK: salto con tecla funcional")
	else:
		var card := intro.get_node_or_null("IntroUI/Card") as Label
		var sub := intro.get_node_or_null("IntroUI/Sub") as Label
		print("[intro] FAIL: no terminó. paso=", intro._step,
			" card=", card.text if card else "?",
			" sub=", sub.text if sub else "?")
	print("[intro] listo")
