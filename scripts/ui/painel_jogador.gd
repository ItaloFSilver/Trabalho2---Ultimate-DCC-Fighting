@tool
class_name PainelJogador
extends PanelContainer
## Painel lateral da seleção: mostra o personagem do Player 1 ou 2.

const ESCALA_RETRATO := 4

@export_range(1, 2) var jogador := 1:
	set(valor):
		jogador = valor
		_atualizar_jogador()

@onready var titulo: Label = $Conteudo/Jogador
@onready var retrato: TextureRect = $Conteudo/Centro/Moldura/CentroRetrato/Retrato
@onready var nome: Label = $Conteudo/Nome
@onready var status: Label = $Conteudo/Status


func _ready() -> void:
	_atualizar_jogador()
	if not Engine.is_editor_hint():
		mostrar(null, false)


## carta = personagem em destaque (null = nenhum); pronto = escolha confirmada.
func mostrar(carta: CartaPersonagem, pronto: bool) -> void:
	if carta == null:
		retrato.texture = null
		nome.text = "-"
	else:
		retrato.texture = carta.retrato
		retrato.custom_minimum_size = carta.retrato.get_size() * ESCALA_RETRATO
		nome.text = carta.nome_exibido
	retrato.modulate.a = 1.0 if pronto else 0.6
	nome.theme_type_variation = &"NomePersonagem" if pronto else &"NomePrevia"
	status.text = "PRONTO!" if pronto else "escolhendo..."
	status.theme_type_variation = &"StatusPronto" if pronto else &"StatusEscolhendo"


func _atualizar_jogador() -> void:
	if not is_node_ready():
		return
	theme_type_variation = &"PainelP1" if jogador == 1 else &"PainelP2"
	titulo.text = "PLAYER %d" % jogador
	titulo.theme_type_variation = &"JogadorP1" if jogador == 1 else &"JogadorP2"
	retrato.flip_h = jogador == 2  # o P2 olha para a esquerda, de frente para o P1
