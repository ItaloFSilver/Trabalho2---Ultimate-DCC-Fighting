extends CharacterBody2D
class_name FighterBase

# Atributos base a serem balanceados[cite: 1]
@export var max_health: float = 100.0
@export var speed: float = 200.0
@export var jump_force: float = -400.0
@export var base_damage: float = 10.0

var health: float = max_health

# Barra de Especial[cite: 1]
var special_meter: float = 0.0
var max_special: float = 100.0
@export var base_special_gain: float = 5.0

# Máquina de Estados[cite: 1]
enum State { IDLE, WALK, JUMP, ATTACK, AIR_ATTACK, HIT, AIR_HIT, DEAD }
var current_state: State = State.IDLE

# Sistema de Combos[cite: 1]
var combo_step: int = 0
@onready var combo_timer = $Timers/ComboTimer #[cite: 1]
@onready var anim_player = $AnimationPlayer #[cite: 1]

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	# Janela de tempo dos combos (ex: 0.35s)[cite: 1]
	combo_timer.wait_time = 0.35
	combo_timer.one_shot = true
	combo_timer.timeout.connect(_on_combo_timer_timeout)

func _physics_process(delta):
	if current_state == State.DEAD:
		return

	if not is_on_floor():
		velocity.y += gravity * delta
		if current_state not in [State.ATTACK, State.AIR_ATTACK, State.HIT, State.AIR_HIT]:
			current_state = State.JUMP
	elif current_state == State.JUMP and is_on_floor():
		current_state = State.IDLE

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

func handle_movement():
	if not is_on_floor(): return
	
	if Input.is_action_just_pressed("ui_up"):
		velocity.y = jump_force
		current_state = State.JUMP
		return

	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * speed
		current_state = State.WALK
		$Sprite2D.scale.x = direction
		$Hitboxes.scale.x = direction #[cite: 1]
		anim_player.play("walk")
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		current_state = State.IDLE
		anim_player.play("idle")

func handle_combat_input():
	if Input.is_action_just_pressed("soco"):
		execute_attack("soco")
	elif Input.is_action_just_pressed("chute"):
		execute_attack("chute")
	elif Input.is_action_just_pressed("especial") and special_meter >= max_special:
		execute_special()

func execute_attack(attack_type: String):
	current_state = State.AIR_ATTACK if not is_on_floor() else State.ATTACK
	
	if combo_timer.is_stopped():
		combo_step = 1
	else:
		combo_step += 1
		
	anim_player.stop()
		
	if combo_step < 3:
		anim_player.play("punch" if attack_type == "soco" else "kick")
		
	elif combo_step >= 3:
		if attack_type == "soco":
			if Input.is_action_pressed("ui_down"):
				# Soco > Soco > Baixo+Soco (Uppercut / Launcher)[cite: 1]
				anim_player.play("uppercut")
				velocity.y = jump_force # Joga o jogador e o oponente para cima simultaneamente[cite: 1]
				current_state = State.AIR_ATTACK
			else:
				# Soco > Soco > Soco[cite: 1]
				anim_player.play("punch") 
				
		elif attack_type == "chute":
			# Soco > Soco > Chute (Controle de espaço / Knockback)[cite: 1]
			anim_player.play("kick") 
			
		combo_step = 0 
		
	combo_timer.start()

func on_hitbox_connected(enemy, is_finisher: bool, attack_type: String):
	# Ganho de barra base ao acertar o golpe[cite: 1]
	add_special_meter(base_special_gain) 
	
	# Multiplicador de dano de 1.2x em golpes finalizadores de combo[cite: 1]
	var damage = base_damage * (1.2 if is_finisher else 1.0) 
	var knockback_force = Vector2.ZERO
	
	if is_finisher and attack_type == "kick":
		knockback_force = Vector2(300 * sign($Sprite2D.scale.x), 0)
	elif is_finisher and attack_type == "uppercut":
		knockback_force = Vector2(0, jump_force)
		
	enemy.take_damage(damage, knockback_force)

func take_damage(amount: float, knockback: Vector2):
	health -= amount
	
	# O personagem que recebe o golpe enche a barra 1,1x (10%) mais rápido em relação ao ganho base[cite: 1]
	add_special_meter(base_special_gain * 1.1) 
	
	velocity = knockback
	if knockback.y < 0 or not is_on_floor():
		current_state = State.AIR_HIT
	else:
		current_state = State.HIT
		
	anim_player.play("hit")
	if health <= 0:
		current_state = State.DEAD
		anim_player.play("die")

func add_special_meter(amount: float):
	special_meter = clamp(special_meter + amount, 0.0, max_special)

func _on_combo_timer_timeout():
	combo_step = 0

func execute_special():
	# Esta função será sobrescrita nos scripts específicos de cada professor
	special_meter = 0.0
	anim_player.play("especial")

func _on_animation_finished(anim_name: String):
	if current_state in [State.ATTACK, State.HIT] and is_on_floor():
		current_state = State.IDLE
	elif current_state in [State.AIR_ATTACK, State.AIR_HIT] and not is_on_floor():
		current_state = State.JUMP
