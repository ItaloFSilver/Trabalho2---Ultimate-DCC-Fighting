extends FighterBase
class_name Caniato

func _ready():
	# Balanceamento de atributos do Caniato
	max_health = 100.0
	speed = 210.0
	jump_force = -600.0
	base_damage = 10.0
	special_damage = 25.0
	
	health = max_health
	super._ready() 
