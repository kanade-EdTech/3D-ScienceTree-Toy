extends Node3D
class_name TechTreeManager

@export var tech_points: float = 0.0
@export var points_per_second: float = 1.0
@export var time_scale: float = 1.0

var tech_data: Dictionary = {}
var tech_nodes: Dictionary = {}
var tech_links: Array = []
var layout_adjustments: Dictionary = {}

@onready var ui_layer: CanvasLayer = $UILayer
@onready var points_label: Label = $UILayer/Control/VBoxContainer/PanelContainer/MarginContainer/InfoVBox/PointsLabel
@onready var speed_label: Label = $UILayer/Control/VBoxContainer/PanelContainer/MarginContainer/InfoVBox/SpeedLabel
@onready var unlocked_label: Label = $UILayer/Control/VBoxContainer/PanelContainer/MarginContainer/InfoVBox/UnlockedLabel
@onready var layout_label: Label = $UILayer/Control/VBoxContainer/PanelContainer/MarginContainer/InfoVBox/LayoutLabel
@onready var tooltip_ui = $UILayer/TooltipUI

const TIER_SPACING = 12.0  # 层间距离（横向模式沿X轴）
const TIER_RADIUS_BASE = 8.0  # 圆盘基础半径
const VERTICAL_TIER_SPACING = 15.0  # 纵向模式层间距

var unlocked_count: int = 0
var total_count: int = 0
var layout_tween: Tween

# Layout modes
enum LayoutMode { HORIZONTAL, VERTICAL }
var current_layout: LayoutMode = LayoutMode.VERTICAL  # 默认从上到下

signal tech_unlocked(tech_id: String)
signal layout_changed(new_layout: LayoutMode)

func _ready():
	load_tech_data()
	create_tech_tree()
	update_ui()

func _process(delta):
	# Accumulate tech points
	tech_points += points_per_second * time_scale * delta
	update_ui()

func load_tech_data():
	# 固定的小幅点位修正，避免重启时随机高度重新引入穿点连线。
	var layout_data = JSON.parse_string(FileAccess.get_file_as_string("res://tech_layout.json"))
	if layout_data is Dictionary:
		layout_adjustments = layout_data
	var file = FileAccess.open("res://tech_tree.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			tech_data = json.data
		else:
			print("Error parsing tech_tree.json: ", json.get_error_message())
	else:
		print("Could not open tech_tree.json")

# 计算圆盘布局的位置
func calculate_disc_position(tier: int, index: int, total_in_tier: int, layout: LayoutMode, height_variation: float = 0.0) -> Vector3:
	var angle_step = TAU / max(total_in_tier, 4)  # 至少按4个点分布
	var angle = angle_step * index

	# 根据层级计算半径（越高层半径越大，展现扩展感）
	var radius = TIER_RADIUS_BASE + tier * 2.0

	# 在圆盘上的X和Z位置
	var x_offset = cos(angle) * radius
	var z_offset = sin(angle) * radius

	# 添加随机高度变化，形成立体圆盘（不是平面）
	var y_variation = height_variation

	if layout == LayoutMode.HORIZONTAL:
		# 横向模式：圆盘沿X轴推进（时间轴）
		return Vector3(
			tier * TIER_SPACING,      # X轴：时间推进
			z_offset + y_variation,   # Y轴：圆盘上的分布
			x_offset                  # Z轴：圆盘深度
		)
	else:
		# 纵向模式：圆盘沿Y轴向下堆叠
		return Vector3(
			x_offset,                              # X轴：圆盘宽度
			-tier * VERTICAL_TIER_SPACING + y_variation,  # Y轴：向下堆叠
			z_offset                               # Z轴：圆盘深度
		)

func adjusted_disc_position(node: TechNode, index: int, count: int, layout: LayoutMode) -> Vector3:
	var base = calculate_disc_position(node.tier, index, count, layout, float(node.get_meta("disc_height_variation", 0.0)))
	var settings: Dictionary = layout_adjustments.get(node.tech_id, {})
	var direction = "vertical" if layout == LayoutMode.VERTICAL else "horizontal"
	var offset: Array = settings.get(direction, [0.0, 0.0, 0.0])
	return base + Vector3(float(offset[0]), float(offset[1]), float(offset[2]))

func create_tech_tree():
	if not tech_data.has("nodes"):
		return

	# Get domain colors
	var domain_colors = {}
	if tech_data.has("domains"):
		for domain in tech_data.domains:
			domain_colors[domain.id] = Color(domain.color)

	# Count nodes per tier for layout
	var tier_counts = {}
	for node_data in tech_data.nodes:
		var tier = int(node_data.tier)
		if not tier_counts.has(tier):
			tier_counts[tier] = 0
		tier_counts[tier] += 1

	total_count = tech_data.nodes.size()

	# Create nodes with disc layout
	var tier_indices = {}
	for node_data in tech_data.nodes:
		var tier = int(node_data.tier)
		if not tier_indices.has(tier):
			tier_indices[tier] = 0

		var tech_node = create_tech_node(node_data, domain_colors, tier_counts, tier_indices)
		tech_nodes[node_data.id] = tech_node
		add_child(tech_node)

		tier_indices[tier] += 1

	# Process links to set prerequisites
	if tech_data.has("links"):
		tech_links = tech_data.links
		for link in tech_links:
			var target_id = link.target
			if tech_nodes.has(target_id):
				var target_node = tech_nodes[target_id]
				target_node.prerequisites.append(link.source)

	# Set initial availability (tier 0 nodes are available)
	for node_id in tech_nodes:
		var node = tech_nodes[node_id]
		if node.tier == 0:
			node.set_available(true)

	create_connection_lines()

func create_tech_node(node_data: Dictionary, domain_colors: Dictionary, tier_counts: Dictionary, tier_indices: Dictionary) -> TechNode:
	var tech_node_scene = preload("res://scenes/tech_node.tscn")
	var tech_node = tech_node_scene.instantiate()

	tech_node.tech_id = node_data.id
	tech_node.tech_name = node_data.name
	tech_node.tier = int(node_data.tier)
	tech_node.tech_cost = randi_range(3, 9)  # Random cost between 3-9

	# Set color based on domain
	if domain_colors.has(node_data.domain):
		tech_node.domain_color = domain_colors[node_data.domain]

	# Calculate position in 3D disc layout
	var tier = int(node_data.tier)
	var tier_count = tier_counts[tier]
	var index = tier_indices[tier]

	var height_variation = randf_range(-1.5, 1.5)
	height_variation = float(layout_adjustments.get(node_data.id, {}).get("height_variation", height_variation))
	tech_node.set_meta("disc_height_variation", height_variation)
	tech_node.position = adjusted_disc_position(tech_node, index, tier_count, current_layout)

	# Connect signals
	tech_node.node_clicked.connect(_on_tech_node_clicked)
	tech_node.node_hovered.connect(_on_tech_node_hovered)

	return tech_node

func create_connection_lines():
	for link in tech_links:
		var source_id = link.source
		var target_id = link.target

		if tech_nodes.has(source_id) and tech_nodes.has(target_id):
			var source_node = tech_nodes[source_id]
			var target_node = tech_nodes[target_id]

			var line = create_line(source_node.position, target_node.position, source_node, target_node)
			add_child(line)

func create_line(from: Vector3, to: Vector3, source_node: TechNode, target_node: TechNode) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	mesh_instance.mesh = immediate_mesh

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate_mesh.surface_add_vertex(from)
	immediate_mesh.surface_add_vertex(to)
	immediate_mesh.surface_end()

	var material = StandardMaterial3D.new()

	# Color based on unlock status
	if source_node.is_unlocked and target_node.is_unlocked:
		material.albedo_color = Color(0.5, 1.0, 0.5, 0.8)  # Green for completed paths
	elif source_node.is_unlocked:
		material.albedo_color = Color(1.0, 1.0, 0.5, 0.6)  # Yellow for available paths
	else:
		material.albedo_color = Color(0.3, 0.3, 0.3, 0.4)  # Gray for locked paths

	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.set_surface_override_material(0, material)

	# Store references for dynamic updates
	mesh_instance.set_meta("source_node", source_node)
	mesh_instance.set_meta("target_node", target_node)

	return mesh_instance

func _on_tech_node_clicked(node: TechNode):
	if node.can_unlock(int(tech_points)):
		tech_points -= node.tech_cost
		node.unlock()
		unlocked_count += 1
		tech_unlocked.emit(node.tech_id)
		update_availability()
		update_connection_lines()
		update_ui()

func _on_tech_node_hovered(node: TechNode, is_hovering: bool):
	if tooltip_ui:
		if is_hovering:
			tooltip_ui.show_tooltip(node, get_viewport().get_mouse_position())
		else:
			tooltip_ui.hide_tooltip(node)

func update_availability():
	for node_id in tech_nodes:
		var node = tech_nodes[node_id]
		if node.is_unlocked:
			continue

		# Check if all prerequisites are unlocked
		var all_prereqs_met = true
		if node.prerequisites.size() > 0:
			for prereq_id in node.prerequisites:
				if tech_nodes.has(prereq_id):
					if not tech_nodes[prereq_id].is_unlocked:
						all_prereqs_met = false
						break
		else:
			# No prerequisites, available if tier 0
			all_prereqs_met = (node.tier == 0)

		node.set_available(all_prereqs_met)
	if tooltip_ui:
		tooltip_ui.refresh_tooltip()

func update_connection_lines():
	# Update all connection line colors based on unlock status
	for child in get_children():
		if child is MeshInstance3D and child.has_meta("source_node"):
			var source_node = child.get_meta("source_node") as TechNode
			var target_node = child.get_meta("target_node") as TechNode

			if source_node and target_node:
				var material = child.get_surface_override_material(0) as StandardMaterial3D
				if material:
					if source_node.is_unlocked and target_node.is_unlocked:
						material.albedo_color = Color(0.5, 1.0, 0.5, 0.8)
					elif source_node.is_unlocked:
						material.albedo_color = Color(1.0, 1.0, 0.5, 0.6)
					else:
						material.albedo_color = Color(0.3, 0.3, 0.3, 0.4)

func update_all_connection_lines():
	# Update both positions and colors of connection lines
	for child in get_children():
		if child is MeshInstance3D and child.has_meta("source_node"):
			var source_node = child.get_meta("source_node") as TechNode
			var target_node = child.get_meta("target_node") as TechNode

			if source_node and target_node:
				# Update line geometry
				var immediate_mesh = child.mesh as ImmediateMesh
				var material = child.get_surface_override_material(0) as StandardMaterial3D
				if immediate_mesh:
					immediate_mesh.clear_surfaces()
					immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
					immediate_mesh.surface_add_vertex(source_node.position)
					immediate_mesh.surface_add_vertex(target_node.position)
					immediate_mesh.surface_end()
					if material:
						child.set_surface_override_material(0, material)

				# Update color
				if material:
					if source_node.is_unlocked and target_node.is_unlocked:
						material.albedo_color = Color(0.5, 1.0, 0.5, 0.8)
					elif source_node.is_unlocked:
						material.albedo_color = Color(1.0, 1.0, 0.5, 0.6)
					else:
						material.albedo_color = Color(0.3, 0.3, 0.3, 0.4)

func update_ui():
	if points_label:
		points_label.text = "科技点: %d" % int(tech_points)
	if speed_label:
		speed_label.text = "速度: %.0fx" % time_scale
	if unlocked_label:
		unlocked_label.text = "已解锁: %d / %d" % [unlocked_count, total_count]
	if layout_label:
		var layout_text = "从左到右" if current_layout == LayoutMode.HORIZONTAL else "从上到下"
		layout_label.text = "发展方向: %s" % layout_text

func _input(event):
	if event.is_action_pressed("ui_page_up"):
		cycle_time_scale()
	elif event.is_action_pressed("ui_page_down"):
		toggle_layout()

func toggle_layout():
	if current_layout == LayoutMode.HORIZONTAL:
		current_layout = LayoutMode.VERTICAL
	else:
		current_layout = LayoutMode.HORIZONTAL

	rebuild_layout()
	update_ui()
	layout_changed.emit(current_layout)

func rebuild_layout():
	if layout_tween and layout_tween.is_valid():
		layout_tween.kill()
	# Recalculate positions for all nodes in disc formation
	var tier_counts = {}
	for node in tech_nodes.values():
		var tier: int = node.tier
		if not tier_counts.has(tier):
			tier_counts[tier] = 0
		tier_counts[tier] += 1

	var tier_indices = {}
	var starting_positions = {}
	var target_positions = {}
	for node_id in tech_nodes:
		var node = tech_nodes[node_id]
		var tier: int = node.tier

		if not tier_indices.has(tier):
			tier_indices[tier] = 0

		var tier_count = tier_counts[tier]
		var index = tier_indices[tier]

		# Calculate new position in disc layout
		starting_positions[node_id] = node.position
		target_positions[node_id] = adjusted_disc_position(node, index, tier_count, current_layout)

		tier_indices[tier] += 1

	if target_positions.is_empty():
		return
	# One callback keeps node positions and line endpoints in the same frame.
	layout_tween = create_tween()
	layout_tween.tween_method(_apply_layout_progress.bind(starting_positions, target_positions), 0.0, 1.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func _apply_layout_progress(progress: float, starting_positions: Dictionary, target_positions: Dictionary):
	for node_id in target_positions:
		tech_nodes[node_id].position = starting_positions[node_id].lerp(target_positions[node_id], progress)
	update_all_connection_lines()

func cycle_time_scale():
	if time_scale == 1.0:
		time_scale = 2.0
	elif time_scale == 2.0:
		time_scale = 4.0
	elif time_scale == 4.0:
		time_scale = 8.0
	else:
		time_scale = 1.0
	update_ui()
