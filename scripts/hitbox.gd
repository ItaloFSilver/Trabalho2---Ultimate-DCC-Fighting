extends Area2D
class_name Hitbox

@export var attack_type: String = "punch"

@onready var owner_fighter = owner

func _ready():
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D):
	if area.name == "Hurtbox":
		var target_fighter = area.owner
		
		if target_fighter != owner_fighter and target_fighter.has_method("take_damage"):
			
			var is_finisher = false
			if "is_current_attack_finisher" in owner_fighter:
				is_finisher = owner_fighter.is_current_attack_finisher
			
			var current_type = attack_type
			if owner_fighter.anim_player.current_animation == "uppercut":
				current_type = "uppercut"
				
			owner_fighter.on_hitbox_connected(target_fighter, is_finisher, current_type)
