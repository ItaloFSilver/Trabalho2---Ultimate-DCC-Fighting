extends Control
## Tela de créditos. O texto fica nos Labels "Nomes" de cada seção (edite pelo Inspetor).
## O botão VOLTAR (sinal "pressed" conectado pelo editor) e o Esc voltam ao menu.

const CENA_MENU := "res://scenes/ui/menu_principal.tscn"


func _ready() -> void:
	$Voltar.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_voltar_pressed()


func _on_voltar_pressed() -> void:
	if not GerenciadorCenas.em_transicao:
		GerenciadorCenas.trocar_cena(CENA_MENU)
