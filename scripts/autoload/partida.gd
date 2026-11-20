extends Node
## Dados da partida atual, compartilhados entre as telas.
## Registrado como autoload "Partida" (Projeto > Configurações > Globais).
##
## Quem preenche:
##   - seleção de personagem: personagem_p1 e personagem_p2
##   - cena da luta, quando a vida de alguém zera:
##         Partida.vencedor = 1   # ou 2
##         GerenciadorCenas.trocar_cena("res://scenes/ui/fim_luta.tscn")

var personagem_p1 := ""
var personagem_p2 := ""
var vencedor := 0  ## 1 ou 2; 0 = luta ainda sem resultado


func perdedor() -> int:
	if vencedor == 0:
		return 0
	return 2 if vencedor == 1 else 1


## Zera o resultado mas mantém os personagens (usado na revanche).
func nova_luta() -> void:
	vencedor = 0


## Zera tudo (usado ao voltar para o menu).
func reiniciar() -> void:
	personagem_p1 = ""
	personagem_p2 = ""
	vencedor = 0
