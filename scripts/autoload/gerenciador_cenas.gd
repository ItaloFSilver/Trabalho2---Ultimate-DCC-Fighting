extends CanvasLayer
## Troca de cenas com fade preto.
## Registrado como autoload "GerenciadorCenas" (Projeto > Configurações > Globais).
## Uso: GerenciadorCenas.trocar_cena("res://scenes/ui/menu_principal.tscn")

signal transicao_terminada

const DURACAO_FADE := 0.25

var em_transicao := false
var _cortina: ColorRect


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cortina = ColorRect.new()
	_cortina.color = Color.BLACK
	_cortina.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cortina.modulate.a = 0.0
	add_child(_cortina)


func trocar_cena(caminho: String) -> void:
	if em_transicao:
		return
	em_transicao = true
	_cortina.mouse_filter = Control.MOUSE_FILTER_STOP  # bloqueia cliques durante o fade

	var fade := create_tween()
	fade.tween_property(_cortina, "modulate:a", 1.0, DURACAO_FADE)
	await fade.finished

	var erro := get_tree().change_scene_to_file(caminho)
	if erro != OK:
		push_error("GerenciadorCenas: não foi possível abrir '%s' (erro %d)" % [caminho, erro])
	await get_tree().process_frame  # a troca de cena acontece no fim do quadro

	fade = create_tween()
	fade.tween_property(_cortina, "modulate:a", 0.0, DURACAO_FADE)
	await fade.finished

	_cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	em_transicao = false
	transicao_terminada.emit()
