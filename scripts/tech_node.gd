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

func _ready():
	setup_visuals()
	update_visual_state()

	# Connect signals
	if area_3d:
		area_3d.mouse_entered.connect(_on_mouse_entered)
		area_3d.mouse_exited.connect(_on_mouse_exited)

func setup_visuals():
	# Setup label
	if label_3d:
		label_3d.text = tech_name
		label_3d.modulate = domain_color
		label_3d.pixel_size = 0.008
		label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label_3d.outline_size = 8
		label_3d.outline_modulate = Color(0, 0, 0, 1)

	# Setup mesh material
	if mesh_instance:
		var material = StandardMaterial3D.new()
		material.albedo_color = domain_color
		material.emission_enabled = true
		material.emission = domain_color * 0.3
		mesh_instance.set_surface_override_material(0, material)

func update_visual_state():
	if not mesh_instance:
		return

	var material = mesh_instance.get_surface_override_material(0) as StandardMaterial3D
	if not material:
		return

	if is_unlocked:
		material.albedo_color = domain_color
		material.emission = domain_color * 0.5
		if label_3d:
			label_3d.modulate = Color.WHITE
	elif is_available:
		material.albedo_color = domain_color * 0.7
		material.emission = domain_color * 0.3
		if label_3d:
			label_3d.modulate = Color.YELLOW
	else:
		material.albedo_color = Color.DARK_GRAY
		material.emission = Color.BLACK
		if label_3d:
			label_3d.modulate = Color.GRAY

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
	# Create a simple scale pulse animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(mesh_instance, "scale", Vector3(1.5, 1.5, 1.5), 0.3)
	tween.tween_property(label_3d, "modulate:a", 0.0, 0.2).set_delay(0.1)
	tween.chain()
	tween.tween_property(mesh_instance, "scale", Vector3(1.0, 1.0, 1.0), 0.3)
	tween.tween_property(label_3d, "modulate:a", 1.0, 0.2)

func set_available(available: bool):
	is_available = available
	update_visual_state()

