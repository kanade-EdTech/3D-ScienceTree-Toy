extends Node3D
## 完全静态的彩色3D界面样片（仅展示 Tier 0 与 Tier 1 早两代科技）
## 审美风格：文艺复兴星盘黄铜（近代史） × 全息星图多面体（现代科技）

const BRASS_GOLD := Color(0.85, 0.70, 0.38, 1.0)
const BRASS_DARK := Color(0.46, 0.36, 0.18, 0.9)
const PARCHMENT_CREAM := Color(0.97, 0.93, 0.84, 1.0)

func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	_build_static_showcase()

func _build_static_showcase() -> void:
	var file := FileAccess.open("res://tech_tree.json", FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return
	var data: Dictionary = json.data

	var domain_colors := {}
	for d in data.get("domains", []):
		domain_colors[d.id] = Color(d.color)

	# 1. 构建背景文艺复兴天球仪星盘与子午刻度线
	_create_astrolabe_backdrop()

	# 2. 筛选早两代科技 (Tier 0: 4个节点, Tier 1: 6个节点)
	var early_nodes: Array = []
	for n in data.get("nodes", []):
		if int(n.tier) <= 1:
			early_nodes.append(n)

	# 精心编排的静态3D透视坐标（与右侧典籍卡片错位排布，左72%为3D星阵舞台，右28%为典籍检视区）
	var curated_positions := {
		# Tier 0: 15-16世纪 文艺复兴与经验先导 (左翼弧线)
		"astronomy_nav": Vector3(-7.4, 3.8, 0.6),
		"surveying_ballistics": Vector3(-7.8, 1.1, -0.3),
		"alchemy_metallurgy": Vector3(-7.8, -1.6, -0.3),
		"anatomy_natural_history": Vector3(-7.4, -4.3, 0.6),
		# Tier 1: 17世纪 第一次科学革命与工具基石 (中右翼双层星阵)
		"analytic_geometry_calculus": Vector3(-0.4, 4.4, -0.4),
		"geometric_optics": Vector3(2.8, 3.6, 0.8),
		"classical_mechanics": Vector3(1.6, 0.6, 1.6),
		"pneumatic_chemistry": Vector3(-0.5, -1.4, -0.3),
		"physiology_circulation": Vector3(-0.2, -4.0, 0.4),
		"microscopic_anatomy": Vector3(2.8, -4.4, 0.9)
	}

	var node_positions := {}
	var node_domains := {}

	for n in early_nodes:
		var pos: Vector3 = curated_positions.get(n.id, Vector3.ZERO)
		var col: Color = domain_colors.get(n.domain, Color.WHITE)
		node_positions[n.id] = pos
		node_domains[n.id] = col
		_create_ornate_tech_node(n, pos, col)

	# 3. 绘制 Tier 0 -> Tier 1 彩色3D能量导管与跨学科赋能金线
	for link in data.get("links", []):
		var src: String = link.source
		var dst: String = link.target
		if node_positions.has(src) and node_positions.has(dst):
			var p1: Vector3 = node_positions[src]
			var p2: Vector3 = node_positions[dst]
			var ltype: String = link.get("type", "core")
			var src_col: Color = node_domains[src]
			var dst_col: Color = node_domains[dst]
			_create_3d_beam(p1, p2, src_col, dst_col, ltype)

func _create_astrolabe_backdrop() -> void:
	var backdrop := Node3D.new()
	backdrop.name = "AstrolabeBackdrop"
	backdrop.position = Vector3(-2.6, -0.2, -4.2)
	add_child(backdrop)

	# 四道同心黄铜星盘环
	var radii := [4.2, 6.8, 9.6, 12.4]
	var tilts := [
		Vector3(6, 10, 0),
		Vector3(-5, -8, 12),
		Vector3(3, 4, -6),
		Vector3(0, 0, 0)
	]
	for i in range(radii.size()):
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = radii[i] - 0.035
		ring_mesh.outer_radius = radii[i] + 0.035
		ring_mesh.rings = 96
		ring_mesh.ring_segments = 16

		var ring_inst := MeshInstance3D.new()
		ring_inst.mesh = ring_mesh
		ring_inst.rotation_degrees = Vector3(90, 0, 0) + tilts[i]

		var mat := StandardMaterial3D.new()
		mat.albedo_color = BRASS_DARK
		mat.metallic = 0.85
		mat.roughness = 0.28
		mat.emission_enabled = true
		mat.emission = BRASS_GOLD * (0.24 - i * 0.04)
		ring_inst.set_surface_override_material(0, mat)
		backdrop.add_child(ring_inst)

	# 12道黄道星盘辐射经线
	var spoke_mat := StandardMaterial3D.new()
	spoke_mat.albedo_color = Color(0.75, 0.60, 0.30, 0.28)
	spoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spoke_mat.emission_enabled = true
	spoke_mat.emission = BRASS_GOLD * 0.15

	for deg in range(0, 180, 30):
		var spoke := CylinderMesh.new()
		spoke.top_radius = 0.015
		spoke.bottom_radius = 0.015
		spoke.height = 24.8
		var spoke_inst := MeshInstance3D.new()
		spoke_inst.mesh = spoke
		spoke_inst.rotation_degrees = Vector3(0, 0, deg)
		spoke_inst.set_surface_override_material(0, spoke_mat)
		backdrop.add_child(spoke_inst)

func _create_ornate_tech_node(node_data: Dictionary, pos: Vector3, domain_color: Color) -> void:
	var holder := Node3D.new()
	holder.name = node_data.id
	holder.position = pos
	add_child(holder)

	var is_flagship: bool = (node_data.id == "classical_mechanics")
	var core_radius: float = 0.66 if is_flagship else (0.52 if int(node_data.tier) == 0 else 0.46)

	# 1. 发光宝石级学科核心球体
	var core_mesh := SphereMesh.new()
	core_mesh.radius = core_radius
	core_mesh.height = core_radius * 2.0
	var core_inst := MeshInstance3D.new()
	core_inst.mesh = core_mesh

	var core_mat := StandardMaterial3D.new()
	core_mat.albedo_color = domain_color.lightened(0.18)
	core_mat.metallic = 0.3
	core_mat.roughness = 0.12
	core_mat.emission_enabled = true
	core_mat.emission = domain_color * (0.95 if is_flagship else 0.72)
	core_inst.set_surface_override_material(0, core_mat)
	holder.add_child(core_inst)

	# 2. 近代科学黄铜星盘外环 (Astrolabe Gimbal Ring)
	var gim_mesh := TorusMesh.new()
	gim_mesh.inner_radius = core_radius * 1.34
	gim_mesh.outer_radius = core_radius * 1.46
	gim_mesh.rings = 64
	gim_mesh.ring_segments = 16
	var gim_inst := MeshInstance3D.new()
	gim_inst.mesh = gim_mesh
	gim_inst.rotation_degrees = Vector3(68, 22, 18)

	var brass_mat := StandardMaterial3D.new()
	brass_mat.albedo_color = BRASS_GOLD
	brass_mat.metallic = 0.92
	brass_mat.roughness = 0.18
	brass_mat.emission_enabled = true
	brass_mat.emission = BRASS_GOLD * 0.35
	gim_inst.set_surface_override_material(0, brass_mat)
	holder.add_child(gim_inst)

	# Tier 1 节点增加正交全息光环；旗舰节点《经典力学与万有引力》增加三道天体运行轨道与伴星
	if int(node_data.tier) == 1:
		var inner_ring := TorusMesh.new()
		inner_ring.inner_radius = core_radius * 1.16
		inner_ring.outer_radius = core_radius * 1.22
		var inner_inst := MeshInstance3D.new()
		inner_inst.mesh = inner_ring
		inner_inst.rotation_degrees = Vector3(-38, 48, -22)
		var holo_mat := StandardMaterial3D.new()
		holo_mat.albedo_color = domain_color.lightened(0.38)
		holo_mat.emission_enabled = true
		holo_mat.emission = domain_color * 0.85
		inner_inst.set_surface_override_material(0, holo_mat)
		holder.add_child(inner_inst)

	if is_flagship:
		var orbit_mesh := TorusMesh.new()
		orbit_mesh.inner_radius = core_radius * 1.78
		orbit_mesh.outer_radius = core_radius * 1.84
		var orbit_inst := MeshInstance3D.new()
		orbit_inst.mesh = orbit_mesh
		orbit_inst.rotation_degrees = Vector3(74, -18, 12)
		orbit_inst.set_surface_override_material(0, brass_mat)
		holder.add_child(orbit_inst)

		# 伴星小球（象征月球/行星万有引力轨道）
		var moon_mesh := SphereMesh.new()
		moon_mesh.radius = 0.13
		moon_mesh.height = 0.26
		var moon_inst := MeshInstance3D.new()
		moon_inst.mesh = moon_mesh
		moon_inst.position = Vector3(core_radius * 1.75, 0.32, 0.25)
		moon_inst.set_surface_override_material(0, brass_mat)
		holder.add_child(moon_inst)

	# 3. 学科主标题 (羊皮卷暖白 + 深黑描边)
	var title_lbl := Label3D.new()
	title_lbl.position = Vector3(0, -core_radius - 0.42, 0.35)
	title_lbl.pixel_size = 0.0068
	title_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title_lbl.text = node_data.name
	title_lbl.font_size = 42 if is_flagship else 36
	title_lbl.modulate = PARCHMENT_CREAM
	title_lbl.outline_size = 10
	title_lbl.outline_modulate = Color(0.02, 0.03, 0.06, 0.98)
	holder.add_child(title_lbl)

	# 4. 近代史代表学者副标题
	var reps: Array = node_data.get("representatives", [])
	var subtitle_lbl := Label3D.new()
	subtitle_lbl.position = Vector3(0, -core_radius - 0.76, 0.35)
	subtitle_lbl.pixel_size = 0.0058
	subtitle_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	subtitle_lbl.text = " · ".join(reps)
	subtitle_lbl.font_size = 26
	subtitle_lbl.modulate = domain_color.lightened(0.42)
	subtitle_lbl.outline_size = 8
	subtitle_lbl.outline_modulate = Color(0.02, 0.03, 0.06, 0.98)
	holder.add_child(subtitle_lbl)

func _create_3d_beam(from: Vector3, to: Vector3, src_col: Color, dst_col: Color, link_type: String) -> void:
	var diff := to - from
	var dist := diff.length()
	if dist < 0.01:
		return

	var dir := diff.normalized()
	var up := Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.99 else Vector3.FORWARD
	var basis_z := dir.cross(up).normalized()
	var basis_x := basis_z.cross(dir).normalized()
	var rot_basis := Basis(basis_x, dir, basis_z)

	var is_core := (link_type == "core")
	var mat := StandardMaterial3D.new()
	var beam_col := src_col.lerp(dst_col, 0.45) if is_core else BRASS_GOLD.lightened(0.22)
	mat.albedo_color = Color(beam_col.r, beam_col.g, beam_col.b, 0.88 if is_core else 0.72)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = beam_col * (0.75 if is_core else 0.55)

	if is_core:
		# 核心学科继承：连续发光能量导管
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.042
		cyl.bottom_radius = 0.042
		cyl.height = dist
		cyl.radial_segments = 12

		var inst := MeshInstance3D.new()
		inst.mesh = cyl
		add_child(inst)
		inst.global_transform = Transform3D(rot_basis, (from + to) * 0.5)
		inst.set_surface_override_material(0, mat)
	else:
		# 跨界工具/方法论赋能：黄铜虚线脉冲光束
		var segments := int(clampf(dist * 2.2, 8.0, 24.0))
		var step := dist / float(segments)
		var seg_mesh := CylinderMesh.new()
		seg_mesh.top_radius = 0.024
		seg_mesh.bottom_radius = 0.024
		seg_mesh.height = step * 0.52
		seg_mesh.radial_segments = 8

		for i in range(segments):
			var t := (float(i) + 0.5) / float(segments)
			var seg_pos := from.lerp(to, t)
			var seg_inst := MeshInstance3D.new()
			seg_inst.mesh = seg_mesh
			add_child(seg_inst)
			seg_inst.global_transform = Transform3D(rot_basis, seg_pos)
			seg_inst.set_surface_override_material(0, mat)
