extends RefCounted

var tree: SceneTree
var config := {}

func configure(cfg: Dictionary) -> void:
	config = cfg

func run(p_tree: SceneTree) -> void:
	tree = p_tree
	var dir := DirAccess.open("res://screenshots")
	if dir == null:
		push_error("no hay carpeta de capturas")
		tree.quit()
		return
	var names: Array[String] = []
	for f in dir.get_files():
		if f.ends_with(".png"):
			names.append(f)
	names.sort()
	for f in names:
		_analyze("res://screenshots/%s" % f)
	tree.quit()

func _analyze(path: String) -> void:
	var img := Image.load_from_file(path)
	if img == null:
		print("%s: no se pudo cargar" % path)
		return
	var w := img.get_width()
	var h := img.get_height()
	var lum := 0.0
	var dark := 0.0
	var bright := 0.0
	var neon := 0.0
	var samples := 0
	var rows: Array[float] = []
	rows.resize(8)
	var row_n: Array[int] = []
	row_n.resize(8)
	for y in range(0, h, 2):
		var band: int = int(float(y) / float(h) * 8.0)
		for x in range(0, w, 2):
			var c := img.get_pixel(x, y)
			var l := 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
			lum += l
			rows[band] += l
			row_n[band] += 1
			samples += 1
			if l < 0.05:
				dark += 1.0
			elif l > 0.6:
				bright += 1.0
			var mx := maxf(c.r, maxf(c.g, c.b))
			var mn := minf(c.r, minf(c.g, c.b))
			if mx > 0.45 and (mx - mn) / maxf(0.001, mx) > 0.55:
				neon += 1.0
	var n := maxf(1.0, float(samples))
	print("%s %dx%d lum=%.3f oscuro=%.1f%% brillo=%.1f%% neon=%.1f%%" % [
		path.get_file(), w, h, lum / n, dark / n * 100.0, bright / n * 100.0, neon / n * 100.0])
	var line := "  perfil vertical (0=top): "
	for i in 8:
		line += "%.2f " % (rows[i] / maxf(1.0, float(row_n[i])))
	print(line)
	if path.get_file().begins_with("l2_") or path.get_file().begins_with("l3_"):
		_grid(img)

func _grid(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	print("  rejilla 6x4 (lum/sat):")
	for gy in 4:
		var line := "    "
		for gx in 6:
			var lum := 0.0
			var sat := 0.0
			var n := 0
			for y in range(gy * h / 4, (gy + 1) * h / 4, 3):
				for x in range(gx * w / 6, (gx + 1) * w / 6, 3):
					var c := img.get_pixel(x, y)
					var mx := maxf(c.r, maxf(c.g, c.b))
					var mn := minf(c.r, minf(c.g, c.b))
					lum += 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
					sat += (mx - mn) / maxf(0.001, mx)
					n += 1
			line += "%.2f/%.2f " % [lum / maxf(1.0, float(n)), sat / maxf(1.0, float(n))]
		print(line)
