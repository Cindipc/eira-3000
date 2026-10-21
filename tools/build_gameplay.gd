extends RefCounted

var mats := {}

func build() -> void:
	_build_materials()
	_build_android()
	_build_projectile()
	_build_data_file()
	_build_terminal()
	_build_pickup()
	_build_boss()
	_build_hud()
	print("GAMEPLAY BUILD DONE")

func _mat(name: String, albedo: Color, metallic: float, roughness: float, emission: Color = Color(0, 0, 0), energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.metallic = metallic
	m.roughness = roughness
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = energy
	mats[name] = m
	return m

func _build_materials() -> void:
	_mat("dark", Color(0.05, 0.055, 0.07), 0.8, 0.45)
	_mat("steel", Color(0.24, 0.26, 0.3), 0.95, 0.3)
	_mat("cyan", Color(0.02, 0.2, 0.25), 0.4, 0.4, Color(0.0, 0.85, 1.0), 4.0)
	_mat("cyan_dim", Color(0.02, 0.15, 0.2), 0.4, 0.5, Color(0.0, 0.85, 1.0), 1.6)
	_mat("amber", Color(0.3, 0.18, 0.02), 0.4, 0.45, Color(1.0, 0.6, 0.0), 3.0)
	_mat("red", Color(0.3, 0.03, 0.04), 0.4, 0.4, Color(1.0, 0.12, 0.15), 4.0)
	_mat("green", Color(0.05, 0.28, 0.12), 0.3, 0.5, Color(0.2, 1.0, 0.4), 3.0)
	_mat("white", Color(0.85, 0.9, 1.0), 0.2, 0.4)
	_mat("glass", Color(0.2, 0.6, 0.9, 0.35), 0.1, 0.1, Color(0.3, 0.8, 1.0), 1.2)

func _set_owner(node: Node, owner_node: Node) -> void:
	for c in node.get_children():
		c.owner = owner_node
		if c.scene_file_path == "":
			_set_owner(c, owner_node)

func _save(root: Node, path: String) -> void:
	_set_owner(root, root)
	var ps := PackedScene.new()
	var err := ps.pack(root)
	if err != OK:
		push_error("pack failed %s (%d)" % [path, err])
		return
	err = ResourceSaver.save(ps, path)
	print("saved ", path, " -> ", err)

func _mesh(parent: Node3D, n: String, mesh: Mesh, pos: Vector3, mat: String, rot: Vector3 = Vector3.ZERO, scale_v: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = mesh
	mi.position = pos
	mi.rotation = rot
	mi.scale = scale_v
	mi.material_override = mats[mat]
	parent.add_child(mi)
	return mi

func _box(parent: Node3D, n: String, size: Vector3, pos: Vector3, mat: String) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	return _mesh(parent, n, bm, pos, mat)

func _sphere(parent: Node3D, n: String, radius: float, pos: Vector3, mat: String) -> MeshInstance3D:
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 16
	sm.rings = 8
	return _mesh(parent, n, sm, pos, mat)

func _cyl(parent: Node3D, n: String, radius: float, height: float, pos: Vector3, mat: String) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = 16
	return _mesh(parent, n, cm, pos, mat)

# ------------------------------------------------------------------ android
func _build_android() -> void:
	var root := CharacterBody3D.new()
	root.name = "Android"
	root.set_script(load("res://scripts/Android.gd"))

	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var cap := CapsuleShape3D.new()
	cap.radius = 0.42
	cap.height = 1.85
	col.shape = cap
	col.position = Vector3(0, 0.92, 0)
	root.add_child(col)

	var visual := Node3D.new()
	visual.name = "Visual"
	root.add_child(visual)

	var robot: PackedScene = load("res://assets/characters/robot.glb")
	var inst := robot.instantiate()
	inst.name = "Robot"
	inst.set_scene_file_path("res://assets/characters/robot.glb")
	inst.rotation = Vector3(-PI * 0.5, 0.0, 0.0)
	inst.scale = Vector3.ONE * 0.36
	inst.position = Vector3(0, 0.0, 0)
	visual.add_child(inst)

	var head := _sphere(visual, "EyeGlow", 0.1, Vector3(0, 1.72, 0.2), "red")
	head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var light := OmniLight3D.new()
	light.name = "HitLight"
	light.light_color = Color(1.0, 0.25, 0.15)
	light.light_energy = 0.0
	light.omni_range = 4.0
	light.position = Vector3(0, 1.2, 0)
	root.add_child(light)

	root.collision_layer = 4
	root.collision_mask = 1
	_save(root, "res://scenes/Android.tscn")

# ------------------------------------------------------------------ projectile
func _build_projectile() -> void:
	var root := Area3D.new()
	root.name = "Projectile"
	root.set_script(load("res://scripts/Projectile.gd"))

	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var sph := SphereShape3D.new()
	sph.radius = 0.22
	col.shape = sph
	root.add_child(col)

	var visual := Node3D.new()
	visual.name = "Visual"
	root.add_child(visual)
	_sphere(visual, "Plasma", 0.22, Vector3.ZERO, "red")
	var light := OmniLight3D.new()
	light.name = "PlasmaLight"
	light.light_color = Color(1.0, 0.35, 0.15)
	light.light_energy = 3.0
	light.omni_range = 5.0
	visual.add_child(light)

	root.collision_layer = 8
	root.collision_mask = 2
	_save(root, "res://scenes/Projectile.tscn")

# ------------------------------------------------------------------ data file
func _build_data_file() -> void:
	var root := Area3D.new()
	root.name = "DataFile"
	root.set_script(load("res://scripts/DataFile.gd"))

	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var sph := SphereShape3D.new()
	sph.radius = 1.0
	col.shape = sph
	col.position = Vector3(0, 1.15, 0)
	root.add_child(col)

	var visual := Node3D.new()
	visual.name = "Visual"
	visual.position = Vector3(0, 1.15, 0)
	root.add_child(visual)
	_box(visual, "Tablet", Vector3(0.42, 0.54, 0.06), Vector3.ZERO, "steel")
	_box(visual, "Screen", Vector3(0.34, 0.44, 0.02), Vector3(0, 0, 0.05), "cyan")
	_box(visual, "Bar", Vector3(0.36, 0.05, 0.03), Vector3(0, -0.12, 0.07), "cyan_dim")

	var beacon := Node3D.new()
	beacon.name = "Beacon"
	root.add_child(beacon)
	_cyl(beacon, "Beam", 0.07, 3.4, Vector3(0, 1.7, 0), "cyan_dim")
	var bl := OmniLight3D.new()
	bl.name = "BeaconLight"
	bl.light_color = Color(0.2, 0.9, 1.0)
	bl.light_energy = 2.5
	bl.omni_range = 8.0
	bl.position = Vector3(0, 1.6, 0)
	beacon.add_child(bl)

	var label := Label3D.new()
	label.name = "Label"
	label.text = "ARCHIVO"
	label.font_size = 48
	label.pixel_size = 0.006
	label.position = Vector3(0, 2.15, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = Color(0.5, 1.0, 0.9)
	root.add_child(label)

	root.collision_layer = 16
	root.collision_mask = 2
	_save(root, "res://scenes/DataFile.tscn")

# ------------------------------------------------------------------ terminal
func _build_terminal() -> void:
	var root := Area3D.new()
	root.name = "Terminal"
	root.set_script(load("res://scripts/PuzzleTerminal.gd"))

	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = Vector3(3.0, 2.4, 2.0)
	col.shape = box
	col.position = Vector3(0, 1.2, 0)
	root.add_child(col)

	var body := StaticBody3D.new()
	body.name = "Body"
	body.collision_layer = 1
	body.collision_mask = 0
	root.add_child(body)
	var bcol := CollisionShape3D.new()
	bcol.name = "BodyShape"
	var bbox := BoxShape3D.new()
	bbox.size = Vector3(2.6, 2.4, 1.4)
	bcol.shape = bbox
	bcol.position = Vector3(0, 1.2, 0)
	body.add_child(bcol)

	_box(root, "Frame", Vector3(2.8, 2.2, 1.2), Vector3(0, 1.2, 0), "dark")
	_box(root, "Console", Vector3(2.4, 0.9, 0.9), Vector3(0, 0.45, 0.25), "steel")
	_box(root, "Screen", Vector3(2.0, 1.1, 0.12), Vector3(0, 1.55, 0.62), "cyan")
	var light := OmniLight3D.new()
	light.name = "ScreenLight"
	light.light_color = Color(0.2, 0.9, 1.0)
	light.light_energy = 3.5
	light.omni_range = 8.0
	light.position = Vector3(0, 1.6, 1.0)
	root.add_child(light)

	var label := Label3D.new()
	label.name = "Label"
	label.text = "TERMINAL"
	label.font_size = 44
	label.pixel_size = 0.005
	label.position = Vector3(0, 2.85, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = Color(0.4, 0.9, 1.0)
	root.add_child(label)

	root.collision_layer = 32
	root.collision_mask = 2
	_save(root, "res://scenes/Terminal.tscn")

# ------------------------------------------------------------------ pickup
func _build_pickup() -> void:
	var root := Area3D.new()
	root.name = "Pickup"
	root.set_script(load("res://scripts/Pickup.gd"))

	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var sph := SphereShape3D.new()
	sph.radius = 0.8
	col.shape = sph
	col.position = Vector3(0, 0.55, 0)
	root.add_child(col)

	var visual := Node3D.new()
	visual.name = "Visual"
	visual.position = Vector3(0, 0.55, 0)
	root.add_child(visual)
	_box(visual, "Crate", Vector3(0.6, 0.44, 0.44), Vector3.ZERO, "steel")
	_box(visual, "Glow", Vector3(0.5, 0.12, 0.46), Vector3(0, 0.12, 0), "cyan")
	var light := OmniLight3D.new()
	light.name = "PickupLight"
	light.light_color = Color(0.3, 1.0, 0.5)
	light.light_energy = 2.2
	light.omni_range = 5.0
	visual.add_child(light)

	root.collision_layer = 16
	root.collision_mask = 2
	_save(root, "res://scenes/Pickup.tscn")

# ------------------------------------------------------------------ boss
func _build_boss() -> void:
	var root := Node3D.new()
	root.name = "AnalyticalMachine"
	root.set_script(load("res://scripts/AnalyticalMachine.gd"))
	_save(root, "res://scenes/AnalyticalMachine.tscn")

# ------------------------------------------------------------------ hud
func _label(parent: Control, n: String, text: String, pos: Vector2, size: int, color: Color) -> Label:
	var l := Label.new()
	l.name = n
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(l)
	return l

func _build_hud() -> void:
	var root := CanvasLayer.new()
	root.name = "HUD"
	root.set_script(load("res://scripts/HUD.gd"))

	var ui := Control.new()
	ui.name = "Root"
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(ui)

	var top_left := Control.new()
	top_left.name = "TopLeft"
	top_left.position = Vector2(26, 20)
	top_left.size = Vector2(420, 100)
	top_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(top_left)
	_label(top_left, "Level", "NIVEL 1", Vector2(0, 0), 26, Color(0.55, 0.9, 1.0))
	_label(top_left, "Resolutions", "RESOLUCIONES  0 / 6", Vector2(0, 32), 22, Color(0.4, 1.0, 0.85))
	_label(top_left, "Files", "ARCHIVOS  0 / 0", Vector2(0, 60), 22, Color(0.85, 0.95, 1.0))

	var top_right := Control.new()
	top_right.name = "TopRight"
	top_right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_right.position = Vector2(-300, 20)
	top_right.size = Vector2(280, 110)
	top_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(top_right)
	_label(top_right, "HealthLabel", "INTEGRIDAD  100", Vector2(0, 0), 20, Color(0.5, 1.0, 0.65))
	var hbar := ProgressBar.new()
	hbar.name = "HealthBar"
	hbar.position = Vector2(0, 26)
	hbar.size = Vector2(270, 20)
	hbar.max_value = 100.0
	hbar.value = 100.0
	hbar.show_percentage = false
	hbar.add_theme_stylebox_override("background", _sb(Color(0.06, 0.08, 0.1, 0.85), Color(0.1, 0.35, 0.2)))
	hbar.add_theme_stylebox_override("fill", _sb(Color(0.25, 0.9, 0.5, 0.95), Color(0.1, 0.35, 0.2)))
	top_right.add_child(hbar)
	_label(top_right, "Ammo", "BALAS  12 / 60", Vector2(0, 56), 20, Color(1.0, 0.85, 0.4))

	var bottom := Control.new()
	bottom.name = "Bottom"
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.position = Vector2(0, -64)
	bottom.size = Vector2(0, 44)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(bottom)
	var obj := _label(bottom, "Objective", "", Vector2(0, 8), 20, Color(0.75, 0.95, 1.0))
	obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	obj.size = Vector2(1600, 30)
	obj.position = Vector2(0, 8)

	var center := Control.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.position = Vector2(-160, -120)
	center.size = Vector2(320, 240)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(center)

	var crosshair := Control.new()
	crosshair.name = "Crosshair"
	crosshair.position = Vector2(152, 112)
	crosshair.size = Vector2(16, 16)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(crosshair)
	for r in [
		Rect2(7, 0, 2, 6), Rect2(7, 10, 2, 6),
		Rect2(0, 7, 6, 2), Rect2(10, 7, 6, 2),
	]:
		var cr := ColorRect.new()
		cr.color = Color(0.6, 0.95, 1.0, 0.85)
		cr.position = r.position
		cr.size = r.size
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		crosshair.add_child(cr)

	var prompt := _label(center, "Prompt", "", Vector2(0, 170), 20, Color(1.0, 0.9, 0.5))
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.size = Vector2(320, 28)
	prompt.visible = false

	var hit := _label(center, "HitMarker", "X", Vector2(146, 100), 22, Color(1.0, 0.4, 0.35))
	hit.modulate.a = 0.0

	var message := _label(ui, "Message", "", Vector2(0, 96), 24, Color(1, 1, 1))
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.size = Vector2(1600, 40)
	message.position = Vector2(0, 96)
	message.modulate.a = 0.0

	var boss := Control.new()
	boss.name = "Boss"
	boss.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss.position = Vector2(-320, 26)
	boss.size = Vector2(640, 60)
	boss.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(boss)
	var bl := _label(boss, "BossLabel", "MÁQUINA ANALÍTICA", Vector2(0, 0), 22, Color(1.0, 0.4, 0.35))
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bl.size = Vector2(640, 26)
	var bbar := ProgressBar.new()
	bbar.name = "BossBar"
	bbar.position = Vector2(0, 30)
	bbar.size = Vector2(640, 18)
	bbar.max_value = 600.0
	bbar.value = 600.0
	bbar.show_percentage = false
	bbar.add_theme_stylebox_override("background", _sb(Color(0.08, 0.05, 0.05, 0.9), Color(0.3, 0.08, 0.08)))
	bbar.add_theme_stylebox_override("fill", _sb(Color(0.9, 0.2, 0.2, 0.95), Color(0.3, 0.08, 0.08)))
	boss.add_child(bbar)

	_save(root, "res://scenes/HUD.tscn")

func _sb(col: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.border_color = border
	sb.set_border_width_all(1)
	return sb
