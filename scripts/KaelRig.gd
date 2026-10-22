extends Node3D

## Animacion procedural de Kael.
##
## El modelo importado (assets/characters/kael.fbx) solo trae un clip de
## caminata, asi que las poses se escriben a mano sobre el esqueleto
## mixamorig: reposo, caminar, golpear, encajar un impacto, arrodillarse y
## caer. No depende de ningun AnimationPlayer, solo del Skeleton3D.

enum State { IDLE, WALK, ATTACK, HIT, KNEEL, FALL }

const NORMALIZE_STRIP := ["mixamorig:", "mixamorig_", "mixamorig", ":", "_", " ", "-"]

const BONE_KEYS := {
	"hips": "hips",
	"spine": "spine",
	"spine1": "spine1",
	"spine2": "spine2",
	"neck": "neck",
	"head": "head",
	"leftshoulder": "leftshoulder",
	"leftarm": "leftarm",
	"leftforearm": "leftforearm",
	"rightshoulder": "rightshoulder",
	"rightarm": "rightarm",
	"rightforearm": "rightforearm",
	"leftupleg": "leftupleg",
	"leftleg": "leftleg",
	"leftfoot": "leftfoot",
	"rightupleg": "rightupleg",
	"rightleg": "rightleg",
	"rightfoot": "rightfoot",
}

var state: int = State.IDLE
var speed := 0.0
var _t := 0.0
var _attack_t := 0.0
var _hit_t := 0.0
var _skeleton: Skeleton3D = null
var _bones := {}
var _rest_rot := {}
var _rest_pos := {}
var _fall_t := 0.0
var _base_y := 0.0

func _ready() -> void:
	_base_y = position.y
	var scope: Node = self
	while scope != null:
		var found := _find_skeleton(scope)
		if found != null:
			_skeleton = found
			break
		scope = scope.get_parent()
	if _skeleton == null:
		return
	_stop_animations(scope)
	for i in _skeleton.get_bone_count():
		var raw := String(_skeleton.get_bone_name(i))
		var key := _normalize(raw)
		_rest_rot[i] = _skeleton.get_bone_pose_rotation(i)
		_rest_pos[i] = _skeleton.get_bone_pose_position(i)
		if BONE_KEYS.has(key):
			_bones[BONE_KEYS[key]] = i

func _stop_animations(node: Node) -> void:
	for c in node.get_children():
		if c is AnimationPlayer:
			var ap := c as AnimationPlayer
			ap.stop()
			ap.active = false
		_stop_animations(c)

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for c in node.get_children():
		var found := _find_skeleton(c)
		if found != null:
			return found
	return null

func _normalize(raw: String) -> String:
	var s := raw.to_lower()
	for token in NORMALIZE_STRIP:
		s = s.replace(token, "")
	return s

func has_bones() -> bool:
	return _skeleton != null and not _bones.is_empty()

func set_state(new_state: int) -> void:
	if state == new_state:
		return
	if new_state == State.ATTACK:
		_attack_t = 0.0
	if new_state == State.HIT:
		_hit_t = 0.0
	if new_state == State.FALL:
		_fall_t = 0.0
	state = new_state

func _process(delta: float) -> void:
	_t += delta
	if _attack_t > 0.0:
		_attack_t += delta
	if _hit_t > 0.0:
		_hit_t = maxf(0.0, _hit_t - delta * 2.0)
	if _fall_t > 0.0:
		_fall_t += delta
	if _skeleton == null or _bones.is_empty():
		_body_only(delta)
		return
	match state:
		State.IDLE:
			_pose_idle()
		State.WALK:
			_pose_walk()
		State.ATTACK:
			_pose_attack()
		State.HIT:
			_pose_hit()
		State.KNEEL:
			_pose_kneel()
		State.FALL:
			_pose_fall()

# ------------------------------------------------------------------ poses
func _pose_idle() -> void:
	var breath := sin(_t * 1.7)
	var sway := sin(_t * 0.8)
	_offset("spine", Quaternion(Vector3.RIGHT, breath * 0.035))
	_offset("spine1", Quaternion(Vector3.RIGHT, breath * 0.025))
	_offset("neck", Quaternion(Vector3.UP, sway * 0.12))
	_offset("head", Quaternion(Vector3.UP, sway * 0.16))
	_offset("head", Quaternion(Vector3.RIGHT, breath * 0.05))
	_arm_sway(-1.0)
	_arm_sway(1.0)
	_offset("leftupleg", Quaternion(Vector3.RIGHT, 0.02))
	_offset("rightupleg", Quaternion(Vector3.RIGHT, -0.02))
	_hips_bob(breath * 0.012)

func _pose_walk() -> void:
	var phase := _t * 5.2
	var swing := sin(phase)
	var breath := sin(_t * 1.7)
	_offset("leftupleg", Quaternion(Vector3.RIGHT, swing * 0.62))
	_offset("rightupleg", Quaternion(Vector3.RIGHT, -swing * 0.62))
	_offset("leftleg", Quaternion(Vector3.RIGHT, maxf(0.0, -swing) * 0.85))
	_offset("rightleg", Quaternion(Vector3.RIGHT, maxf(0.0, swing) * 0.85))
	_offset("leftfoot", Quaternion(Vector3.RIGHT, maxf(0.0, -swing) * 0.3))
	_offset("rightfoot", Quaternion(Vector3.RIGHT, maxf(0.0, swing) * 0.3))
	_arm_sway(swing)
	_offset("spine", Quaternion(Vector3.RIGHT, 0.06 + breath * 0.03))
	_offset("spine1", Quaternion(Vector3.UP, -swing * 0.08))
	_offset("head", Quaternion(Vector3.UP, sin(_t * 0.9) * 0.08))
	_hips_bob(absf(sin(phase)) * 0.05)

func _pose_attack() -> void:
	## 0.0-0.18 carga, 0.18-0.42 golpe, 0.42-0.8 recuperación
	var t := _attack_t
	var swing := 0.0
	if t < 0.18:
		swing = lerpf(0.0, -1.35, t / 0.18)
	elif t < 0.42:
		swing = lerpf(-1.35, 1.25, (t - 0.18) / 0.24)
	else:
		swing = lerpf(1.25, 0.0, clampf((t - 0.42) / 0.38, 0.0, 1.0))
	_offset("rightarm", Quaternion(Vector3.RIGHT, swing))
	_offset("rightforearm", Quaternion(Vector3.RIGHT, maxf(0.0, swing) * 0.35))
	_offset("rightshoulder", Quaternion(Vector3.RIGHT, swing * 0.35))
	_offset("spine", Quaternion(Vector3.RIGHT, -swing * 0.22))
	_offset("spine1", Quaternion(Vector3.UP, -swing * 0.18))
	_offset("leftarm", Quaternion(Vector3.RIGHT, 0.25))
	_offset("leftupleg", Quaternion(Vector3.RIGHT, -0.12))
	_offset("rightupleg", Quaternion(Vector3.RIGHT, 0.18))
	_hips_bob(0.0)

func _pose_hit() -> void:
	var amount := clampf(_hit_t, 0.0, 1.0)
	_offset("spine", Quaternion(Vector3.RIGHT, -0.35 * amount))
	_offset("spine1", Quaternion(Vector3.RIGHT, -0.2 * amount))
	_offset("head", Quaternion(Vector3.RIGHT, -0.3 * amount))
	_offset("leftarm", Quaternion(Vector3.RIGHT, -0.5 * amount))
	_offset("rightarm", Quaternion(Vector3.RIGHT, -0.5 * amount))
	_hips_bob(-0.04 * amount)

func _pose_kneel() -> void:
	var breath := sin(_t * 1.2)
	_offset("hips", Quaternion(Vector3.RIGHT, 0.12))
	_move_bone("hips", Vector3(0, -0.55, -0.05))
	_offset("leftupleg", Quaternion(Vector3.RIGHT, -1.15))
	_offset("rightupleg", Quaternion(Vector3.RIGHT, -1.05))
	_offset("leftleg", Quaternion(Vector3.RIGHT, 1.45))
	_offset("rightleg", Quaternion(Vector3.RIGHT, 1.35))
	_offset("spine", Quaternion(Vector3.RIGHT, 0.22 + breath * 0.02))
	_offset("head", Quaternion(Vector3.RIGHT, 0.28))
	_offset("leftarm", Quaternion(Vector3.RIGHT, 0.35))
	_offset("rightarm", Quaternion(Vector3.RIGHT, 0.25))

func _pose_fall() -> void:
	var amount := clampf(_fall_t / 1.1, 0.0, 1.0)
	var fall := Quaternion(Vector3.FORWARD, amount * 1.45)
	_offset("spine", fall)
	_offset("spine1", Quaternion(Vector3.RIGHT, -0.2 * amount))
	_offset("head", Quaternion(Vector3.RIGHT, 0.35 * amount))
	_offset("leftarm", Quaternion(Vector3.RIGHT, -0.9 * amount))
	_offset("rightarm", Quaternion(Vector3.RIGHT, -0.7 * amount))
	_offset("leftupleg", Quaternion(Vector3.RIGHT, 0.4 * amount))
	_offset("rightupleg", Quaternion(Vector3.RIGHT, 0.2 * amount))
	_move_bone("hips", Vector3(0, -0.65 * amount, -0.1 * amount))

func _arm_sway(amount: float) -> void:
	_offset("leftarm", Quaternion(Vector3.RIGHT, 0.18 + amount * 0.12))
	_offset("rightarm", Quaternion(Vector3.RIGHT, 0.18 - amount * 0.12))
	_offset("leftforearm", Quaternion(Vector3.RIGHT, -0.25))
	_offset("rightforearm", Quaternion(Vector3.RIGHT, -0.25))

func _hips_bob(amount: float) -> void:
	_move_bone("hips", Vector3(0, amount, 0))

func _body_only(delta: float) -> void:
	## Sin esqueleto: se mueve el modelo entero (respaldo para FBX sin huesos).
	var breath := sin(_t * 1.7)
	match state:
		State.WALK:
			position.y = _base_y + absf(sin(_t * 5.2)) * 0.06
			rotation.z = sin(_t * 5.2) * 0.06
		State.ATTACK:
			position.y = _base_y
			rotation.x = -0.25 * sin(clampf(_attack_t / 0.4, 0.0, 1.0) * PI)
		State.FALL:
			rotation.z = clampf(_fall_t, 0.0, 1.2)
		_:
			position.y = _base_y + breath * 0.02
			rotation.z = 0.0

# ------------------------------------------------------------------ helpers
func _offset(key: String, extra: Quaternion) -> void:
	if not _bones.has(key):
		return
	var idx: int = _bones[key]
	var rest: Quaternion = _rest_rot.get(idx, Quaternion.IDENTITY)
	_skeleton.set_bone_pose_rotation(idx, rest * extra)

func _move_bone(key: String, delta_pos: Vector3) -> void:
	if not _bones.has(key):
		return
	var idx: int = _bones[key]
	var rest: Vector3 = _rest_pos.get(idx, Vector3.ZERO)
	_skeleton.set_bone_pose_position(idx, rest + delta_pos)
