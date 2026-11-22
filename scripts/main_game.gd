extends Node2D

@export var fighters_scenes: Dictionary = {
	&"caniato": preload("res://scenes/Caniato.tscn"),
	&"gleiph": preload("res://scenes/Gleiph.tscn"),
	&"knop": preload("res://scenes/Knop.tscn"),
	&"victor": preload("res://scenes/Stroele.tscn"),
}

## Fim de luta: cena aberta quando um lutador é derrotado.
const CENA_FIM := "res://scenes/ui/fim_luta.tscn"
## Música que toca durante a luta.
const MUSICA_ARENA := "res://assets/sons/trilha_sonora.mp3"
## Quanto tempo (em segundos reais) o K.O. dura antes da troca de tela.
@export var duracao_ko := 1.5
## Velocidade do jogo durante o K.O. (1.0 = normal).
@export_range(0.05, 1.0) var camera_lenta := 0.35

@onready var spawn_p1: Marker2D = $SpawnP1
@onready var spawn_p2: Marker2D = $SpawnP2
@onready var camera: DynamicCamera = $Camera2D

var player1: FighterBase
var player2: FighterBase
var _luta_encerrada := false


func _ready() -> void:
	_instanciate_fighters()


func _instanciate_fighters() -> void:
	var id_p1 := StringName(str(Partida.personagem_p1).to_lower().strip_edges())
	var id_p2 := StringName(str(Partida.personagem_p2).to_lower().strip_edges())

	print("Spawnando -> P1: ", id_p1, " | P2: ", id_p2)

	var scene_p1: PackedScene = fighters_scenes.get(id_p1)
	var scene_p2: PackedScene = fighters_scenes.get(id_p2)

	if scene_p1:
		player1 = scene_p1.instantiate() as FighterBase
		add_child(player1)
		player1.global_position = spawn_p1.global_position
		player1.player_prefix = "p1_"
	else:
		push_warning("Cena não encontrada para P1: " + str(id_p1))

	if scene_p2:
		player2 = scene_p2.instantiate() as FighterBase
		add_child(player2)
		player2.global_position = spawn_p2.global_position
		player2.player_prefix = "p2_"
	else:
		push_warning("Cena não encontrada para P2: " + str(id_p2))

	if player1 and player2:
		player1.opponent = player2
		player2.opponent = player1
		# quando alguém morre, a luta termina e vai para a tela de fim
		player1.derrotado.connect(_on_lutador_derrotado)
		player2.derrotado.connect(_on_lutador_derrotado)

		# HUD com vida, especial, nomes e aviso de K.O. (os lutadores já estão na cena)
		var hud := HudCombate.new()
		add_child(hud)
		hud.configurar(player1, player2)

	Audio.tocar_musica(MUSICA_ARENA)
		
	camera.player1 = player1
	camera.player2 = player2


func _on_lutador_derrotado(perdedor: FighterBase) -> void:
	if _luta_encerrada:
		return  # se os dois caírem juntos, vale quem caiu primeiro
	_luta_encerrada = true
	Partida.registrar_derrota(perdedor.numero_jogador())
	Audio.tocar_sfx("ko")
	Audio.parar_musica(1.0)

	# "K.O." em câmera lenta; o timer ignora a câmera lenta para durar o tempo real
	Engine.time_scale = camera_lenta
	await get_tree().create_timer(duracao_ko, true, false, true).timeout
	Engine.time_scale = 1.0
	GerenciadorCenas.trocar_cena(CENA_FIM)


func _exit_tree() -> void:
	Engine.time_scale = 1.0  # garante que a câmera lenta não vaze para outra cena
