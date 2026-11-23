extends Control
## Menu inicial do Ultimate DCC Fighting: Jogar, Instruções, Créditos e Sair.
## Layout, cores e fontes ficam na cena e no tema (assets/ui/tema_ui.tres);
## os sinais "pressed" dos botões estão conectados pelo editor (aba Nó > Sinais).

## Cena aberta por "Jogar": a seleção de personagem.
const CENA_JOGAR := "res://scenes/ui/selecao_personagem.tscn"
const CENA_INSTRUCOES := "res://scenes/ui/instrucoes.tscn"
const CENA_CREDITOS := "res://scenes/ui/creditos.tscn"

@onready var botoes: Array[Button] = [$Opcoes/Jogar, $Opcoes/Instrucoes, $Opcoes/Creditos, $Opcoes/Sair]

var _escolheu := false


func _ready() -> void:
	botoes[0].grab_focus()
	# ao abrir o jogo, o menu é a primeira cena: começa a música dos menus aqui
	GerenciadorCenas.tocar_musica_da_cena(scene_file_path)


func _unhandled_input(event: InputEvent) -> void:
	# Setas e Enter/Espaço já funcionam pelo foco da Godot (ui_up/ui_down/ui_accept).
	# Aqui só acrescentamos W/S, que no projeto são p1_up/p1_down.
	if _escolheu:
		return
	if event.is_action_pressed("p1_up"):
		_mover_selecao(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("p1_down"):
		_mover_selecao(1)
		get_viewport().set_input_as_handled()


func _mover_selecao(direcao: int) -> void:
	var atual := botoes.find(get_viewport().gui_get_focus_owner())
	if atual == -1:
		atual = 0
	botoes[(atual + direcao + botoes.size()) % botoes.size()].grab_focus()


func _pode_escolher() -> bool:
	if _escolheu or GerenciadorCenas.em_transicao:
		return false
	_escolheu = true
	return true


func _on_jogar_pressed() -> void:
	if _pode_escolher():
		GerenciadorCenas.trocar_cena(CENA_JOGAR)


func _on_instrucoes_pressed() -> void:
	if _pode_escolher():
		GerenciadorCenas.trocar_cena(CENA_INSTRUCOES)


func _on_creditos_pressed() -> void:
	if _pode_escolher():
		GerenciadorCenas.trocar_cena(CENA_CREDITOS)


func _on_sair_pressed() -> void:
	if _pode_escolher():
		get_tree().quit()
