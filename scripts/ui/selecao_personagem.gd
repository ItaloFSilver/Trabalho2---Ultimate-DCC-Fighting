extends Control
## Seleção de personagem em turnos: primeiro o Player 1 escolhe, depois o Player 2.
##
## Controles:
##   - setas / WASD / mouse: mover a seleção
##   - Enter, Espaço ou clique: escolher (C também vale na vez do P1, K na vez do P2)
##   - V desfaz a escolha do P1, L desfaz a do P2
##   - Esc volta ao menu
## START só fica habilitado quando os dois jogadores escolheram.

const CENA_MENU := "res://scenes/ui/menu_principal.tscn"
const CENA_LUTA := "res://scenes/main_game.tscn"

@onready var cartas: Array[CartaPersonagem] = [
	$Cartas/Caniato, $Cartas/Gleiph, $Cartas/Igor, $Cartas/Victor,
]
@onready var painel_p1: PainelJogador = $PainelP1
@onready var painel_p2: PainelJogador = $PainelP2
@onready var vez: Label = $Vez
@onready var botao_voltar: Button = $Voltar
@onready var botao_start: Button = $Start

var escolha_p1: CartaPersonagem = null
var escolha_p2: CartaPersonagem = null
var _saindo := false


func _ready() -> void:
	var n := cartas.size()
	for i in n:
		var carta := cartas[i]
		# navegação: esquerda/direita circular; para baixo vai para os botões
		carta.focus_neighbor_left = carta.get_path_to(cartas[(i - 1 + n) % n])
		carta.focus_neighbor_right = carta.get_path_to(cartas[(i + 1) % n])
		carta.focus_neighbor_top = carta.get_path_to(carta)
		carta.pressed.connect(_escolher.bind(carta))
		carta.focus_entered.connect(_atualizar_previa)
	_atualizar_tela()
	cartas[0].grab_focus()


## 1 = vez do P1, 2 = vez do P2, 0 = os dois já escolheram.
func turno() -> int:
	if escolha_p1 == null:
		return 1
	if escolha_p2 == null:
		return 2
	return 0


func _unhandled_input(event: InputEvent) -> void:
	if _saindo:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_voltar_pressed()
	elif event.is_action_pressed("p1_kick"):
		_desfazer(1)
	elif event.is_action_pressed("p2_kick"):
		_desfazer(2)
	elif event.is_action_pressed("p1_punch") and turno() == 1:
		_confirmar_foco()
	elif event.is_action_pressed("p2_punch") and turno() == 2:
		_confirmar_foco()
	else:
		# WASD movem a seleção como as setas (as setas já são ui_left/ui_right/...)
		for par in [["p1_left", "ui_left"], ["p1_right", "ui_right"], ["p1_up", "ui_up"], ["p1_down", "ui_down"]]:
			if event.is_action_pressed(par[0]):
				_simular_acao(par[1])
				break
		return
	get_viewport().set_input_as_handled()


func _simular_acao(acao: String) -> void:
	var ev := InputEventAction.new()
	ev.action = acao
	ev.pressed = true
	Input.parse_input_event(ev)
	get_viewport().set_input_as_handled()


func _confirmar_foco() -> void:
	var carta := get_viewport().gui_get_focus_owner() as CartaPersonagem
	if carta:
		_escolher(carta)


func _escolher(carta: CartaPersonagem) -> void:
	match turno():
		1:
			escolha_p1 = carta
		2:
			escolha_p2 = carta
		_:
			return  # os dois já escolheram: só falta o START
	_atualizar_tela()
	if turno() == 0:
		botao_start.grab_focus()


func _desfazer(jogador: int) -> void:
	var carta: CartaPersonagem = escolha_p1 if jogador == 1 else escolha_p2
	if carta == null:
		return
	if jogador == 1:
		escolha_p1 = null
	else:
		escolha_p2 = null
	_atualizar_tela()
	carta.grab_focus()  # volta o cursor para a carta que foi desfeita


func _atualizar_tela() -> void:
	var t := turno()
	for carta in cartas:
		carta.marcar(carta == escolha_p1, carta == escolha_p2)
		# a cor da borda do cursor muda conforme a vez
		carta.theme_type_variation = [&"CartaPronto", &"CartaP1", &"CartaP2"][t]
	match t:
		1:
			vez.text = "VEZ DO PLAYER 1"
			vez.theme_type_variation = &"VezP1"
		2:
			vez.text = "VEZ DO PLAYER 2"
			vez.theme_type_variation = &"VezP2"
		0:
			vez.text = "PRONTOS! APERTE START"
			vez.theme_type_variation = &"VezPronto"
	botao_start.disabled = t != 0
	# das cartas, "para baixo" vai para o START quando ele está liberado
	for carta in cartas:
		carta.focus_neighbor_bottom = carta.get_path_to(botao_start if t == 0 else botao_voltar)
	_atualizar_previa()


## Atualiza os painéis laterais: escolha confirmada ou prévia da carta em foco.
func _atualizar_previa() -> void:
	var em_foco := get_viewport().gui_get_focus_owner() as CartaPersonagem
	var t := turno()
	if escolha_p1:
		painel_p1.mostrar(escolha_p1, true)
	else:
		painel_p1.mostrar(em_foco if t == 1 else null, false)
	if escolha_p2:
		painel_p2.mostrar(escolha_p2, true)
	else:
		painel_p2.mostrar(em_foco if t == 2 else null, false)


func _on_voltar_pressed() -> void:
	if _saindo or GerenciadorCenas.em_transicao:
		return
	_saindo = true
	Partida.reiniciar()
	GerenciadorCenas.trocar_cena(CENA_MENU)


func _on_start_pressed() -> void:
	if turno() != 0 or _saindo or GerenciadorCenas.em_transicao:
		return
	_saindo = true
	Partida.personagem_p1 = escolha_p1.id_personagem
	Partida.personagem_p2 = escolha_p2.id_personagem
	Partida.nova_luta()
	GerenciadorCenas.trocar_cena(CENA_LUTA)
