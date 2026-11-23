@tool
class_name CartaPersonagem
extends Button

const ESCALA_RETRATO := 4      ## retratos são pixel art pequena; ampliação inteira
const BASE_RETRATO := 140.0    ## altura (y) onde ficam os pés do personagem

@export var id_personagem := "gleiph"
@export var nome_exibido := "Gleiph":
	set(valor):
		nome_exibido = valor
		_atualizar()
@export var retrato: Texture2D:
	set(valor):
		retrato = valor
		_atualizar()


func _ready() -> void:
	_atualizar()
	if Engine.is_editor_hint():
		return
	marcar(false, false)
	mouse_entered.connect(grab_focus)


## Mostra as etiquetas "P1" / "P2" de quem escolheu esta carta.
func marcar(p1: bool, p2: bool) -> void:
	$EtiquetaP1.visible = p1
	$EtiquetaP2.visible = p2


func _atualizar() -> void:
	if not is_node_ready():
		return
	$Nome.text = nome_exibido
	$Retrato.texture = retrato
	if retrato:
		var tam := retrato.get_size() * ESCALA_RETRATO
		$Retrato.size = tam
		$Retrato.position = Vector2((custom_minimum_size.x - tam.x) / 2.0, BASE_RETRATO - tam.y).floor()
