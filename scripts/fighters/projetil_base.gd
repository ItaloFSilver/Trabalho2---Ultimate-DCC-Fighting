extends Area2D
class_name ProjetilBase

@export var speed: float = 450.0
@export var damage: float = 25.0

var direction: float = 1.0
var shooter: Node2D = null

func _ready():
	area_entered.connect(_on_area_entered)
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)

func _physics_process(delta):
	position.x += speed * direction * delta

func setup(dir: float, owner_node: Node2D, custom_damage: float):
	direction = sign(dir)
	shooter = owner_node
	damage = custom_damage
	$Sprite2D.scale.x = abs($Sprite2D.scale.x) * direction

func _on_area_entered(area: Area2D):
	if area.name == "Hurtbox":
		var target = area.owner
		if target != shooter and target.has_method("take_damage"):
			# Aplica dano e um pequeno knockback horizontal
			target.take_damage(damage, Vector2(250 * direction, 0))
			queue_free() # Destrói o projétil ao acertar
