extends CanvasLayer
## Troca de cenas com fade preto.
## Registrado como autoload "GerenciadorCenas" (Projeto > Configurações > Globais).
## Uso: GerenciadorCenas.trocar_cena("res://scenes/ui/menu_principal.tscn")
##
## Também troca a música: se a cena que está abrindo estiver em MUSICAS_POR_CENA,
## a música correspondente começa (com crossfade) assim que a cena carrega.
## Cenas que não estão na lista mantêm a música que já estava tocando.
## (A música do combate é iniciada pela própria arena.)

signal transicao_terminada

const DURACAO_FADE := 0.25

## Cena -> música. AJUSTE os caminhos para os das suas cenas e arquivos.
const MUSICAS_POR_CENA := {
	"res://scenes/ui/selecao_personagem.tscn": "res://assets/sons/trilha_sonora.mp3",
}

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
	print("GerenciadorCenas: abrindo -> ", caminho, " | música mapeada: ", MUSICAS_POR_CENA.get(caminho, "nenhuma"))
	em_transicao = true
	_cortina.mouse_filter = Control.MOUSE_FILTER_STOP  # bloqueia cliques durante o fade

	var fade := create_tween()
	fade.tween_property(_cortina, "modulate:a", 1.0, DURACAO_FADE)
	await fade.finished

	var erro := get_tree().change_scene_to_file(caminho)
	if erro != OK:
		push_error("GerenciadorCenas: não foi possível abrir '%s' (erro %d)" % [caminho, erro])
	elif MUSICAS_POR_CENA.has(caminho):
		Audio.tocar_musica(MUSICAS_POR_CENA[caminho])
	await get_tree().process_frame  # a troca de cena acontece no fim do quadro

	fade = create_tween()
	fade.tween_property(_cortina, "modulate:a", 0.0, DURACAO_FADE)
	await fade.finished

	_cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	em_transicao = false
	transicao_terminada.emit()
