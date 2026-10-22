extends RefCounted

var tree: SceneTree
var level: Node
var shot := 0

func run(p_tree: SceneTree) -> void:
	tree = p_tree
	level = Node3D.new()
	tree.root.add_child(level)
	var cam := Camera3D.new()
	level.add_child(cam)
	cam.current = true
	cam.far = 200.0
	var light := DirectionalLight3D.new()
	level.add_child(light)
	light.rotation = Vector3(-1.2, 0.8, 0.0)
	light.light_energy = 1.6
	var env := WorldEnvironment.new()
	level.add_child(env)
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.12, 0.13, 0.16)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.5, 0.55, 0.65)
	e.ambient_light_energy = 0.8
	env.environment = e

	var ps: PackedScene = load("res://assets/characters/character.fbx")
	var model := ps.instantiate()
	level.add_child(model)
	for i in 30:
		await tree.process_frame
	# ocultar joints
	for n in model.find_children("*", "MeshInstance3D", true, false):
		if n.name == "Alpha_Joints":
			(n as MeshInstance3D).visible = false
	var ap := model.find_children("*", "AnimationPlayer", true, false)
	if not ap.is_empty():
		var anim := ap[0] as AnimationPlayer
		print("ANIMS: ", anim.get_animation_list())
		for a in anim.get_animation_list():
			var an: Animation = anim.get_animation(a)
			print("   ", a, " len=", an.length, " tracks=", an.get_track_count())
			an.loop_mode = Animation.LOOP_LINEAR
		anim.play(anim.get_animation_list()[0])
	for i in 10:
		await tree.process_frame

	DirAccess.make_dir_recursive_absolute("res://screenshots")
	await _shot_at(Vector3(0, 1.0, 3.0), Vector3(0, 0.95, 0), "char_frente")
	await _shot_at(Vector3(0, 1.0, -3.0), Vector3(0, 0.95, 0), "char_atras")
	await _shot_at(Vector3(3.0, 1.0, 0), Vector3(0, 0.95, 0), "char_lado")
	print("SHOTS DONE (%d)" % shot)
	tree.quit()

func _shot_at(pos: Vector3, look: Vector3, name: String) -> void:
	var cam := level.get_child(0) as Camera3D
	cam.global_position = pos
	cam.look_at_from_position(pos, look, Vector3.UP)
	for i in 6:
		await tree.process_frame
	await RenderingServer.frame_post_draw
	var img := tree.root.get_texture().get_image()
	if img == null:
		print("no image for ", name)
		return
	img.save_png("res://screenshots/%s.png" % name)
	shot += 1
	print("saved ", name, " ", img.get_size())
