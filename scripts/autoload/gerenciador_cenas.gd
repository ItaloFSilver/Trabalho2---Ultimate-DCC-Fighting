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

## Música das telas de menu (menu inicial, instruções, créditos e seleção).
const MUSICA_MENU := "res://assets/sons/trilha_sonora.mp3"
## Volume da música dos menus, em decibéis (dB). 0 = volume original do arquivo;
## valores negativos abaixam: -6 ≈ metade da força, -10 ≈ bem mais baixo, -20 ≈ fundo.
const VOLUME_MUSICA_MENU_DB := -20.0

## Cena -> música. Ao trocar entre telas com a mesma música, ela continua sem reiniciar.
const MUSICAS_POR_CENA := {
	"res://scenes/ui/menu_principal.tscn": MUSICA_MENU,
	"res://scenes/ui/instrucoes.tscn": MUSICA_MENU,
	"res://scenes/ui/creditos.tscn": MUSICA_MENU,
	"res://scenes/ui/selecao_personagem.tscn": MUSICA_MENU,
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
	else:
		tocar_musica_da_cena(caminho)
	await get_tree().process_frame  # a troca de cena acontece no fim do quadro

	fade = create_tween()
	fade.tween_property(_cortina, "modulate:a", 0.0, DURACAO_FADE)
	await fade.finished

	_cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	em_transicao = false
	transicao_terminada.emit()



## Toca a música associada à cena (se houver). O menu chama isto ao abrir o jogo,
## porque a primeira cena é aberta pela Godot, sem passar por trocar_cena().
func tocar_musica_da_cena(caminho: String) -> void:
	if MUSICAS_POR_CENA.has(caminho):
		Audio.tocar_musica(MUSICAS_POR_CENA[caminho], 0.8, VOLUME_MUSICA_MENU_DB)
