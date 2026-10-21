extends SceneTree

const CELL := 5.0
const X0 := -100.0
const X1 := 185.0
const Z0 := -150.0
const Z1 := 70.0

func _initialize() -> void:
	var ps: PackedScene = load("res://assets/levels/Futuristic_City.fbx")
	var n: Node = ps.instantiate()
	get_root().add_child(n)
	await process_frame
	var mi: MeshInstance3D = null
	var stack: Array[Node] = [n]
	while not stack.is_empty() and mi == null:
		var cur: Node = stack.pop_back()
		for c in cur.get_children():
			stack.append(c)
		if cur is MeshInstance3D:
			var cand := cur as MeshInstance3D
			if cand.mesh != null and String(cand.name).to_lower().contains("cube_251"):
				mi = cand
	var cols := int((X1 - X0) / CELL)
	var rows := int((Z1 - Z0) / CELL)
	var grid := PackedFloat32Array()
	grid.resize(cols * rows)
	grid.fill(-999.0)
	for s in mi.mesh.get_surface_count():
		var arrays := mi.mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var xf := _accumulate(mi, n)
		var tri_count := idx.size() / 3 if idx.size() > 0 else verts.size() / 3
		for t in tri_count:
			var a: Vector3
			var b: Vector3
			var c: Vector3
			if idx.size() > 0:
				a = xf * verts[idx[t * 3]]
				b = xf * verts[idx[t * 3 + 1]]
				c = xf * verts[idx[t * 3 + 2]]
			else:
				a = xf * verts[t * 3]
				b = xf * verts[t * 3 + 1]
				c = xf * verts[t * 3 + 2]
			var nrm := (b - a).cross(c - a)
			if absf(nrm.y) < 0.02 * maxf(nrm.length(), 0.001):
				continue
			nrm = nrm.normalized()
			if nrm.y < 0.9:
				continue
			var cy := (a.y + b.y + c.y) / 3.0
			var cx := (a.x + b.x + c.x) / 3.0
			var cz := (a.z + b.z + c.z) / 3.0
			var gx := int((cx - X0) / CELL)
			var gz := int((cz - Z0) / CELL)
			if gx < 0 or gz < 0 or gx >= cols or gz >= rows:
				continue
			var k := gz * cols + gx
			if cy > grid[k]:
				grid[k] = cy
	print("mapa de superficies planas (caracter = altura en metros, '.' = nada)")
	for gz in range(rows - 1, -1, -1):
		var line := ""
		for gx in cols:
			var v := grid[gz * cols + gx]
			if v < -900.0:
				line += "."
			elif v < 0.5:
				line += "0"
			elif v < 4.0:
				line += "1"
			elif v < 9.0:
				line += "2"
			elif v < 19.0:
				line += "3"
			elif v < 34.0:
				line += "4"
			elif v < 44.0:
				line += "5"
			else:
				line += "#"
		print(line)
	quit(0)

func _accumulate(node: Node, root: Node) -> Transform3D:
	var xform: Transform3D = (node as Node3D).transform
	var p := node.get_parent()
	while p != null and p != root:
		xform = (p as Node3D).transform * xform
		p = p.get_parent()
	return xform
