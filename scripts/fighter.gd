extends CharacterBody2D
class_name FighterBase

## Emitido uma vez, quando a vida chega a zero. A arena usa para encerrar a luta.
signal derrotado(lutador: FighterBase)

# Identificação e Referência do Oponente
@export var player_prefix: String = "p1_" # Use "p1_" para Player 1 e "p2_" para Player 2
@export var opponent: Node2D # Arraste o oponente no Inspector ou atribua via código na Arena

# Atributos base (balanceáveis individualmente em cada professor)[cite: 1]
@export var max_health: float = 100.0
@export var speed: float = 200.0
@export var jump_force: float = -600.0
@export var gravity: float = 980.0 # Atributo próprio para ajustar o peso/queda de cada lutador
@export var base_damage: float = 10.0
@export var hit_cooldown: float = 0.3 # Tempo de atordoamento/cooldown ao levar um golpe

# Especial (Projétil)
@export var projectile_scene: PackedScene
@export var special_damage: float = 25.0

var is_current_attack_finisher: bool = false
var is_invincible: bool = false
var health: float = max_health

# Barra de Especial[cite: 1]
var special_meter: float = 0.0
var max_special: float = 100.0
@export var base_special_gain: float = 15.0

enum State { IDLE, WALK, JUMP, ATTACK, AIR_ATTACK, HIT, AIR_HIT, DEAD }
var current_state: State = State.IDLE

var combo_step: int = 0
@onready var combo_timer = $Timers/Combo_Timer
@onready var anim_player = $AnimationPlayer

func _ready():
	health = max_health
	combo_timer.wait_time = 0.35
	combo_timer.one_shot = true
	combo_timer.timeout.connect(_on_combo_timer_timeout)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		if current_state not in [State.ATTACK, State.AIR_ATTACK, State.HIT, State.AIR_HIT, State.DEAD]:
			current_state = State.JUMP
	elif current_state == State.JUMP:
		current_state = State.IDLE

	if current_state == State.DEAD:
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0, speed * delta * 4)
		move_and_slide()
		global_position.x = clamp(global_position.x, 45.0, 1331.0)
		return

	if current_state not in [State.HIT, State.AIR_HIT]:
		update_facing()

	match current_state:
		State.IDLE, State.WALK, State.JUMP:
			handle_movement()
			handle_combat_input()
		State.ATTACK, State.AIR_ATTACK:
			if is_on_floor():
				velocity.x = move_toward(velocity.x, 0, speed * delta * 4)
		State.HIT, State.AIR_HIT:
			if is_on_floor():
				velocity.x = move_toward(velocity.x, 0, speed * delta * 2)

	move_and_slide()
	global_position.x = clamp(global_position.x, 45.0, 1331.0)

func update_facing():
	if opponent and is_instance_valid(opponent):
		var diff_x = opponent.global_position.x - global_position.x
		if abs(diff_x) > 5.0:
			var facing = sign(diff_x)
			$Sprite2D.scale.x = abs($Sprite2D.scale.x) * facing
			$HitBoxes.scale.x = abs($HitBoxes.scale.x) * facing

func handle_movement():
	if not is_on_floor(): return
	
	if Input.is_action_just_pressed(player_prefix + "up"):
		velocity.y = jump_force
		current_state = State.JUMP
		anim_player.play("jump")
		return

	var direction = Input.get_axis(player_prefix + "left", player_prefix + "right")
	if direction:
		velocity.x = direction * speed
		current_state = State.WALK
		if not opponent:
			var facing = sign(direction)
			$Sprite2D.scale.x = abs($Sprite2D.scale.x) * facing
			$HitBoxes.scale.x = abs($HitBoxes.scale.x) * facing
		anim_player.play("walk")
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		current_state = State.IDLE
		anim_player.play("idle")

func handle_combat_input():
	if Input.is_action_just_pressed(player_prefix + "punch"):
		execute_attack("soco")
	elif Input.is_action_just_pressed(player_prefix + "kick"):
		execute_attack("chute")
	elif Input.is_action_just_pressed(player_prefix + "special") and special_meter >= max_special:
		execute_special()

func execute_attack(attack_type: String):
	current_state = State.AIR_ATTACK if not is_on_floor() else State.ATTACK
	
	if combo_timer.is_stopped():
		combo_step = 1
	else:
		combo_step += 1
		
	anim_player.stop()
		
	if combo_step < 3:
		is_current_attack_finisher = false
		anim_player.play("punch" if attack_type == "soco" else "kick")
		
	elif combo_step >= 3:
		is_current_attack_finisher = true 
		if attack_type == "soco":
			if Input.is_action_pressed(player_prefix + "down"):
				anim_player.play("uppercut")
				velocity.y = jump_force 
				current_state = State.AIR_ATTACK
			else:
				anim_player.play("punch") 
				
		elif attack_type == "chute":
			anim_player.play("kick") 
			
		combo_step = 0 
		
	await anim_player.animation_finished
	combo_timer.start()
	if current_state not in [State.HIT, State.AIR_HIT, State.DEAD]:
		current_state = State.IDLE if is_on_floor() else State.JUMP

func on_hitbox_connected(enemy, is_finisher: bool, attack_type: String):
	add_special_meter(base_special_gain) 
	
	var damage = base_damage * (1.2 if is_finisher else 1.0) # Multiplicador de 1.2x no finalizador[cite: 1]
	var knockback_force = Vector2.ZERO
	
	if is_finisher and attack_type == "kick":
		knockback_force = Vector2(300 * sign($Sprite2D.scale.x), 0)
	elif is_finisher and attack_type == "uppercut":
		knockback_force = Vector2(0, jump_force)
		
	enemy.take_damage(damage, knockback_force)

func is_blocking() -> bool:
	if not is_on_floor() or current_state not in [State.IDLE, State.WALK]:
		return false
		
	var facing = sign($Sprite2D.scale.x)
	var input_dir = Input.get_axis(player_prefix + "left", player_prefix + "right")
	
	return input_dir != 0 and sign(input_dir) != facing

func take_damage(amount: float, knockback: Vector2):
	if current_state == State.DEAD or is_invincible:
		return

	var blocked = is_blocking()
	var final_damage = amount * 0.25 if blocked else amount
	
	health -= final_damage
	add_special_meter(base_special_gain * 1.1) # Barra enche 1,1x mais rápido ao apanhar[cite: 1]
	
	if health <= 0:
		current_state = State.DEAD
		anim_player.play("die")
		derrotado.emit(self)
		return

	is_invincible = true
	
	if blocked:
		velocity = Vector2(knockback.x * 0.5, 0)
		current_state = State.HIT
		anim_player.play("hit")
	else:
		velocity = knockback
		if knockback.y < 0 or not is_on_floor():
			current_state = State.AIR_HIT
		else:
			current_state = State.HIT
		anim_player.play("hit")

	await get_tree().create_timer(hit_cooldown).timeout
	
	is_invincible = false
	if current_state != State.DEAD:
		current_state = State.IDLE if is_on_floor() else State.JUMP

## 1 para o Player 1, 2 para o Player 2 (a partir do player_prefix).
func numero_jogador() -> int:
	return 2 if player_prefix == "p2_" else 1

func add_special_meter(amount: float):
	special_meter = clamp(special_meter + amount, 0.0, max_special)

func _on_combo_timer_timeout():
	combo_step = 0

func execute_special():
	special_meter = 0.0
	current_state = State.ATTACK
	anim_player.play("special")
	spawn_projectile()
	await anim_player.animation_finished
	if current_state not in [State.HIT, State.AIR_HIT, State.DEAD]:
		current_state = State.IDLE

func spawn_projectile():
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		get_parent().add_child(proj)
		proj.global_position = $HitBoxes/ProjeteisSpawnPoint.global_position
		var facing = sign($Sprite2D.scale.x)
		proj.setup(facing, self, special_damage)
