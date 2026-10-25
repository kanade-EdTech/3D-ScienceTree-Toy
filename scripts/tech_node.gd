extends Node3D
class_name TechNode

signal node_clicked(node: TechNode)
signal node_hovered(node: TechNode, is_hovering: bool)

@export var tech_id: String = ""
@export var tech_name: String = ""
@export var tech_cost: int = 5
@export var tier: int = 0
@export var domain_color: Color = Color.WHITE

var is_unlocked: bool = false
var is_available: bool = false
var prerequisites: Array[String] = []

@onready var label_3d: Label3D = $Label3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var area_3d: Area3D = $Area3D

# 模型和光晕
var model_container: Node3D = null
var model_loaded: bool = false
var glow_light: OmniLight3D = null
var glow_halo: MeshInstance3D = null
var halo_material: StandardMaterial3D
static var halo_texture: GradientTexture2D
var model_materials: Array[Dictionary] = []
var unlock_tween: Tween
const MODEL_SIZE = 1.0
const PULSE_SCALE = 1.3

# Tier 0的模型映射
var tier_0_models = {
	"astronomy_nav": "res://assets/models/poly_pizza/astronomy_nav.glb",
	"surveying_ballistics": "res://assets/models/poly_pizza/surveying_ballistics.glb",
	"alchemy_metallurgy": "res://assets/models/poly_pizza/alchemy_metallurgy.glb",
	"anatomy_natural_history": "res://assets/models/poly_pizza/anatomy_natural_history.glb"
}

# Tier 1的模型映射
var tier_1_models = {
	"analytic_geometry_calculus": "res://assets/models/poly_pizza/analytic_geometry_calculus.glb",
	"geometric_optics": "res://assets/models/poly_pizza/geometric_optics.glb",
	"classical_mechanics": "res://assets/models/poly_pizza/classical_mechanics.glb",
	"pneumatic_chemistry": "res://assets/models/poly_pizza/pneumatic_chemistry.glb",
	"physiology_circulation": "res://assets/models/poly_pizza/physiology_circulation.glb",
	"microscopic_anatomy": "res://assets/models/poly_pizza/microscopic_anatomy.glb"
}

# Tier 2的模型映射
var tier_2_models = {
	"analytical_fluid_mechanics": "res://assets/models/poly_pizza/analytical_fluid_mechanics.glb",
	"thermodynamics_stat_mech": "res://assets/models/poly_pizza/thermodynamics_stat_mech.glb",
	"electromagnetism": "res://assets/models/poly_pizza/electromagnetism.glb",
	"quantitative_chemistry": "res://assets/models/poly_pizza/quantitative_chemistry.glb",
	"organic_periodic_chemistry": "res://assets/models/poly_pizza/organic_periodic_chemistry.glb",
	"geology_paleontology": "res://assets/models/poly_pizza/geology_paleontology.glb",
	"cell_microbiology_evolution": "res://assets/models/poly_pizza/cell_microbiology_evolution.glb"
}

# Tier 3的模型映射
var tier_3_models = {
	"probability_statistics_topology": "res://assets/models/poly_pizza/probability_statistics_topology.glb",
	"relativity": "res://assets/models/poly_pizza/relativity.glb",
	"quantum_nuclear_physics": "res://assets/models/poly_pizza/quantum_nuclear_physics.glb",
	"solid_state_semiconductor": "res://assets/models/poly_pizza/solid_state_semiconductor.glb",
	"physical_quantum_chemistry": "res://assets/models/poly_pizza/physical_quantum_chemistry.glb",
	"polymer_materials_science": "res://assets/models/poly_pizza/polymer_materials_science.glb",
	"genetics_biochemistry": "res://assets/models/poly_pizza/genetics_biochemistry.glb",
	"molecular_biology": "res://assets/models/poly_pizza/molecular_biology.glb",
	"electronics_cybernetics_info": "res://assets/models/poly_pizza/electronics_cybernetics_info.glb"
}

# Tier 4的模型映射
var tier_4_models = {
	"astrophysics_cosmology": "res://assets/models/poly_pizza/astrophysics_cosmology.glb",
	"computer_science_ai": "res://assets/models/poly_pizza/computer_science_ai.glb",
	"genomics_synthetic_bio": "res://assets/models/poly_pizza/genomics_synthetic_bio.glb",
	"cognitive_neuroscience": "res://assets/models/poly_pizza/cognitive_neuroscience.glb",
	"earth_system_climate": "res://assets/models/poly_pizza/earth_system_climate.glb",
	"nanotech_quantum_info": "res://assets/models/poly_pizza/nanotech_quantum_info.glb"
}

func _ready():
	setup_visuals()
	create_glow_light()

	# 加载 Tier 0–4 的全部节点模型。
	var model_path = get_model_path()
	if model_path:
		load_model(model_path)
	update_visual_state()

	# Connect signals
	if area_3d:
		area_3d.mouse_entered.connect(_on_mouse_entered)
		area_3d.mouse_exited.connect(_on_mouse_exited)

func get_model_path() -> String:
	if tier == 0 and tech_id in tier_0_models:
		return tier_0_models[tech_id]
	elif tier == 1 and tech_id in tier_1_models:
		return tier_1_models[tech_id]
	elif tier == 2 and tech_id in tier_2_models:
		return tier_2_models[tech_id]
	elif tier == 3 and tech_id in tier_3_models:
		return tier_3_models[tech_id]
	elif tier == 4 and tech_id in tier_4_models:
		return tier_4_models[tech_id]
	return ""

func setup_visuals():
	# Setup label
	if label_3d:
		label_3d.text = tech_name
		label_3d.modulate = domain_color
		label_3d.pixel_size = 0.008
		label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label_3d.outline_size = 8
		label_3d.outline_modulate = Color(0, 0, 0, 1)

	# Setup mesh material（如果没有模型则使用球体）
	if mesh_instance:
		var material = StandardMaterial3D.new()
		material.albedo_color = domain_color
		material.emission_enabled = true
		material.emission = domain_color * 0.3
		mesh_instance.set_surface_override_material(0, material)

func create_glow_light():
	# 创建光晕灯光
	glow_light = OmniLight3D.new()
	glow_light.name = "GlowLight"
	glow_light.light_energy = 0.0  # 初始关闭
	glow_light.omni_range = 6.0  # 增大范围（原来3.0）
	glow_light.light_color = Color.WHITE
	add_child(glow_light)

	# FogVolume requires Forward+. Use a soft billboard for desktop GL and Web.
	if halo_texture == null:
		var gradient = Gradient.new()
		gradient.set_color(0, Color(1, 1, 1, 0.7))
		gradient.set_color(1, Color(1, 1, 1, 0))
		gradient.add_point(0.4, Color(1, 1, 1, 0.18))
		halo_texture = GradientTexture2D.new()
		halo_texture.width = 128
		halo_texture.height = 128
		halo_texture.gradient = gradient
		halo_texture.fill = GradientTexture2D.FILL_RADIAL
		halo_texture.fill_from = Vector2(0.5, 0.5)
		halo_texture.fill_to = Vector2(0.5, 1.0)
	halo_material = StandardMaterial3D.new()
	halo_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	halo_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	halo_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	halo_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	halo_material.albedo_texture = halo_texture
	var quad = QuadMesh.new()
	quad.size = Vector2(3, 3)
	glow_halo = MeshInstance3D.new()
	glow_halo.name = "GlowHalo"
	glow_halo.mesh = quad
	glow_halo.material_override = halo_material
	glow_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	glow_halo.visible = false
	add_child(glow_halo)

func load_model(model_path: String):
	if not ResourceLoader.exists(model_path):
		print("模型不存在: ", model_path)
		return

	# 加载GLB模型
	var model_resource = ResourceLoader.load(model_path)
	if model_resource and model_resource is PackedScene:
		model_container = Node3D.new()
		model_container.name = "ModelContainer"
		add_child(model_container)
		# Keep normalization separate from the animated container scale.
		var geometry = Node3D.new()
		geometry.name = "ModelGeometry"
		model_container.add_child(geometry)
		var model_instance = model_resource.instantiate()
		geometry.add_child(model_instance)
		var bounds = AABB()
		var first = true
		for mesh in geometry.find_children("*", "MeshInstance3D", true, false):
			if mesh.mesh == null:
				continue
			var local_transform = geometry.global_transform.affine_inverse() * mesh.global_transform
			var box: AABB = local_transform * mesh.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
			for surface in range(mesh.mesh.get_surface_count()):
				var original = mesh.get_active_material(surface) as StandardMaterial3D
				if original:
					var material = original.duplicate() as StandardMaterial3D
					mesh.set_surface_override_material(surface, material)
					model_materials.append({"material":material, "color":material.albedo_color})
		if first or not bounds.size.is_finite() or bounds.get_longest_axis_size() <= 0:
			model_container.free()
			model_container = null
			model_materials.clear()
			return
		var factor = MODEL_SIZE / bounds.get_longest_axis_size()
		geometry.scale = Vector3.ONE * factor
		geometry.position = -bounds.get_center() * factor
		var collision = area_3d.get_node("CollisionShape3D") as CollisionShape3D
		var shape = BoxShape3D.new()
		var size = bounds.size * factor
		shape.size = Vector3(maxf(size.x, 0.12), maxf(size.y, 0.12), maxf(size.z, 0.12)) * PULSE_SCALE + Vector3.ONE * 0.12
		collision.shape = shape
		collision.position = Vector3.ZERO

		# 隐藏原始球体
		if mesh_instance:
			mesh_instance.visible = false

		model_loaded = true
		print("模型已加载: ", tech_id)

	else:
		print("无法加载模型资源: ", model_path)

func update_visual_state():
	if model_loaded:
		# Node3D has no modulate; tint per-instance materials without altering GLBs.
		for entry in model_materials:
			var material: StandardMaterial3D = entry.material
			var color: Color = entry.color
			var brightness = 1.0 if is_unlocked else (0.85 if is_available else 0.3)
			material.albedo_color = Color(color.r * brightness, color.g * brightness, color.b * brightness, color.a)
			material.emission_enabled = is_unlocked or is_available
			material.emission = Color(color.r, color.g, color.b) * (0.2 if is_unlocked else 0.1)
	else:
		# 对于球体
		if not mesh_instance:
			return

		var material = mesh_instance.get_surface_override_material(0) as StandardMaterial3D
		if not material:
			return

		if is_unlocked:
			material.albedo_color = domain_color
			material.emission = domain_color * 0.5
		elif is_available:
			material.albedo_color = domain_color * 0.7
			material.emission = domain_color * 0.3
		else:
			material.albedo_color = Color.DARK_GRAY
			material.emission = Color.BLACK

	if label_3d:
		label_3d.modulate = Color.WHITE if is_unlocked else (Color.YELLOW if is_available else Color.GRAY)

	# 更新光晕
	update_glow()

func update_glow():
	if not glow_light:
		return

	if is_unlocked:
		# 已解锁：深卡其色光晕
		glow_light.light_color = Color(0.76, 0.60, 0.30)  # 更深的卡其色
		glow_light.light_energy = 2.0  # 增强能量


	elif is_available:
		# 可解锁：深绿色光晕
		glow_light.light_color = Color(0.2, 0.8, 0.3)  # 更深的绿色
		glow_light.light_energy = 2.2  # 增强能量


	else:
		# 锁定：无光晕
		glow_light.light_energy = 0.0

	if glow_halo:
		glow_halo.visible = is_available or is_unlocked
		halo_material.albedo_color = Color(glow_light.light_color.r, glow_light.light_color.g, glow_light.light_color.b, 0.3)

func _on_mouse_entered():
	node_hovered.emit(self, true)

func _on_mouse_exited():
	node_hovered.emit(self, false)

func can_unlock(current_points: int) -> bool:
	return is_available and not is_unlocked and current_points >= tech_cost

func unlock():
	if not is_unlocked:
		is_unlocked = true
		update_visual_state()
		play_unlock_animation()

func play_unlock_animation():
	# 创建一个简单的脉冲动画
	if unlock_tween and unlock_tween.is_valid():
		unlock_tween.kill()
	var tween = create_tween()
	unlock_tween = tween
	if model_loaded and model_container:
		tween.set_parallel(true)
		tween.tween_property(model_container, "scale", Vector3.ONE * PULSE_SCALE, 0.3)
		tween.chain()
		tween.tween_property(model_container, "scale", Vector3(1.0, 1.0, 1.0), 0.3)
	elif mesh_instance:
		tween.set_parallel(true)
		tween.tween_property(mesh_instance, "scale", Vector3(1.5, 1.5, 1.5), 0.3)
		if label_3d:
			tween.tween_property(label_3d, "modulate:a", 0.0, 0.2).set_delay(0.1)
		tween.chain()
		tween.tween_property(mesh_instance, "scale", Vector3(1.0, 1.0, 1.0), 0.3)
		if label_3d:
			tween.tween_property(label_3d, "modulate:a", 1.0, 0.2)

func set_available(available: bool):
	is_available = available
	update_visual_state()
