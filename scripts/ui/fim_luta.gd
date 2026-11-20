extends Control
## Tela de fim de luta: mostra quem "reprovou" (o jogador que perdeu)
## e oferece REVANCHE ou MENU. O resultado vem do autoload Partida.

const CENA_LUTA := "res://scenes/main_game.tscn"
const CENA_MENU := "res://scenes/ui/menu_principal.tscn"

## Vencedor usado só quando a tela é aberta direto (F6), sem passar pela luta.
@export_range(1, 2) var vencedor_teste: int = 1

@onready var jogador: Label = $Mensagem/Jogador
@onready var botoes: Array[Button] = [$Opcoes/Revanche, $Opcoes/Menu]

var _escolheu := false


func _ready() -> void:
	if Partida.vencedor == 0:
		Partida.vencedor = vencedor_teste
	jogador.text = "PLAYER %d" % Partida.perdedor()
	botoes[0].grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	# Setas e Enter/Espaço funcionam pelo foco da Godot; aqui só acrescentamos W/S.
	if _escolheu:
		return
	if event.is_action_pressed("p1_up") or event.is_action_pressed("p1_down"):
		var atual := botoes.find(get_viewport().gui_get_focus_owner())
		botoes[1 if atual == 0 else 0].grab_focus()
		get_viewport().set_input_as_handled()


func _pode_escolher() -> bool:
	if _escolheu or GerenciadorCenas.em_transicao:
		return false
	_escolheu = true
	return true


func _on_revanche_pressed() -> void:
	if _pode_escolher():
		Partida.nova_luta()
		GerenciadorCenas.trocar_cena(CENA_LUTA)


func _on_menu_pressed() -> void:
	if _pode_escolher():
		Partida.reiniciar()
		GerenciadorCenas.trocar_cena(CENA_MENU)
