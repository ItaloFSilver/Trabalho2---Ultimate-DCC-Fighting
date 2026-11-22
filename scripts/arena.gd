extends Node
## Script da arena (nó raiz de main_game.tscn).
##
## Ao iniciar, cria os dois lutadores escolhidos na seleção (Partida.personagem_p1/p2)
## nas posições dos marcadores SpawnP1 e SpawnP2.
## Quando um lutador é derrotado, a luta entra em câmera lenta por um instante
## (o "K.O.") e depois vai para a tela de fim de luta, informando quem perdeu.

const CENA_FIM := "res://scenes/ui/fim_luta.tscn"
## Trilha sonora da luta. Pode escolher o arquivo pelo Inspector (seletor de arquivo),
## sem precisar digitar o caminho.
@export_file("*.mp3", "*.ogg", "*.wav") var musica_arena := "res://assets/sons/lutaPrincipal.mp3"

## Personagens usados quando a luta é aberta direto (F6), sem passar pela seleção.
@export var personagem_teste_p1 := "gleiph"
@export var personagem_teste_p2 := "knop"

## Quanto tempo (em segundos reais) o K.O. dura antes da troca de tela.
@export var duracao_ko := 1.5
## Velocidade do jogo durante o K.O. (1.0 = normal).
@export_range(0.05, 1.0) var camera_lenta := 0.35

var lutador_p1: FighterBase
var lutador_p2: FighterBase
var _luta_encerrada := false


func _ready() -> void:
	var id_p1 := Partida.personagem_p1 if Partida.personagem_p1 != "" else personagem_teste_p1
	var id_p2 := Partida.personagem_p2 if Partida.personagem_p2 != "" else personagem_teste_p2

	lutador_p1 = _criar_lutador(id_p1, 1, $SpawnP1)
	lutador_p2 = _criar_lutador(id_p2, 2, $SpawnP2)
	# cada um olha para o outro
	lutador_p1.opponent = lutador_p2
	lutador_p2.opponent = lutador_p1
	add_child(lutador_p1)
	add_child(lutador_p2)

	lutador_p1.derrotado.connect(_on_lutador_derrotado)
	lutador_p2.derrotado.connect(_on_lutador_derrotado)

	# HUD (precisa vir depois de add_child: os lutadores já estão prontos)
	var hud := HudCombate.new()
	add_child(hud)
	hud.configurar(lutador_p1, lutador_p2)
	print("Arena: HUD criado")

	print("Arena: tocando música -> ", musica_arena)
	Audio.tocar_musica(musica_arena)


func _criar_lutador(id: String, jogador: int, spawn: Marker2D) -> FighterBase:
	var cena: PackedScene = Partida.CENAS_PERSONAGENS.get(id)
	if cena == null:
		push_error("Arena: personagem '%s' não está em Partida.CENAS_PERSONAGENS" % id)
		cena = Partida.CENAS_PERSONAGENS["gleiph"]
	var lutador := cena.instantiate() as FighterBase
	lutador.name = "LutadorP%d" % jogador
	lutador.player_prefix = "p%d_" % jogador
	lutador.position = spawn.position
	return lutador


func _on_lutador_derrotado(perdedor: FighterBase) -> void:
	if _luta_encerrada:
		return  # se os dois caírem juntos, vale quem caiu primeiro
	_luta_encerrada = true
	Partida.registrar_derrota(perdedor.numero_jogador())
	Audio.tocar_sfx("ko")
	Audio.parar_musica(1.0)

	Engine.time_scale = camera_lenta
	# timer que ignora a câmera lenta, para durar o mesmo tempo real
	await get_tree().create_timer(duracao_ko, true, false, true).timeout
	Engine.time_scale = 1.0
	GerenciadorCenas.trocar_cena(CENA_FIM)


func _exit_tree() -> void:
	Engine.time_scale = 1.0  # garante que a câmera lenta não vaze para outra cena
