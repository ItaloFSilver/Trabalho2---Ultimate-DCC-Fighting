extends CanvasLayer
class_name HudCombate
## HUD de combate. Criado inteiramente por código: basta chamar
##   var hud := HudCombate.new(); add_child(hud); hud.configurar(lutador_p1, lutador_p2)
## Mostra barra de vida (com "barra fantasma" que desce devagar), barra de especial,
## nome de cada lutador, o aviso de K.O., o vencedor e o botão de voltar ao início.
## Visual no estilo do menu principal: texto dourado com sombra marrom, molduras
## quadradas em azul-noite e seta amarela no botão selecionado.

# ---------- Paleta (a mesma do menu) ----------
const COR_OURO := Color(1.0, 0.82, 0.30)        # texto dos títulos
const COR_SOMBRA := Color(0.55, 0.30, 0.10)     # sombra marrom dos textos
const COR_DESTAQUE := Color(1.0, 0.95, 0.75)    # opção selecionada
const COR_OPCAO := Color(0.72, 0.58, 0.33)      # opção não selecionada
const COR_PAINEL := Color(0.06, 0.05, 0.14, 0.92)  # fundo azul-noite das barras
const COR_MOLDURA := Color(0.95, 0.75, 0.25)    # borda dourada

const COR_VIDA := Color(0.25, 0.85, 0.35)
const COR_VIDA_BAIXA := Color(0.9, 0.2, 0.2)
const COR_FANTASMA := Color(1.0, 0.85, 0.2)
const COR_ESPECIAL := Color(0.3, 0.6, 1.0)
const COR_ESPECIAL_CHEIO := Color(1.0, 0.9, 0.3)

const LARGURA_BARRA := 520.0
const ALTURA_VIDA := 28.0
const ALTURA_ESPECIAL := 14.0
const MARGEM := 40.0
## Quanto a barra de especial fica afastada da ponta da barra de vida.
const INSET_ESPECIAL := 18.0
## true  = barra de especial do P2 fica no lado ESQUERDO da barra de vida dele
##         (voltado para o centro da tela) e enche da esquerda para a direita.
## false = fica no lado direito, espelhando o P1.
const ESPECIAL_P2_NO_LADO_ESQUERDO := true

## Fonte pixel do jogo. Deixe vazio para o HUD procurar sozinho uma fonte em res://assets
## (o caminho encontrado aparece no Output). Para fixar, ex.: "res://assets/fonts/minha.ttf"
const CAMINHO_FONTE := ""

## Cena para onde o botão "Voltar ao início" leva. AJUSTE se o caminho for outro.
const CENA_MENU := "res://scenes/ui/menu_principal.tscn"

const SHADER_CINZA := """
shader_type canvas_item;
uniform sampler2D tela : hint_screen_texture, filter_linear_mipmap;
uniform float intensidade : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec4 c = texture(tela, SCREEN_UV);
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(c.rgb, vec3(g), intensidade), 1.0);
}
"""

var _lados := {}  # numero do jogador -> { vida, fantasma, especial, lutador }
var _label_ko: Label
var _raiz: Control
var _fonte: Font
var _tween_especial := {}
var _ko_acionado := false


func _init() -> void:
	layer = 10


func configurar(p1: FighterBase, p2: FighterBase) -> void:
	_preparar_fonte()

	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz)
	_raiz = raiz

	_criar_lado(raiz, p1, 1)
	_criar_lado(raiz, p2, 2)

	_label_ko = Label.new()
	_label_ko.text = "K.O.!"
	_label_ko.visible = false
	_estilizar_texto(_label_ko, 120, COR_OURO, 8)
	_label_ko.set_anchors_preset(Control.PRESET_CENTER)
	_label_ko.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label_ko.grow_vertical = Control.GROW_DIRECTION_BOTH
	_centralizar_pivo(_label_ko)
	raiz.add_child(_label_ko)


# ---------- Estilo ----------

func _preparar_fonte() -> void:
	var caminho := CAMINHO_FONTE
	if caminho == "" or not ResourceLoader.exists(caminho):
		caminho = _achar_fonte("res://assets" if DirAccess.dir_exists_absolute("res://assets") else "res://")
	if caminho != "":
		_fonte = load(caminho) as Font
		print("HudCombate: fonte -> ", caminho)


## Procura o primeiro arquivo de fonte dentro de uma pasta (e subpastas).
func _achar_fonte(pasta: String) -> String:
	var dir := DirAccess.open(pasta)
	if dir == null:
		return ""
	var subpastas: Array[String] = []
	dir.list_dir_begin()
	var nome := dir.get_next()
	while nome != "":
		if not nome.begins_with("."):
			var base := nome.trim_suffix(".import").trim_suffix(".remap")
			var caminho := pasta.path_join(base)
			if dir.current_is_dir():
				subpastas.append(caminho)
			elif base.get_extension().to_lower() in ["ttf", "otf", "woff", "woff2"]:
				dir.list_dir_end()
				return caminho
		nome = dir.get_next()
	dir.list_dir_end()
	for sub in subpastas:
		var achado := _achar_fonte(sub)
		if achado != "":
			return achado
	return ""


## Texto dourado com sombra marrom, como os títulos do menu.
func _estilizar_texto(controle: Control, tamanho: int, cor: Color = COR_OURO, sombra: int = 3) -> void:
	if _fonte:
		controle.add_theme_font_override("font", _fonte)
	controle.add_theme_font_size_override("font_size", tamanho)
	controle.add_theme_color_override("font_color", cor)
	controle.add_theme_color_override("font_shadow_color", COR_SOMBRA)
	controle.add_theme_constant_override("shadow_offset_x", sombra)
	controle.add_theme_constant_override("shadow_offset_y", sombra)


## Painel quadrado (sem cantos arredondados) com borda.
func _painel(posicao: Vector2, tamanho: Vector2, cor_fundo: Color, cor_borda: Color, borda := 3) -> Panel:
	var painel := Panel.new()
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor_fundo
	estilo.set_border_width_all(borda)
	estilo.border_color = cor_borda
	painel.add_theme_stylebox_override("panel", estilo)
	painel.position = posicao
	painel.size = tamanho
	return painel


## Moldura azul-noite com borda dourada e uma "sombra" marrom deslocada, no estilo do menu.
func _moldura(pai: Control, posicao: Vector2, tamanho: Vector2, borda := 3) -> void:
	pai.add_child(_painel(posicao + Vector2(4, 4), tamanho, COR_SOMBRA, COR_SOMBRA, borda))
	pai.add_child(_painel(posicao, tamanho, COR_PAINEL, COR_MOLDURA, borda))


## Mantém o pivô de escala no centro do controle (para as animações de "pop").
func _centralizar_pivo(controle: Control) -> void:
	controle.resized.connect(func(): controle.pivot_offset = controle.size / 2.0)


# ---------- Barras ----------

func _criar_lado(raiz: Control, lutador: FighterBase, numero: int) -> void:
	var esquerda := numero == 1

	# Contêiner ancorado no canto do seu lado: acompanha o tamanho da janela,
	# então o P2 fica sempre na mesma distância da borda direita.
	var lado := Control.new()
	lado.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if esquerda:
		lado.set_anchors_preset(Control.PRESET_TOP_LEFT)
		lado.offset_left = MARGEM
		lado.offset_right = MARGEM + LARGURA_BARRA
	else:
		lado.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		lado.offset_left = -(MARGEM + LARGURA_BARRA)
		lado.offset_right = -MARGEM
	lado.offset_top = 0.0
	lado.offset_bottom = 100.0
	raiz.add_child(lado)

	# Moldura da barra de vida
	_moldura(lado, Vector2(-5, MARGEM - 5), Vector2(LARGURA_BARRA + 10, ALTURA_VIDA + 10))

	# Barra fantasma (amarela), por baixo da barra de vida
	var fantasma := ProgressBar.new()
	_estilizar_barra(fantasma, COR_FANTASMA, ALTURA_VIDA, lutador.max_health, !esquerda)
	fantasma.position = Vector2(0, MARGEM)
	lado.add_child(fantasma)

	var vida := ProgressBar.new()
	_estilizar_barra(vida, COR_VIDA, ALTURA_VIDA, lutador.max_health, !esquerda)
	vida.position = Vector2(0, MARGEM)
	lado.add_child(vida)

	# Barra de especial
	var largura_esp := LARGURA_BARRA * 0.6
	var esp_na_direita := not esquerda and not ESPECIAL_P2_NO_LADO_ESQUERDO
	var x_esp := LARGURA_BARRA - largura_esp - INSET_ESPECIAL if esp_na_direita else INSET_ESPECIAL
	var y_esp := MARGEM + ALTURA_VIDA + 12.0

	_moldura(lado, Vector2(x_esp - 4, y_esp - 4), Vector2(largura_esp + 8, ALTURA_ESPECIAL + 8), 2)

	var especial := ProgressBar.new()
	# a largura vai direto no _estilizar_barra: mudar o custom_minimum_size depois não
	# encolhe a barra na hora (a Godot atualiza o tamanho mínimo depois), e ela ficava
	# com a largura da barra de vida, passando para fora da tela no lado do P2
	_estilizar_barra(especial, COR_ESPECIAL, ALTURA_ESPECIAL, lutador.max_special, esp_na_direita, largura_esp)
	especial.position = Vector2(x_esp, y_esp)
	lado.add_child(especial)

	# Nome
	var nome := Label.new()
	nome.text = _nome_do_lutador(lutador, numero)
	_estilizar_texto(nome, 24, COR_OURO, 3)
	nome.position = Vector2(0, MARGEM - 40)
	nome.size.x = LARGURA_BARRA
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if esquerda else HORIZONTAL_ALIGNMENT_RIGHT
	lado.add_child(nome)

	_lados[numero] = {"vida": vida, "fantasma": fantasma, "especial": especial, "lutador": lutador}

	vida.value = lutador.health
	fantasma.value = lutador.health
	especial.value = lutador.special_meter

	lutador.vida_mudou.connect(_on_vida_mudou.bind(numero))
	lutador.especial_mudou.connect(_on_especial_mudou.bind(numero))
	lutador.derrotado.connect(_on_derrotado)


func _estilizar_barra(barra: ProgressBar, cor: Color, altura: float, maximo: float, invertida: bool, largura := LARGURA_BARRA) -> void:
	barra.show_percentage = false
	barra.min_value = 0.0
	barra.max_value = maximo
	barra.value = maximo
	barra.custom_minimum_size = Vector2(largura, altura)
	barra.size = Vector2(largura, altura)
	barra.fill_mode = ProgressBar.FILL_END_TO_BEGIN if invertida else ProgressBar.FILL_BEGIN_TO_END
	var preenchimento := StyleBoxFlat.new()
	preenchimento.bg_color = cor
	barra.add_theme_stylebox_override("fill", preenchimento)
	barra.add_theme_stylebox_override("background", StyleBoxEmpty.new())


func _id_do_lutador(lutador: FighterBase, numero: int) -> String:
	var id: String = Partida.personagem_p1 if numero == 1 else Partida.personagem_p2
	if id == "":
		id = String(lutador.name)
	return id.capitalize()


func _nome_do_lutador(lutador: FighterBase, numero: int) -> String:
	return "P%d  %s" % [numero, _id_do_lutador(lutador, numero)]


func _on_vida_mudou(atual: float, maximo: float, numero: int) -> void:
	var lado: Dictionary = _lados[numero]
	var vida: ProgressBar = lado["vida"]
	var fantasma: ProgressBar = lado["fantasma"]
	vida.value = max(atual, 0.0)
	var proporcao := atual / maximo
	var cor := COR_VIDA.lerp(COR_VIDA_BAIXA, clamp(1.0 - proporcao * 2.0, 0.0, 1.0))
	(vida.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = cor

	# a barra amarela desce depois de um instante, mostrando quanto foi perdido
	var tween := create_tween()
	tween.tween_interval(0.4)
	tween.tween_property(fantasma, "value", max(atual, 0.0), 0.5)


func _on_especial_mudou(atual: float, maximo: float, numero: int) -> void:
	var barra: ProgressBar = _lados[numero]["especial"]
	barra.value = atual
	var cheio := atual >= maximo
	(barra.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = COR_ESPECIAL_CHEIO if cheio else COR_ESPECIAL
	if _tween_especial.has(numero) and _tween_especial[numero]:
		_tween_especial[numero].kill()
	if cheio:
		# pisca para avisar que o especial está pronto
		var tween := create_tween().set_loops()
		tween.tween_property(barra, "modulate", Color(1.6, 1.6, 1.6), 0.25)
		tween.tween_property(barra, "modulate", Color.WHITE, 0.25)
		_tween_especial[numero] = tween
	else:
		barra.modulate = Color.WHITE


# ---------- K.O. ----------

## Deixa a tela em preto e branco (o HUD, que fica numa camada acima, continua colorido).
func _escurecer_tela() -> void:
	var camada := CanvasLayer.new()
	camada.layer = layer - 5  # abaixo do HUD
	var filtro := ColorRect.new()
	filtro.set_anchors_preset(Control.PRESET_FULL_RECT)
	filtro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = SHADER_CINZA
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("intensidade", 0.0)
	filtro.material = material
	camada.add_child(filtro)
	get_parent().add_child(camada)  # fica na cena de luta e some junto com ela

	var tween := create_tween()
	tween.tween_property(material, "shader_parameter/intensidade", 1.0, 0.2)


func _on_derrotado(perdedor: FighterBase) -> void:
	if _ko_acionado:
		return  # os dois caíram juntos: o efeito só acontece uma vez
	_ko_acionado = true
	Partida.registrar_derrota(perdedor.numero_jogador())
	Audio.parar_musica(0.5)
	_escurecer_tela()

	_label_ko.visible = true
	_label_ko.scale = Vector2(3, 3)
	_label_ko.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_label_ko, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_label_ko, "modulate:a", 1.0, 0.15)

	# depois de um instante, mostra o vencedor e o botão (ignora a câmera lenta)
	await get_tree().create_timer(1.0, true, false, true).timeout
	_mostrar_fim(2 if perdedor.numero_jogador() == 1 else 1)


## Texto com o jogador vencedor + botão para voltar ao início.
## Usa o mesmo "pop" do K.O.!: aparece grande, encolhe com um quique e some o fade.
func _mostrar_fim(numero_vencedor: int) -> void:
	var lutador: FighterBase = _lados[numero_vencedor]["lutador"]

	var margem := MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	margem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margem.add_theme_constant_override("margin_top", int(get_viewport().get_visible_rect().size.y * 0.62))

	var caixa := VBoxContainer.new()
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.add_theme_constant_override("separation", 28)
	margem.add_child(caixa)

	var texto := Label.new()
	texto.text = "Jogador %d (%s) venceu!" % [numero_vencedor, _id_do_lutador(lutador, numero_vencedor)]
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_estilizar_texto(texto, 56, COR_OURO, 5)
	_centralizar_pivo(texto)
	caixa.add_child(texto)

	var botao := _criar_botao_menu("Voltar ao início")
	botao.pressed.connect(_voltar_ao_inicio)
	caixa.add_child(botao)

	texto.scale = Vector2(2.5, 2.5)
	texto.modulate.a = 0.0
	botao.scale = Vector2(0.5, 0.5)
	botao.modulate.a = 0.0

	_raiz.add_child(margem)
	botao.grab_focus()  # funciona também com teclado/controle (Enter / botão de confirmar)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(texto, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(texto, "modulate:a", 1.0, 0.15)
	# o botão entra logo depois do texto
	tween.tween_property(botao, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.2)
	tween.tween_property(botao, "modulate:a", 1.0, 0.15).set_delay(0.2)


## Botão no estilo do menu: só texto, bege quando parado, claro + seta amarela quando selecionado.
func _criar_botao_menu(texto: String) -> Button:
	var botao := Button.new()
	botao.text = texto
	botao.flat = true
	botao.custom_minimum_size = Vector2(420, 64)
	botao.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	botao.focus_mode = Control.FOCUS_ALL
	for estado in ["normal", "hover", "pressed", "focus", "disabled"]:
		botao.add_theme_stylebox_override(estado, StyleBoxEmpty.new())
	if _fonte:
		botao.add_theme_font_override("font", _fonte)
	botao.add_theme_font_size_override("font_size", 40)
	botao.add_theme_color_override("font_color", COR_OPCAO)
	for cor_nome in ["font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		botao.add_theme_color_override(cor_nome, COR_DESTAQUE)

	# seta amarela (desenhada como triângulo, não depende da fonte)
	var seta := Polygon2D.new()
	seta.polygon = PackedVector2Array([Vector2(0, 0), Vector2(22, 16), Vector2(0, 32)])
	seta.color = COR_OURO
	seta.position = Vector2(8, 16)
	seta.visible = false
	botao.add_child(seta)
	botao.focus_entered.connect(func(): seta.visible = true)
	botao.focus_exited.connect(func(): seta.visible = false)
	botao.mouse_entered.connect(botao.grab_focus)

	_centralizar_pivo(botao)
	return botao


func _voltar_ao_inicio() -> void:
	Engine.time_scale = 1.0
	Partida.reiniciar()
	GerenciadorCenas.trocar_cena(CENA_MENU)
