extends FighterBase
class_name Gleiph

func _ready():
	# Balanceamento de atributos do Gleiph
	max_health = 95.0
	speed = 245.0
	jump_force = -430.0
	base_damage = 9.5
	special_damage = 24.0
	
	health = max_health
	super._ready()

# Exemplo opcional: sobrescrevendo o disparo para o projétil do Gleiph viajar mais rápido
func spawn_projectile():
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		get_parent().add_child(proj)
		proj.global_position = $HitBoxes/ProjeteisSpawnPoint.global_position
		proj.speed = 650.0 # Projétil mais rápido que o padrão (450.0)
		var facing = sign($Sprite2D.scale.x)
		proj.setup(facing, self, special_damage)
