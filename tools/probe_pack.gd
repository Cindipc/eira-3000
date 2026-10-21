extends SceneTree

func _initialize() -> void:
	var n := StaticBody3D.new()
	n.name = "BarrierTest"
	n.set_script(load("res://scripts/Barrier.gd"))
	n.set("required_resolutions", 3)
	print("value = ", n.get("required_resolutions"))
	n.add_to_group("barrier")
	var ps := PackedScene.new()
	var err := ps.pack(n)
	print("pack err ", err)
	print(var_to_str(ps))
	quit()
