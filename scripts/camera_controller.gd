extends Camera3D

@export var zoom_speed: float = 2.0
@export var min_distance: float = 10.0
@export var max_distance: float = 70.0
@export var rotation_speed: float = 0.005
@export var pan_speed: float = 0.05
@export var drag_threshold: float = 6.0

var camera_distance: float = 30.0
var dragging: bool = false
var last_mouse_pos: Vector2
var press_mouse_pos: Vector2
var gesture_moved: bool = false
var pressed_node: TechNode
var tech_tree: Node3D

# 旋转和平移
var rotation_angle: float = 0.0  # 绕中轴线的360°旋转
var pan_offset: float = 0.0      # 沿中轴线的平移

enum LayoutMode { HORIZONTAL, VERTICAL }
var current_layout: LayoutMode = LayoutMode.VERTICAL  # 默认从上到下

# 固定中轴线
var axis_center: Vector3 = Vector3.ZERO

func _ready():
	tech_tree = get_node_or_null("../TechTreeManager")
	if tech_tree:
		tech_tree.layout_changed.connect(_on_layout_changed)
		_on_layout_changed(tech_tree.current_layout)
		frame_initial_tree()
	else:
		calculate_axis_center()
		update_camera_transform()

func frame_initial_tree():
	if not is_instance_valid(tech_tree) or tech_tree.tech_nodes.is_empty():
		return
	var nodes = tech_tree.tech_nodes.values()
	var bounds = AABB(nodes[0].global_position, Vector3.ZERO)
	for node in nodes:
		bounds = bounds.expand(node.global_position)
	bounds = bounds.grow(2.0)
	var size = get_viewport().get_visible_rect().size
	var aspect = size.x / maxf(size.y, 1.0)
	var tan_vertical = tan(deg_to_rad(fov) * 0.5)
	var tan_horizontal = tan_vertical * aspect
	if keep_aspect == Camera3D.KEEP_WIDTH:
		tan_horizontal = tan_vertical
		tan_vertical = tan_horizontal / aspect
	var required_distance = min_distance
	var focus = get_focus_point()
	for index in range(8):
		var corner = global_basis.transposed() * (bounds.get_endpoint(index) - focus)
		required_distance = maxf(required_distance, corner.z + absf(corner.x) / tan_horizontal)
		required_distance = maxf(required_distance, corner.z + absf(corner.y) / tan_vertical)
	camera_distance = clampf(required_distance, min_distance, max_distance)
	update_camera_transform()

func _on_layout_changed(new_layout):
	cancel_gesture()
	current_layout = new_layout
	rotation_angle = 0.0
	pan_offset = 0.0
	calculate_axis_center()
	update_camera_transform()

func calculate_axis_center():
	var min_tier = 0
	var max_tier = 4
	if is_instance_valid(tech_tree) and not tech_tree.tech_nodes.is_empty():
		min_tier = 2147483647
		max_tier = 0
		for node in tech_tree.tech_nodes.values():
			min_tier = mini(min_tier, node.tier)
			max_tier = maxi(max_tier, node.tier)
	var middle_tier = (min_tier + max_tier) * 0.5
	if current_layout == LayoutMode.VERTICAL:
		var spacing = tech_tree.VERTICAL_TIER_SPACING if is_instance_valid(tech_tree) else 15.0
		axis_center = Vector3(0, -middle_tier * spacing, 0)
	else:
		var spacing = tech_tree.TIER_SPACING if is_instance_valid(tech_tree) else 12.0
		axis_center = Vector3(middle_tier * spacing, 0, 0)

func get_focus_point() -> Vector3:
	if current_layout == LayoutMode.VERTICAL:
		return axis_center + Vector3(0, pan_offset, 0)
	return axis_center + Vector3(pan_offset, 0, 0)

func cancel_gesture():
	dragging = false
	gesture_moved = false
	pressed_node = null

func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_MOUSE_EXIT:
		cancel_gesture()

func _exit_tree():
	cancel_gesture()

func _pick_tech_node(screen_position: Vector2) -> TechNode:
	var ray_origin = project_ray_origin(screen_position)
	var ray_end = ray_origin + project_ray_normal(screen_position) * far
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var collider = hit.collider
		if collider is Area3D and collider.get_parent() is TechNode:
			return collider.get_parent() as TechNode
	return null

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cancel_gesture()
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				cancel_gesture()
				dragging = true
				press_mouse_pos = event.position
				last_mouse_pos = event.position
				pressed_node = _pick_tech_node(event.position)
			else:
				var candidate = pressed_node
				var is_click = dragging and not gesture_moved and event.position.distance_to(press_mouse_pos) <= drag_threshold
				var same_target = is_click and is_instance_valid(candidate) and _pick_tech_node(event.position) == candidate
				cancel_gesture()
				if same_target and is_instance_valid(candidate):
					candidate.node_clicked.emit(candidate)
			return

		# 滚轮缩放
		if not event.pressed:
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			cancel_gesture()
			camera_distance -= zoom_speed
			camera_distance = clamp(camera_distance, min_distance, max_distance)
			update_camera_transform()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cancel_gesture()
			camera_distance += zoom_speed
			camera_distance = clamp(camera_distance, min_distance, max_distance)
			update_camera_transform()

	if event is InputEventMouseMotion and dragging:
		if not (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
			cancel_gesture()
			return
		gesture_moved = gesture_moved or event.position.distance_to(press_mouse_pos) > drag_threshold
		if not gesture_moved:
			return
		# 越过拖动阈值时补齐起始位移，避免鼠标采样频率影响拖动距离。
		var delta_mouse = event.position - last_mouse_pos
		last_mouse_pos = event.position
		pressed_node = null

		if current_layout == LayoutMode.VERTICAL:
			# 从上到下：垂直Y轴固定
			# 左右拖动 = 绕Y轴旋转
			# 上下拖动 = 沿Y轴平移（跟随鼠标方向）
			rotation_angle -= delta_mouse.x * rotation_speed
			pan_offset += delta_mouse.y * pan_speed

		else:
			# 从左到右：水平X轴固定
			# 上下拖动 = 绕X轴旋转
			# 左右拖动 = 沿X轴平移（跟随鼠标方向）
			rotation_angle -= delta_mouse.y * rotation_speed
			# 焦点反向移动，使画面内容跟随鼠标。
			pan_offset -= delta_mouse.x * pan_speed

		update_camera_transform()

func update_camera_transform():
	camera_distance = clampf(camera_distance, min_distance, max_distance)
	rotation_angle = wrapf(rotation_angle, -PI, PI)
	var focus_point = get_focus_point()
	var cam_pos: Vector3
	var look_up = Vector3.UP

	if current_layout == LayoutMode.VERTICAL:
		# 从上到下：垂直Y轴固定
		# 使用较小的俯角，减少透视变形
		var tilt = -PI/6  # 俯角30度（原来60度太陡）
		var horizontal_dist = camera_distance * cos(tilt)
		var vertical_height = camera_distance * sin(tilt)

		var x_pos = horizontal_dist * sin(rotation_angle)
		var z_pos = horizontal_dist * cos(rotation_angle)

		cam_pos = focus_point + Vector3(x_pos, -vertical_height, z_pos)

	else:
		# 从左到右：水平X轴固定
		# 使用较小的侧视角，减少透视变形
		var side_angle = -PI/6  # 侧视角30度（原来45度太陡）
		var y_pos = camera_distance * sin(rotation_angle + side_angle)
		var z_pos = camera_distance * cos(rotation_angle + side_angle)

		cam_pos = focus_point + Vector3(0, y_pos, z_pos)
		# Keep orientation continuous when the X-axis orbit crosses either Y pole.
		look_up = Basis(Vector3.RIGHT, -rotation_angle) * Vector3.UP

	global_position = cam_pos
	look_at(focus_point, look_up)
