extends Node
## Dados da partida atual, compartilhados entre as telas.
## Registrado como autoload "Partida" (Projeto > Configurações > Globais).
##
## Quem preenche:
##   - seleção de personagem: personagem_p1 e personagem_p2
##   - arena (scripts/arena.gd), quando um lutador é derrotado:
##         Partida.registrar_derrota(numero_do_perdedor)

## Cena de luta de cada personagem, pelo id usado na seleção.
## Para adicionar um professor: crie a cena herdada de fighter.tscn e acrescente aqui.
const CENAS_PERSONAGENS := {
	"caniato": preload("res://scenes/Caniato.tscn"),
	"gleiph": preload("res://scenes/Gleiph.tscn"),
	"knop": preload("res://scenes/Knop.tscn"),
	"stroele": preload("res://scenes/Stroele.tscn"),
}

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


## Guarda o resultado a partir de quem perdeu (1 ou 2).
func registrar_derrota(jogador_perdedor: int) -> void:
	vencedor = 2 if jogador_perdedor == 1 else 1
