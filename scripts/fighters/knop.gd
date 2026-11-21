extends FighterBase
class_name Knop

func _ready():
	# Balanceamento de atributos do Knop
	max_health = 90.0
	speed = 200.0
	jump_force = -600.0
	base_damage = 11.0
	special_damage = 35.0
	
	health = max_health
	super._ready()
