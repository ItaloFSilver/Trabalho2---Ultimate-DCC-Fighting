extends FighterBase
class_name Stroele

func _ready():
	# Balanceamento de atributos do Stroele
	max_health = 120.0
	speed = 175.0
	jump_force = -380.0
	base_damage = 13.0
	special_damage = 32.0
	
	health = max_health
	super._ready()
