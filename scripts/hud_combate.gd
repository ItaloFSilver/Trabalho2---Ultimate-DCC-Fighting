extends CanvasLayer
class_name HudCombate
## HUD de combate. Criado inteiramente por código: basta chamar
##   var hud := HudCombate.new(); add_child(hud); hud.configurar(lutador_p1, lutador_p2)
## Mostra barra de vida (com "barra fantasma" que desce devagar), barra de especial,
## nome de cada lutador e o aviso de K.O.

const COR_VIDA := Color(0.25, 0.85, 0.35)
const COR_VIDA_BAIXA := Color(0.9, 0.2, 0.2)
const COR_FANTASMA := Color(1.0, 0.85, 0.2)
const COR_ESPECIAL := Color(0.3, 0.6, 1.0)
const COR_ESPECIAL_CHEIO := Color(1.0, 0.9, 0.3)
const COR_FUNDO := Color(0.1, 0.1, 0.12, 0.85)

const LARGURA_BARRA := 520.0
const ALTURA_VIDA := 28.0
const ALTURA_ESPECIAL := 14.0
const MARGEM := 40.0

var _lados := {}  # numero do jogador -> { vida, fantasma, especial, lutador }
var _label_ko: Label
var _tween_especial := {}


func _init() -> void:
	layer = 10


func configurar(p1: FighterBase, p2: FighterBase) -> void:
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz)

	_criar_lado(raiz, p1, 1)
	_criar_lado(raiz, p2, 2)

	_label_ko = Label.new()
	_label_ko.text = "K.O.!"
	_label_ko.visible = false
	_label_ko.add_theme_font_size_override("font_size", 120)
	_label_ko.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	_label_ko.add_theme_color_override("font_outline_color", Color.BLACK)
	_label_ko.add_theme_constant_override("outline_size", 16)
	_label_ko.set_anchors_preset(Control.PRESET_CENTER)
	_label_ko.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label_ko.grow_vertical = Control.GROW_DIRECTION_BOTH
	_label_ko.pivot_offset = Vector2(150, 70)
	raiz.add_child(_label_ko)


func _criar_lado(raiz: Control, lutador: FighterBase, numero: int) -> void:
	var esquerda := numero == 1
	var x := MARGEM if esquerda else get_viewport().get_visible_rect().size.x - MARGEM - LARGURA_BARRA

	# Fundo da barra de vida
	var fundo := ColorRect.new()
	fundo.color = COR_FUNDO
	fundo.position = Vector2(x - 4, MARGEM - 4)
	fundo.size = Vector2(LARGURA_BARRA + 8, ALTURA_VIDA + 8)
	raiz.add_child(fundo)

	# Barra fantasma (amarela), por baixo da barra de vida
	var fantasma := ProgressBar.new()
	_estilizar_barra(fantasma, COR_FANTASMA, ALTURA_VIDA, lutador.max_health, !esquerda)
	fantasma.position = Vector2(x, MARGEM)
	raiz.add_child(fantasma)

	var vida := ProgressBar.new()
	_estilizar_barra(vida, COR_VIDA, ALTURA_VIDA, lutador.max_health, !esquerda)
	vida.position = Vector2(x, MARGEM)
	raiz.add_child(vida)

	# Barra de especial
	var fundo_esp := ColorRect.new()
	fundo_esp.color = COR_FUNDO
	fundo_esp.position = Vector2(x - 2, MARGEM + ALTURA_VIDA + 8)
	fundo_esp.size = Vector2(LARGURA_BARRA * 0.6 + 4, ALTURA_ESPECIAL + 4)
	if not esquerda:
		fundo_esp.position.x = x + LARGURA_BARRA - fundo_esp.size.x + 2
	raiz.add_child(fundo_esp)

	var especial := ProgressBar.new()
	# a largura vai direto no _estilizar_barra: mudar o custom_minimum_size depois não
	# encolhe a barra na hora (a Godot atualiza o tamanho mínimo depois), e ela ficava com
	# a largura da barra de vida, passando para fora da tela no lado do P2
	_estilizar_barra(especial, COR_ESPECIAL, ALTURA_ESPECIAL, lutador.max_special, !esquerda, LARGURA_BARRA * 0.6)
	especial.position = Vector2(fundo_esp.position.x + 2, fundo_esp.position.y + 2)
	raiz.add_child(especial)

	# Nome
	var nome := Label.new()
	nome.text = _nome_do_lutador(lutador, numero)
	nome.add_theme_font_size_override("font_size", 22)
	nome.add_theme_color_override("font_outline_color", Color.BLACK)
	nome.add_theme_constant_override("outline_size", 6)
	nome.position = Vector2(x, MARGEM - 34)
	nome.size.x = LARGURA_BARRA
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if esquerda else HORIZONTAL_ALIGNMENT_RIGHT
	raiz.add_child(nome)

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


func _nome_do_lutador(lutador: FighterBase, numero: int) -> String:
	var id: String = Partida.personagem_p1 if numero == 1 else Partida.personagem_p2
	if id == "":
		id = String(lutador.name)
	return "P%d  %s" % [numero, id.capitalize()]


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


func _on_derrotado(_lutador: FighterBase) -> void:
	_label_ko.visible = true
	_label_ko.scale = Vector2(3, 3)
	_label_ko.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_label_ko, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_label_ko, "modulate:a", 1.0, 0.15)
