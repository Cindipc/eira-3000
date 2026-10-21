extends RefCounted

var tree: SceneTree
var config := {}
var shot := 0

func configure(cfg: Dictionary) -> void:
	config = cfg

func run(p_tree: SceneTree) -> void:
	tree = p_tree
	DirAccess.make_dir_recursive_absolute("res://screenshots")
	var city: Node3D = (load("res://assets/levels/Futuristic_City.fbx") as PackedScene).instantiate()
	city.name = "City"
	tree.root.add_child(city)
	city.set_script(load("res://scripts/CityStyler.gd"))

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.03, 0.06)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.45, 0.55)
	env.ambient_light_energy = 1.2
	env.glow_enabled = true
	env.glow_intensity = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	tree.root.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.6
	sun.rotation_degrees = Vector3(-55, 35, 0)
	tree.root.add_child(sun)

	await tree.process_frame
	for i in 10:
		await tree.process_frame

	await _shot_at(Vector3(0, 600, 1), Vector3(0, 0, 0), 70.0, "city_top")
	await _shot_at(Vector3(-420, 260, 330), Vector3(40, 40, -20), 60.0, "city_wide")
	await _shot_at(Vector3(60, 25, 180), Vector3(40, 30, 0), 60.0, "city_street")
	await _shot_at(Vector3(0, 120, 320), Vector3(20, 60, 0), 60.0, "city_north")
	print("SHOTS DONE (%d)" % shot)
	tree.quit()

func _shot_at(pos: Vector3, look: Vector3, fov: float, name: String) -> void:
	var cam := Camera3D.new()
	cam.fov = fov
	cam.far = 6000.0
	tree.root.add_child(cam)
	cam.global_position = pos
	cam.look_at_from_position(pos, look, Vector3.UP)
	cam.current = true
	for i in 8:
		await tree.process_frame
	await RenderingServer.frame_post_draw
	var img := tree.root.get_texture().get_image()
	if img != null:
		img.save_png("res://screenshots/%s.png" % name)
		shot += 1
		print("saved ", name, " ", img.get_size())
	cam.queue_free()
