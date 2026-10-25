extends SceneTree
## Model binding, visible geometry picking, release-only purchase and layout regressions.

var IDS: Array[String] = []
const EXACT_MESH_LAYER = 1 << 19
var checks = 0
var failures: Array[String] = []
var observations: Array = []
var capture_images = false
var output_dir = ""
var native_input = false

func _initialize():
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://tech_tree.json"))
	var pending: Array[String] = []
	for node in data.nodes:
		pending.append(node.id)
	# Same-tier dependencies need not follow the order of records in JSON.
	while not pending.is_empty():
		var progressed = false
		for id in pending.duplicate():
			var ready = true
			for link in data.links:
				if link.target == id and not IDS.has(link.source):
					ready = false
					break
			if ready:
				IDS.append(id)
				pending.erase(id)
				progressed = true
		if not progressed:
			push_error("Model test prerequisites cannot be ordered: " + str(pending))
			quit(2)
			return
	capture_images = "--render" in OS.get_cmdline_user_args()
	native_input = DisplayServer.get_name() != "headless"
	output_dir = OS.get_environment("TECH_TREE_MODEL_TEST_OUTPUT")
	if output_dir.is_empty():
		output_dir = "user://tier0_model_tests"
	if capture_images:
		DirAccess.make_dir_recursive_absolute(output_dir)
	create_timer(120.0).timeout.connect(func(): quit(2))
	call_deferred("run")

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func button(point: Vector2, down: bool):
	var event = InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	event.pressed = down
	if native_input:
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	else:
		root.push_input(event, true)

func motion(point: Vector2, held: bool):
	if native_input and not held:
		root.warp_mouse(point)
	var event = InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	if native_input:
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	else:
		root.push_input(event, true)

func bounds_of(container: Node3D) -> AABB:
	var bounds = AABB()
	var first = true
	for mesh in container.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh:
			var box: AABB = mesh.global_transform * mesh.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
	return bounds

func screenshot(name: String):
	if not capture_images:
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output_dir.path_join(name + ".png"))

func line_geometry_ok(manager) -> bool:
	for child in manager.get_children():
		if child is MeshInstance3D and child.has_meta("source_node"):
			var vertices = child.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			if not vertices[0].is_equal_approx(child.get_meta("source_node").position) or not vertices[1].is_equal_approx(child.get_meta("target_node").position):
				return false
	return true

func run():
	seed(48)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	if native_input:
		root.grab_focus()
	var manager = game.get_node("TechTreeManager")
	var camera = game.get_node("Camera3D")
	manager.points_per_second = 0.0
	manager.tech_points = 1000.0
	await create_timer(0.25).timeout
	for id in IDS:
		var node = manager.tech_nodes[id]
		check(node.model_loaded, id + ": binding loads on launch")
		if node.tier > 0:
			check(not node.is_available and node.label_3d.modulate.is_equal_approx(Color.GRAY), id + ": starts locked")
			check(is_zero_approx(node.glow_light.light_energy), id + ": locked glow is off")
			check(not node.glow_halo.visible, id + ": locked halo is hidden")
	await screenshot("tier0-initial")
	for id in IDS:
		var node = manager.tech_nodes[id]
		check(node.model_loaded and is_instance_valid(node.model_container), id + ": model loads")
		check(not node.mesh_instance.visible, id + ": original sphere is hidden")
		check(node.label_3d.modulate.is_equal_approx(Color.YELLOW), id + ": available label is yellow")
		check(node.glow_light.light_color.is_equal_approx(Color(0.2, 0.8, 0.3)) and is_equal_approx(node.glow_light.light_energy, 2.2), id + ": available glow is deep green")
		check(node.glow_halo.visible and node.halo_material.albedo_color.g > node.halo_material.albedo_color.r, id + ": compatible halo is visible and green")
		var bounds = bounds_of(node.model_container)
		var center = bounds.get_center()
		check(center.distance_to(node.global_position) < 0.001 and absf(bounds.get_longest_axis_size() - 1.0) < 0.001, id + ": model is centered and normalized")
		camera.look_at_from_position(center + Vector3(2, 1.5, 3).normalized() * maxf(2.5, bounds.size.length() * 1.8), center, Vector3.UP)
		await screenshot("tier0-" + id)
		# Test-only triangle colliders identify genuinely visible mesh pixels.
		# They never receive GUI picking and are removed before gesture tests.
		var bodies: Array = []
		for mesh in node.model_container.find_children("*", "MeshInstance3D", true, false):
			if mesh.mesh == null:
				continue
			var body = StaticBody3D.new()
			body.collision_layer = EXACT_MESH_LAYER
			body.collision_mask = 0
			body.input_ray_pickable = false
			root.add_child(body)
			var shape = CollisionShape3D.new()
			# Bake world-space faces: a StaticBody inherited from a GLB mesh can
			# carry extreme scale, which makes the test proxy unreliable.
			var faces = mesh.mesh.get_faces()
			for face_index in range(faces.size()):
				faces[face_index] = mesh.global_transform * faces[face_index]
			var triangles = ConcavePolygonShape3D.new()
			triangles.backface_collision = true
			triangles.set_faces(faces)
			shape.shape = triangles
			body.add_child(shape)
			bodies.append(body)
		for i in range(2):
			await physics_frame
		var first_point = camera.unproject_position(bounds.get_endpoint(0))
		var rectangle = Rect2(first_point, Vector2.ZERO)
		for i in range(1, 8):
			rectangle = rectangle.expand(camera.unproject_position(bounds.get_endpoint(i)))
		var visible_samples = 0
		var missed_samples = 0
		var example_miss = Vector2.ZERO
		for y in range(24):
			for x in range(24):
				var point = rectangle.position + rectangle.size * Vector2((x + 0.5) / 24.0, (y + 0.5) / 24.0)
				var start = camera.project_ray_origin(point)
				var query = PhysicsRayQueryParameters3D.create(start, start + camera.project_ray_normal(point) * camera.far, EXACT_MESH_LAYER)
				query.collide_with_bodies = true
				query.collide_with_areas = false
				if not camera.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
					visible_samples += 1
					if camera._pick_tech_node(point) != node:
						missed_samples += 1
						example_miss = point
		check(visible_samples > 0 and missed_samples == 0, id + ": visible model pixels are pickable (misses " + str(missed_samples) + "/" + str(visible_samples) + ")")
		for body in bodies:
			body.free()
		for i in range(2):
			await physics_frame
		var point = camera.unproject_position(node.global_position)
		motion(point, false)
		for i in range(2):
			await physics_frame
		var balance = manager.tech_points
		button(point, true)
		for i in range(2):
			await physics_frame
		var unlocked_on_press = node.is_unlocked
		check(Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) if native_input else camera.dragging, id + ": simulated press begins a held gesture")
		check(not node.is_unlocked and is_equal_approx(manager.tech_points, balance), id + ": press waits for release")
		motion(point + Vector2(80, 30), true)
		await physics_frame
		button(point + Vector2(80, 30), false)
		for i in range(2):
			await physics_frame
		check(not node.is_unlocked and is_equal_approx(manager.tech_points, balance), id + ": drag never purchases its starting node")
		var spent_after_drag = balance - manager.tech_points
		# Once gesture protection is fixed, exercise a legitimate release purchase too.
		if not node.is_unlocked:
			camera.look_at_from_position(center + Vector3(2, 1.5, 3).normalized() * maxf(2.5, bounds.size.length() * 1.8), center, Vector3.UP)
			point = camera.unproject_position(node.global_position)
			motion(point, false)
			for i in range(2):
				await physics_frame
			button(point, true)
			for i in range(2):
				await physics_frame
			var gesture_before_release = {"focused":root.has_focus(),"dragging":camera.dragging,"moved":camera.gesture_moved,"target":camera.pressed_node == node,"held":Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)}
			button(point, false)
			for i in range(2):
				await physics_frame
			if not node.is_unlocked:
				print("Purchase interrupted: ", id, " ", gesture_before_release)
		check(node.is_unlocked and is_equal_approx(manager.tech_points, balance - node.tech_cost), id + ": valid purchase deducts the exact cost once")
		await create_timer(0.7).timeout
		check(node.model_container.scale.is_equal_approx(Vector3.ONE), id + ": model pulse restores scale")
		check(node.label_3d.modulate.is_equal_approx(Color.WHITE), id + ": unlocked label is white")
		check(node.glow_light.light_color.is_equal_approx(Color(0.76, 0.60, 0.30)) and is_equal_approx(node.glow_light.light_energy, 2.0), id + ": unlocked glow is deep khaki")
		check(node.glow_halo.visible and node.halo_material.albedo_color.r > node.halo_material.albedo_color.b, id + ": compatible halo is khaki")
		observations.append({"node_id":id, "bounds":str(bounds), "visible_mesh_samples":visible_samples, "unpickable_mesh_samples":missed_samples, "example_unpickable_screen_point":str(example_miss), "unlocked_on_press":unlocked_on_press, "spent_after_drag":spent_after_drag, "spent_after_valid_click":balance-manager.tech_points})
	for mode in [manager.LayoutMode.HORIZONTAL, manager.LayoutMode.VERTICAL]:
		manager.toggle_layout()
		await create_timer(0.95).timeout
		for id in IDS:
			var node = manager.tech_nodes[id]
			check(node.model_loaded and node.model_container.get_parent() == node, id + ": model follows layout " + str(mode))
		check(line_geometry_ok(manager), "Connection endpoints follow layout " + str(mode))
		check(manager.unlocked_count == IDS.size(), "Layout retains unlock count " + str(mode))
		await screenshot("tier0-layout-" + str(mode))
	var fallback = load("res://scenes/tech_node.tscn").instantiate()
	fallback.tech_id = "astronomy_nav"
	fallback.tier = 0
	fallback.tier_0_models = fallback.tier_0_models.duplicate()
	fallback.tier_0_models["astronomy_nav"] = "res://assets/models/poly_pizza/missing_test_model.glb"
	root.add_child(fallback)
	fallback.set_available(true)
	check(not fallback.model_loaded and fallback.mesh_instance.visible, "Missing model leaves fallback sphere visible")
	check(fallback.mesh_instance.get_surface_override_material(0) != null and fallback.label_3d.modulate.is_equal_approx(Color.YELLOW), "Missing model fallback has a valid available-state material and label")
	fallback.free()
	if capture_images:
		var file = FileAccess.open(output_dir.path_join("tier0-observations.json"), FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"models":observations}, "  "))
		file.close()
	print("Tier 0 model probe: ", checks, " checks; ", failures.size(), " failures")
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
