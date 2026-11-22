extends Camera2D
class_name DynamicCamera

@export var player1: Node2D
@export var player2: Node2D

@export var min_zoom: float = 0.75
@export var max_zoom: float = 1.25
@export var margin: Vector2 = Vector2(200, 150) 
@export var smooth_speed: float = 8.0 

@export var vertical_offset: float = -40.0 

@onready var screen_size: Vector2 = get_viewport_rect().size

func _process(delta: float) -> void:
	if not is_instance_valid(player1) or not is_instance_valid(player2):
		return

	var midpoint = (player1.global_position + player2.global_position) * 0.5
	midpoint.y += vertical_offset
	
	global_position = global_position.lerp(midpoint, smooth_speed * delta)

	var dist_x = abs(player1.global_position.x - player2.global_position.x) + margin.x * 2
	var dist_y = abs(player1.global_position.y - player2.global_position.y) + margin.y * 2

	var zoom_x = screen_size.x / dist_x
	var zoom_y = screen_size.y / dist_y
	
	var target_zoom_value = clamp(min(zoom_x, zoom_y), min_zoom, max_zoom)
	var target_zoom = Vector2(target_zoom_value, target_zoom_value)

	zoom = zoom.lerp(target_zoom, smooth_speed * delta)
