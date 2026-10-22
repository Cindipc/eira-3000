extends Node

const BUILDERS := {
	"gameplay": "res://tools/build_gameplay.gd",
	"level1": "res://tools/build_level1.gd",
	"level2": "res://tools/build_level2.gd",
	"level3": "res://tools/build_level3.gd",
}

const TOOLS := {
	"verify": "res://tools/verify_gameplay.gd",
	"shots": "res://tools/screenshot.gd",
	"probe": "res://tools/probe_terminal.gd",
	"city": "res://tools/shot_city.gd",
	"level2shots": "res://tools/shot_level2.gd",
	"level2probe": "res://tools/probe_level2.gd",
	"analyze": "res://tools/analyze_shots.gd",
	"flow": "res://tools/probe_level1_flow.gd",
	"collect": "res://tools/probe_collect.gd",
	"androidshot": "res://tools/probe_android_shot.gd",
	"files": "res://tools/probe_files.gd",
	"walk": "res://tools/probe_walk.gd",
	"tree": "res://tools/probe_tree.gd",
	"novashot": "res://tools/shot_nova.gd",
	"fps": "res://tools/probe_fps.gd",
	"intro": "res://tools/probe_intro.gd",
	"hud": "res://tools/probe_hud.gd",
	"kael": "res://tools/probe_kael.gd",
	"citybounds": "res://tools/probe_city_bounds.gd",
	"level3probe": "res://tools/probe_level3.gd",
	"level3shots": "res://tools/shot_level3.gd",
	"l3flow": "res://tools/probe_l3_flow.gd",
	"chain": "res://tools/probe_chain.gd",
	"l1": "res://tools/probe_l1.gd",
	"l1b": "res://tools/probe_l1b.gd",
	"l1c": "res://tools/probe_l1c.gd",
	"l2": "res://tools/probe_l2.gd",
	"l1flow": "res://tools/probe_level1_flow.gd",
	"l1real": "res://tools/probe_l1_real.gd",
	"charshot": "res://tools/shot_character.gd",
}

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var target := ""
	var config := {}
	for a in args:
		if a.begins_with("--build="):
			target = a.substr(8)
		elif a.begins_with("--tool="):
			target = a.substr(7)
		elif a.begins_with("--"):
			var kv := a.substr(2).split("=", true)
			if kv.size() == 2:
				config[kv[0]] = kv[1]
	if target == "":
		return
	var guard := get_tree().create_timer(900.0)
	guard.timeout.connect(func() -> void:
		push_error("tiempo de build agotado")
		get_tree().quit())
	if TOOLS.has(target):
		var tool_path: String = TOOLS[target]
		print("[BuildRunner] running tool %s" % tool_path)
		await get_tree().process_frame
		var tool_script: GDScript = load(tool_path)
		if tool_script == null or not tool_script.can_instantiate():
			push_error("no se pudo cargar " + tool_path)
			get_tree().quit()
			return
		var tool: Object = tool_script.new()
		if tool == null:
			push_error("no se pudo instanciar " + tool_path)
			get_tree().quit()
			return
		if tool.has_method("configure"):
			tool.call("configure", config)
		await tool.run(Engine.get_main_loop() as SceneTree)
		print("[BuildRunner] tool done")
		get_tree().quit()
		return
	var list: Array[String] = []
	if target == "all":
		list = ["gameplay", "level1", "level2"]
	else:
		list = [target]
	for name in list:
		var path: String = BUILDERS.get(name, "")
		if path == "":
			push_error("unknown builder: " + name)
			continue
		print("[BuildRunner] running %s" % path)
		var script: GDScript = load(path)
		var builder: Object = script.new()
		builder.build()
	print("[BuildRunner] done")
	get_tree().quit()
