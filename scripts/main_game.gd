extends Node2D

@export var fighters_scenes: Dictionary = {
	&"caniato": preload("res://scenes/Caniato.tscn"),
	&"gleiph": preload("res://scenes/Gleiph.tscn"),
	&"knop": preload("res://scenes/Knop.tscn"),
	&"victor": preload("res://scenes/Stroele.tscn"),
	&"stroele": preload("res://scenes/Stroele.tscn"),
}

## Trilha sonora da luta (pode trocar pelo seletor de arquivo no Inspector).
@export_file("*.mp3", "*.ogg", "*.wav") var musica_arena := "res://assets/sons/lutaPrincipal.mp3"

@onready var spawn_p1: Marker2D = $SpawnP1
@onready var spawn_p2: Marker2D = $SpawnP2
@onready var camera: DynamicCamera = $Camera2D

var player1: FighterBase
var player2: FighterBase


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

		# Câmera dinâmica
		camera.player1 = player1
		camera.player2 = player2

		# HUD de combate
		var hud := HudCombate.new()
		add_child(hud)
		hud.configurar(player1, player2)
		print("MainGame: HUD criado")

	# Trilha sonora
	print("MainGame: tocando música -> ", musica_arena)
	Audio.tocar_musica(musica_arena)
