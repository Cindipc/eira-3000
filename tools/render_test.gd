extends SceneTree

var frames := 0
var target_anim := ""
var shot := 0

func _init() -> void:
	var world := Node3D.new()
	get_root().add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.15, 0.16, 0.2)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.5, 0.55, 0.6)
	e.ambient_light_energy = 1.0
	env.environment = e
	world.add_child(env)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 2.0
	world.add_child(light)

	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.2, 4.0)
	cam.look_at(Vector3(0, 1.0, 0))
	world.add_child(cam)
	cam.current = true

	for p in ["res://assets/characters/eira.glb", "res://assets/characters/nova.glb"]:
		var ps: PackedScene = load(p)
		var inst: Node = ps.instantiate()
		world.add_child(inst)
		if p.ends_with("eira.glb"):
			inst.position = Vector3(-1.2, 0, 0)
			_snap(inst)
		else:
			inst.position = Vector3(1.2, 0, 0)

func _snap(n: Node) -> void:
	var pl: AnimationPlayer = _find(n)
	if pl and pl.has_animation("idle"):
		pl.play("idle")
		pl.advance(0.0)

func _find(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n as AnimationPlayer
	for c in n.get_children():
		var r := _find(c)
		if r != null:
			return r
	return null

func _process(_d: float) -> bool:
	frames += 1
	if frames == 5:
		var img := get_root().get_texture().get_image()
		img.save_png("user://render_test.png")
		print("SHOT saved at frame ", frames)
		return true
	return false
