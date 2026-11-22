extends Node

const BARRA_MUSICA := "Musica"
const BARRA_SFX := "SFX"
const TAMANHO_POOL_SFX := 12

## Nome do efeito -> caminho do arquivo. Edite aqui conforme for criando os sons.
const SFX := {
	"soco": "res://assets/sons/soco.mp3",
	"chute": "res://assets/sons/chute.mp3",
	"finalizador": "res://assets/sons/finalizador.mp3",
	"bloqueio": "res://assets/sons/bloqueio.mp3",
	"pulo": "res://assets/sons/pulo.mp3",
	"especial": "res://assets/sons/especial.mp3",
	"especial_pronto": "res://assets/sons/especial.mp3",
	"derrota": "res://assets/sons/derrota.mp3",
	"ko": "res://assets/sons/ko.mp3",
	"menu_mover": "res://assets/sons/menu.mp3",
	"menu_confirmar": "res://assets/sons/menu.mp3",
}

var _cache := {}
var _pool: Array[AudioStreamPlayer] = []
var _musica_a: AudioStreamPlayer
var _musica_b: AudioStreamPlayer
var _musica_ativa: AudioStreamPlayer
var _musica_atual := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # continua tocando durante pausa/câmera lenta
	_garantir_barras()

	_musica_a = _criar_player(BARRA_MUSICA)
	_musica_b = _criar_player(BARRA_MUSICA)
	_musica_ativa = _musica_a
	for i in TAMANHO_POOL_SFX:
		_pool.append(_criar_player(BARRA_SFX))


# ---------- Música ----------

func tocar_musica(caminho: String, fade := 0.8, volume_db := 0.0) -> void:
	if caminho == _musica_atual and _musica_ativa.playing:
		return  # já está tocando
	var stream := _carregar(caminho)
	if stream == null:
		return
	# música em loop (para .wav, ative o loop na aba Import do arquivo)
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = true

	var saindo := _musica_ativa
	var entrando := _musica_b if _musica_ativa == _musica_a else _musica_a
	_musica_ativa = entrando
	_musica_atual = caminho

	entrando.stream = stream
	entrando.volume_db = -60.0
	entrando.play()

	var tween := create_tween().set_parallel(true)
	tween.tween_property(entrando, "volume_db", volume_db, fade)
	if saindo.playing:
		tween.tween_property(saindo, "volume_db", -60.0, fade)
		tween.chain().tween_callback(saindo.stop)


func parar_musica(fade := 0.6) -> void:
	_musica_atual = ""
	if not _musica_ativa.playing:
		return
	var player := _musica_ativa
	var tween := create_tween()
	tween.tween_property(player, "volume_db", -60.0, fade)
	tween.tween_callback(player.stop)


# ---------- Efeitos sonoros ----------

func tocar_sfx(nome: String, variacao_pitch := 0.0, volume_db := 0.0) -> void:
	var caminho: String = SFX.get(nome, "")
	if caminho == "":
		push_warning("Audio: efeito '%s' não cadastrado em SFX" % nome)
		return
	var stream := _carregar(caminho)
	if stream == null:
		return
	var player := _player_livre()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-variacao_pitch, variacao_pitch)
	player.play()


# ---------- Volume (para uma tela de opções) ----------

## valor de 0.0 a 1.0
func definir_volume_musica(valor: float) -> void:
	_definir_volume_barra(BARRA_MUSICA, valor)

func definir_volume_sfx(valor: float) -> void:
	_definir_volume_barra(BARRA_SFX, valor)


# ---------- Internos ----------

func _criar_player(barra: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = barra
	add_child(player)
	return player


func _player_livre() -> AudioStreamPlayer:
	for player in _pool:
		if not player.playing:
			return player
	return _pool[0]  # todos ocupados: reaproveita o primeiro


func _carregar(caminho: String) -> AudioStream:
	if _cache.has(caminho):
		return _cache[caminho]
	if not ResourceLoader.exists(caminho):
		push_warning("Audio: arquivo não encontrado: %s" % caminho)
		_cache[caminho] = null
		return null
	var stream := load(caminho) as AudioStream
	_cache[caminho] = stream
	return stream


func _garantir_barras() -> void:
	# cria as barras Musica e SFX por código, sem precisar abrir o editor de áudio
	for nome in [BARRA_MUSICA, BARRA_SFX]:
		if AudioServer.get_bus_index(nome) == -1:
			AudioServer.add_bus()
			var indice := AudioServer.bus_count - 1
			AudioServer.set_bus_name(indice, nome)
			AudioServer.set_bus_send(indice, "Master")


func _definir_volume_barra(barra: String, valor: float) -> void:
	var indice := AudioServer.get_bus_index(barra)
	AudioServer.set_bus_volume_db(indice, linear_to_db(clamp(valor, 0.0, 1.0)))
	AudioServer.set_bus_mute(indice, valor <= 0.001)
