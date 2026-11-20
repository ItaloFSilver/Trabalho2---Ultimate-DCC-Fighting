extends Button
## Botão de menu que mostra a seta (nó filho "Seta") quando está selecionado.
## Passar o mouse por cima também seleciona o botão.

@onready var seta: CanvasItem = $Seta


func _ready() -> void:
	seta.visible = has_focus()
	focus_entered.connect(func(): seta.visible = true)
	focus_exited.connect(func(): seta.visible = false)
	mouse_entered.connect(grab_focus)
