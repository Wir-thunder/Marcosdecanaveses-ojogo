extends Node

# Sistema Global de Áudio para A Loja do Alquimista
var sfx_streams: Dictionary = {}
var bgm_streams: Dictionary = {}
var players_pool: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 12

var bgm_player: AudioStreamPlayer
var bgm_player_a: AudioStreamPlayer
var bgm_player_b: AudioStreamPlayer
var bgm_player_ativo: AudioStreamPlayer = null
var bgm_id_atual: String = ""
var _bgm_tween: Tween = null
var _bgm_base_vol_db: float = -7.5

var voice_player: AudioStreamPlayer = null
var _voice_base_vol_db: float = 0.0

var ambience_player: AudioStreamPlayer = null
var _ambience_base_vol_db: float = -7.5
var _ambience_tween: Tween = null

var _duck_db: float = 0.0
var _duck_tween: Tween = null

const AUDIO_SETTINGS_PATH: String = "user://audio_settings.cfg"
const BUS_COMBAT_P1: String = "CombatP1"
const BUS_COMBAT_P2: String = "CombatP2"

var _volume_musica_linear: float = 1.0
var _volume_sfx_linear: float = 1.0
var _volume_vozes_linear: float = 1.0

var volume_sfx_db: float = 0.0
var volume_musica_db: float = 0.0
var volume_vozes_db: float = 0.0

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	_carregar_configuracoes_audio()
	_configurar_buses_combate()
	_carregar_sfx()
	_criar_pool()
	_criar_bgm_player()
	_criar_voice_e_ambience_players()

func _carregar_sfx() -> void:
	var lista := {
		"moedas": "res://Assets/Audio/SFX/moedas.wav",
		"moeda": "res://Assets/Audio/SFX/moedas.wav",
		"caldeirao": "res://Assets/Audio/SFX/caldeirao.wav",
		"venda_sucesso": "res://Assets/Audio/SFX/venda_sucesso.wav",
		"pechincha_falha": "res://Assets/Audio/SFX/pechincha_falha.wav",
		"colheita": "res://Assets/Audio/SFX/colheita_sucesso.wav",
		"colheita_sucesso": "res://Assets/Audio/SFX/colheita_sucesso.wav",
		"picareta": "res://Assets/Audio/SFX/picareta.wav",
		"abrir_balcao": "res://Assets/Audio/SFX/abrir_balcao.wav",
		"soco": "res://Assets/Audio/SFX/soco.wav",
		"chute": "res://Assets/Audio/SFX/chute.wav",
		"bloqueio": "res://Assets/Audio/SFX/bloqueio.wav",
		"especial_hit": "res://Assets/Audio/SFX/especial_hit.wav",
		"golpe_ar": "res://Assets/Audio/SFX/golpe_ar.wav",
		"especial_disparo": "res://Assets/Audio/SFX/especial_disparo.wav",
		"fanfarra_vitoria": "res://Assets/Audio/SFX/fanfarra_vitoria.wav",
		# Novos assets ElevenLabs
		"sino_porta": "res://Assets/Audio/SFX/sino_porta.mp3",
		"pocao_pronta": "res://Assets/Audio/SFX/pocao_pronta.mp3",
		"pocao_magica": "res://Assets/Audio/SFX/Magical_potion_brewe_#3-1793631850587.mp3",
		"ambiente_loja": "res://Assets/Audio/SFX/Medieval_fantasy_sho_#3-1793631724512.mp3",
		"porta_pesada": "res://Assets/Audio/SFX/Heavy_medieval_woode_#2-1793631936449.mp3",
		"passo_madeira": "res://Assets/Audio/SFX/Short_subtle_wooden__#3-1793631999912.mp3",
		"cristal_coleta": "res://Assets/Audio/SFX/Super_satisfying_cri_#3-1793632145372.mp3",
		"vento_floresta": "res://Assets/Audio/SFX/Twig_snapping_and_wi_#3-1793632179201.mp3",
		"arbusto_passo": "res://Assets/Audio/SFX/Player_rustling_into_#4-1793632094682.mp3",
		"javali_investida": "res://Assets/Audio/SFX/Aggressive_wild_boar_#1-1793632042252.mp3",
		"impacto_cinematico": "res://Assets/Audio/SFX/Dramatic_heavy_cinem_#4-1793632360787.mp3",
		"super_especial": "res://Assets/Audio/SFX/Fighting_game_super__#4-1793632253693.mp3",
		"passo_tecido": "res://Assets/Audio/SFX/Quick_cloth_swoosh_a_#4-1793632283424.mp3",
		"porta_transicao": "res://Assets/Audio/SFX/porta_transicao.mp3",
		"ui_click": "res://Assets/Audio/SFX/ui_click.mp3",
		"javali_alerta": "res://Assets/Audio/SFX/javali_alerta.mp3",
		"moita_farfalhar": "res://Assets/Audio/SFX/moita_farfalhar.mp3",
		"colheita_perfeita": "res://Assets/Audio/SFX/colheita_perfeita.mp3",
		"colheita_falha": "res://Assets/Audio/SFX/colheita_falha.mp3",
		"especial_pronto": "res://Assets/Audio/SFX/especial_pronto.mp3",
		"lutador_pulo": "res://Assets/Audio/SFX/lutador_pulo.mp3",
		"lutador_ko": "res://Assets/Audio/SFX/lutador_ko.mp3",
		# Pacote Completo de Combate Arcade — Torneio de Tongóbriga
		"super_flash_freeze": "res://Assets/Audio/SFX/super_flash_freeze.mp3",
		"ko_impact_boom": "res://Assets/Audio/SFX/ko_impact_boom.mp3",
		"dash_esquiva": "res://Assets/Audio/SFX/dash_esquiva.mp3",
		"corte_lamina": "res://Assets/Audio/SFX/corte_lamina.wav",
		"impacto_macico_pedra": "res://Assets/Audio/SFX/impacto_macico_pedra.wav",
		"carnyx_trombeta_gaulesa": "res://Assets/Audio/SFX/carnyx_trombeta_gaulesa.wav",
		"trovao_eslavo_perun": "res://Assets/Audio/SFX/trovao_eslavo_perun.wav",
		"frasco_alquimico_explosao": "res://Assets/Audio/SFX/frasco_alquimico_explosao.wav",
		"rasteira_poeira": "res://Assets/Audio/SFX/rasteira_poeira.wav",
		"agarrao_trava": "res://Assets/Audio/SFX/agarrao_trava.wav",
		"counter_hit_bell": "res://Assets/Audio/SFX/counter_hit_bell.wav",
		"guard_crush": "res://Assets/Audio/SFX/guard_crush.wav",
		"aterragem_arena": "res://Assets/Audio/SFX/aterragem_arena.wav",
		"cursor_selecao_lutador": "res://Assets/Audio/SFX/cursor_selecao_lutador.wav",
		"confirmar_lutador_gongo": "res://Assets/Audio/SFX/confirmar_lutador_gongo.wav",
		"torcida_arena_reacao": "res://Assets/Audio/SFX/torcida_arena_reacao.wav",
		"timer_10s_alerta": "res://Assets/Audio/SFX/timer_10s_alerta.wav",
		# Locutor Arcade & Vozes dos 10 Campeões (Google Gemini 3.8 TTS)
		"announcer_round_1": "res://Assets/Audio/Voices/announcer_round_1.wav",
		"announcer_round_2": "res://Assets/Audio/Voices/announcer_round_2.wav",
		"announcer_final_round": "res://Assets/Audio/Voices/announcer_final_round.wav",
		"announcer_ko": "res://Assets/Audio/Voices/announcer_ko.wav",
		"announcer_perfect": "res://Assets/Audio/Voices/announcer_perfect.wav",
		"vox_viriato": "res://Assets/Audio/Voices/vox_viriato_pack.wav",
		"vox_nabia": "res://Assets/Audio/Voices/vox_nabia_pack.wav",
		"vox_endovelico": "res://Assets/Audio/Voices/vox_endovelico_pack.wav",
		"vox_aunia": "res://Assets/Audio/Voices/vox_aunia_pack.wav",
		"vox_breno": "res://Assets/Audio/Voices/vox_breno_gaules.wav",
		"vox_bracaro": "res://Assets/Audio/Voices/vox_bracaro_pack.wav",
		"vox_decimo": "res://Assets/Audio/Voices/vox_decimo_pack.wav",
		"vox_trebaruna": "res://Assets/Audio/Voices/vox_trebaruna_pack.wav",
		"vox_klaudia": "res://Assets/Audio/Voices/vox_klaudia_slav.wav",
		"vox_marco": "res://Assets/Audio/Voices/vox_marco_pack.wav",
	}
	for id in lista:
		var stream := _carregar_stream(lista[id])
		if stream != null:
			sfx_streams[id] = stream

	var musicas := {
		# Novas Trilhas Musicais Dedicadas por Cenário (Síntese Medieval/Folk 16-Bit)
		"loja_alquimista": "res://Assets/Audio/Music/bgm_loja_alquimista.wav",
		"praca_central": "res://Assets/Audio/Music/bgm_praca_central.wav",
		"taverna_do_vale": "res://Assets/Audio/Music/bgm_taverna_do_vale.wav",
		"floresta_tamega": "res://Assets/Audio/Music/bgm_floresta_tamega.wav",
		"mina_antiga": "res://Assets/Audio/Music/bgm_mina_antiga.wav",
		"termas_romanas": "res://Assets/Audio/Music/bgm_termas_romanas.wav",
		# Torneio de Tongóbriga & Arcade
		"select_tongobriga": "res://Assets/Audio/Music/bgm_select_tongobriga.mp3",
		"stage1_castro": "res://Assets/Audio/Music/bgm_stage1_castro.mp3",
		"stage2_termas_forum": "res://Assets/Audio/Music/bgm_stage2_termas_forum.mp3",
		"stage3_ponte_tamega": "res://Assets/Audio/Music/bgm_stage3_ponte_tamega.mp3",
		"stage4_feira_noite": "res://Assets/Audio/Music/bgm_stage4_feira_noite.mp3",
	}
	for mid in musicas:
		var mstream := _carregar_stream(musicas[mid], true)
		if mstream != null:
			if mstream is AudioStreamMP3:
				(mstream as AudioStreamMP3).loop = true
			bgm_streams[mid] = mstream

func _carregar_stream(caminho: String, loopar: bool = false) -> AudioStream:
	if ResourceLoader.exists(caminho):
		var res: Resource = ResourceLoader.load(caminho)
		if res is AudioStream:
			if loopar and res is AudioStreamWAV:
				(res as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
			return res as AudioStream

	if not FileAccess.file_exists(caminho):
		return null

	if caminho.ends_with(".mp3"):
		var f := FileAccess.open(caminho, FileAccess.READ)
		if f != null:
			var bytes := f.get_buffer(f.get_length())
			f.close()
			var mp3 := AudioStreamMP3.new()
			mp3.data = bytes
			if loopar:
				mp3.loop = true
			return mp3
	elif caminho.ends_with(".wav"):
		return _carregar_wav_direto(caminho, loopar)

	return null

func _carregar_wav_direto(caminho: String, loopar: bool = false) -> AudioStreamWAV:
	if not FileAccess.file_exists(caminho):
		return null
		
	var f := FileAccess.open(caminho, FileAccess.READ)
	if f == null:
		return null
		
	var tamanho: int = f.get_length()
	if tamanho <= 44:
		f.close()
		return null
		
	var buffer := f.get_buffer(tamanho)
	f.close()
	
	var stream := AudioStreamWAV.new()
	var channels: int = buffer.decode_u16(22)
	var sample_rate: int = buffer.decode_u32(24)
	var bits_per_sample: int = buffer.decode_u16(34)
	var data_offset: int = 44
	for pos in range(12, mini(tamanho - 8, 256)):
		if buffer[pos] == 0x64 and buffer[pos + 1] == 0x61 and buffer[pos + 2] == 0x74 and buffer[pos + 3] == 0x61:
			data_offset = pos + 8
			break
	stream.format = AudioStreamWAV.FORMAT_8_BITS if bits_per_sample == 8 else AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate if sample_rate >= 8000 and sample_rate <= 96000 else 44100
	stream.stereo = (channels == 2)
	stream.data = buffer.slice(data_offset)
	if loopar:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		var bytes_por_amostra: int = (2 if bits_per_sample == 16 else 1) * (2 if stream.stereo else 1)
		stream.loop_end = stream.data.size() / bytes_por_amostra
	return stream

func _criar_pool() -> void:
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		players_pool.append(p)

func _criar_bgm_player() -> void:
	bgm_player_a = AudioStreamPlayer.new()
	bgm_player_a.name = "BgmPlayerA"
	bgm_player_a.bus = "Master"
	bgm_player_a.volume_db = _bgm_base_vol_db + volume_musica_db
	add_child(bgm_player_a)

	bgm_player_b = AudioStreamPlayer.new()
	bgm_player_b.name = "BgmPlayerB"
	bgm_player_b.bus = "Master"
	bgm_player_b.volume_db = -80.0
	add_child(bgm_player_b)

	bgm_player = bgm_player_a
	bgm_player_ativo = bgm_player_a

func _criar_voice_e_ambience_players() -> void:
	voice_player = AudioStreamPlayer.new()
	voice_player.name = "VoicePlayer"
	voice_player.bus = "Master"
	voice_player.volume_db = volume_vozes_db
	add_child(voice_player)

	ambience_player = AudioStreamPlayer.new()
	ambience_player.name = "AmbiencePlayer"
	ambience_player.bus = "Master"
	ambience_player.volume_db = _ambience_base_vol_db + volume_sfx_db
	add_child(ambience_player)

func _configurar_buses_combate() -> void:
	_garantir_bus_com_pan(BUS_COMBAT_P1, -0.26)
	_garantir_bus_com_pan(BUS_COMBAT_P2, 0.26)

func _garantir_bus_com_pan(nome_bus: String, pan_valor: float) -> void:
	var idx := AudioServer.get_bus_index(nome_bus)
	if idx == -1:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, nome_bus)
		AudioServer.set_bus_send(idx, "Master")
	if AudioServer.get_bus_effect_count(idx) == 0:
		var panner := AudioEffectPanner.new()
		panner.pan = pan_valor
		AudioServer.add_bus_effect(idx, panner)

func _linear_para_db(linear: float) -> float:
	var clamped := clampf(linear, 0.0, 1.0)
	if clamped <= 0.001:
		return -80.0
	return linear_to_db(clamped)

func _carregar_configuracoes_audio() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(AUDIO_SETTINGS_PATH) == OK:
		_volume_musica_linear = clampf(float(cfg.get_value("audio", "musica", 1.0)), 0.0, 1.0)
		_volume_sfx_linear = clampf(float(cfg.get_value("audio", "sfx", 1.0)), 0.0, 1.0)
		_volume_vozes_linear = clampf(float(cfg.get_value("audio", "vozes", 1.0)), 0.0, 1.0)
	volume_musica_db = _linear_para_db(_volume_musica_linear)
	volume_sfx_db = _linear_para_db(_volume_sfx_linear)
	volume_vozes_db = _linear_para_db(_volume_vozes_linear)

func _salvar_configuracoes_audio() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "musica", _volume_musica_linear)
	cfg.set_value("audio", "sfx", _volume_sfx_linear)
	cfg.set_value("audio", "vozes", _volume_vozes_linear)
	cfg.save(AUDIO_SETTINGS_PATH)

func definir_volume_musica(linear: float) -> void:
	_volume_musica_linear = clampf(linear, 0.0, 1.0)
	volume_musica_db = _linear_para_db(_volume_musica_linear)
	if bgm_player_ativo != null and bgm_player_ativo.playing:
		bgm_player_ativo.volume_db = _bgm_base_vol_db + volume_musica_db + _duck_db
	_salvar_configuracoes_audio()

func definir_volume_sfx(linear: float) -> void:
	_volume_sfx_linear = clampf(linear, 0.0, 1.0)
	volume_sfx_db = _linear_para_db(_volume_sfx_linear)
	if ambience_player != null and ambience_player.playing:
		ambience_player.volume_db = _ambience_base_vol_db + volume_sfx_db + _duck_db
	_salvar_configuracoes_audio()

func definir_volume_vozes(linear: float) -> void:
	_volume_vozes_linear = clampf(linear, 0.0, 1.0)
	volume_vozes_db = _linear_para_db(_volume_vozes_linear)
	if voice_player != null and voice_player.playing:
		voice_player.volume_db = _voice_base_vol_db + volume_vozes_db
	_salvar_configuracoes_audio()

func obter_volume_musica() -> float:
	return _volume_musica_linear

func obter_volume_sfx() -> float:
	return _volume_sfx_linear

func obter_volume_vozes() -> float:
	return _volume_vozes_linear

func _aplicar_duck_db(val: float) -> void:
	_duck_db = val
	if bgm_player_ativo != null and bgm_player_ativo.playing:
		bgm_player_ativo.volume_db = _bgm_base_vol_db + volume_musica_db + _duck_db
	if ambience_player != null and ambience_player.playing:
		ambience_player.volume_db = _ambience_base_vol_db + volume_sfx_db + _duck_db

func ativar_ducking(reducao_db: float = -7.0, duracao_hold: float = 1.2) -> void:
	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_method(_aplicar_duck_db, _duck_db, reducao_db, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_duck_tween.tween_interval(maxf(0.1, duracao_hold))
	_duck_tween.tween_method(_aplicar_duck_db, reducao_db, 0.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func tocar_voz(id: String, vol_db: float = 2.0, pitch: float = 1.0, duck_bgm: bool = true) -> void:
	if not sfx_streams.has(id) or voice_player == null:
		return
	_voice_base_vol_db = vol_db
	voice_player.stream = sfx_streams[id]
	voice_player.volume_db = _voice_base_vol_db + volume_vozes_db
	voice_player.pitch_scale = pitch
	voice_player.play()
	if duck_bgm:
		ativar_ducking(-7.0, 1.2)

func tocar_ambiente(id: String, vol_db: float = -7.5, pitch_variacao: float = 0.04) -> void:
	if not sfx_streams.has(id) or ambience_player == null:
		return
	if _ambience_tween != null and _ambience_tween.is_valid():
		_ambience_tween.kill()
	_ambience_base_vol_db = vol_db
	ambience_player.stream = sfx_streams[id]
	ambience_player.volume_db = _ambience_base_vol_db + volume_sfx_db + _duck_db
	if pitch_variacao > 0.0:
		ambience_player.pitch_scale = randf_range(1.0 - pitch_variacao, 1.0 + pitch_variacao)
	else:
		ambience_player.pitch_scale = 1.0
	ambience_player.play()

func parar_ambiente(fade_segundos: float = 0.5) -> void:
	if ambience_player == null or not ambience_player.playing:
		return
	if _ambience_tween != null and _ambience_tween.is_valid():
		_ambience_tween.kill()
	if fade_segundos > 0.0:
		_ambience_tween = create_tween()
		_ambience_tween.tween_property(ambience_player, "volume_db", -45.0, fade_segundos)
		_ambience_tween.chain().tween_callback(ambience_player.stop)
	else:
		ambience_player.stop()

func tocar_sfx(id: String, pitch_variacao: float = 0.08) -> void:
	tocar_sfx_volume(id, 0.0, pitch_variacao)

func tocar_sfx_volume(id: String, vol_db: float = 0.0, pitch_variacao: float = 0.08) -> void:
	if id.begins_with("announcer_") or id.begins_with("vox_"):
		tocar_voz(id, vol_db + 2.0, 1.0, true)
		return
	if id == "torcida_arena_reacao":
		tocar_ambiente(id, vol_db - 7.5, pitch_variacao)
		return
	if id == "super_flash_freeze":
		ativar_ducking(-7.0, 1.2)
	_tocar_no_pool(id, "Master", vol_db + volume_sfx_db, pitch_variacao)

func tocar_sfx_combate(id: String, lado: int = 0, vol_db: float = 0.0, pitch_variacao: float = 0.08) -> void:
	if id.begins_with("announcer_") or id.begins_with("vox_"):
		tocar_voz(id, vol_db + 2.0, 1.0, true)
		return
	if id == "super_flash_freeze":
		ativar_ducking(-7.0, 1.2)
	var bus_alvo := "Master"
	if lado < 0:
		bus_alvo = BUS_COMBAT_P1
	elif lado > 0:
		bus_alvo = BUS_COMBAT_P2
	_tocar_no_pool(id, bus_alvo, vol_db + volume_sfx_db, pitch_variacao)

func _tocar_no_pool(id: String, bus_nome: String, vol_final_db: float, pitch_variacao: float) -> void:
	if not sfx_streams.has(id) or players_pool.is_empty():
		return
	var stream: AudioStream = sfx_streams[id]
	var pitch_final := randf_range(1.0 - pitch_variacao, 1.0 + pitch_variacao) if pitch_variacao > 0.0 else 1.0
	for p in players_pool:
		if not p.playing:
			p.bus = bus_nome
			p.stream = stream
			p.volume_db = vol_final_db
			p.pitch_scale = pitch_final
			p.play()
			return

	var p0 := players_pool[0]
	p0.bus = bus_nome
	p0.stream = stream
	p0.volume_db = vol_final_db
	p0.pitch_scale = pitch_final
	p0.play()

func tocar_bgm(stream: AudioStream, vol_db: float = -7.5, pitch: float = 1.0, fade_segundos: float = 1.2) -> void:
	tocar_bgm_stream(stream, "custom_stream", vol_db, pitch, fade_segundos)

func tocar_bgm_id(id: String, vol_db: float = -7.5, pitch: float = 1.0, fade_segundos: float = 1.2) -> void:
	if not bgm_streams.has(id):
		return
	tocar_bgm_stream(bgm_streams[id], id, vol_db, pitch, fade_segundos)

func tocar_bgm_stream(stream: AudioStream, stream_id: String, vol_db: float = -7.5, pitch: float = 1.0, fade_segundos: float = 1.2) -> void:
	if stream == null or bgm_player_a == null or bgm_player_b == null:
		return

	_bgm_base_vol_db = vol_db
	var vol_final := _bgm_base_vol_db + volume_musica_db + _duck_db

	# Se for a mesma música já ativa: modulação suave de tom e volume sem reiniciar a faixa
	if bgm_id_atual == stream_id and bgm_player_ativo != null and bgm_player_ativo.playing:
		if _bgm_tween != null and _bgm_tween.is_valid():
			_bgm_tween.kill()
		_bgm_tween = create_tween()
		_bgm_tween.set_parallel(true)
		_bgm_tween.tween_property(bgm_player_ativo, "volume_db", vol_final, 0.8)
		_bgm_tween.tween_property(bgm_player_ativo, "pitch_scale", pitch, 0.8)
		return

	# Crossfade cinematográfico com os dois canais
	var player_saindo: AudioStreamPlayer = bgm_player_ativo
	var player_entrando: AudioStreamPlayer = bgm_player_b if player_saindo == bgm_player_a else bgm_player_a

	if _bgm_tween != null and _bgm_tween.is_valid():
		_bgm_tween.kill()
	_bgm_tween = create_tween()
	_bgm_tween.set_parallel(true)

	# Inicia o novo canal a partir de silêncio e sobe suavemente
	player_entrando.stream = stream
	player_entrando.pitch_scale = pitch
	player_entrando.volume_db = -45.0
	player_entrando.play()
	_bgm_tween.tween_property(player_entrando, "volume_db", vol_final, fade_segundos).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Reduz gradualmente o canal anterior e interrompe ao final
	if player_saindo != null and player_saindo.playing:
		_bgm_tween.tween_property(player_saindo, "volume_db", -45.0, fade_segundos).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_bgm_tween.chain().tween_callback(player_saindo.stop)

	bgm_player_ativo = player_entrando
	bgm_player = player_entrando
	bgm_id_atual = stream_id

func tocar_musica_area(nome_local: String, de_noite: bool = false, tensao: bool = false) -> void:
	var chave := nome_local.to_lower()
	var track_id := ""
	var vol_alvo := -7.5
	var pitch_alvo := 1.0

	# 1. A Loja do Alquimista (Atelier acolhedor, ritmo de valsa 3/4 com alaúde e flauta)
	if "loja" in chave or "botica" in chave or "atelier" in chave:
		track_id = "loja_alquimista"
		vol_alvo = -7.0
		pitch_alvo = 0.94 if de_noite else 1.0

	# 2. Feira Medieval da Vila (Trilha festiva dedicada)
	elif "feira" in chave:
		track_id = "stage4_feira_noite"
		vol_alvo = -7.2
		pitch_alvo = 0.98 if de_noite else 1.04

	# 3. A Praça Central de Marco de Canaveses (Vida da vila ao ar livre)
	elif "praca" in chave or "praça" in chave or "centro" in chave:
		track_id = "praca_central"
		vol_alvo = -7.5
		pitch_alvo = 0.95 if de_noite else 1.0

	# 4. A Taverna do Vale (Folk celta/minhoto 6/8 animado, fogueira e copos)
	elif "taverna" in chave or "bardo" in chave or "taberna" in chave:
		track_id = "taverna_do_vale"
		vol_alvo = -6.5
		pitch_alvo = 1.0

	# 5. Margens do Tâmega & Ponte do Rio (Trilha dedicada das margens)
	elif "margens" in chave or "ponte" in chave or "rio" in chave:
		track_id = "stage3_ponte_tamega"
		vol_alvo = -8.0
		pitch_alvo = 0.94 if de_noite else 0.99

	# 6. Floresta do Tâmega (Mistério botânico, harpa e sopros)
	elif "floresta" in chave or "tamega" in chave or "tâmega" in chave or "olival" in chave or "bosque" in chave:
		track_id = "floresta_tamega"
		vol_alvo = -8.0
		if tensao or "javali" in chave:
			pitch_alvo = 1.06
		elif de_noite:
			pitch_alvo = 0.93
		else:
			pitch_alvo = 1.0

	# 7. Combate RPG nas Catacumbas / Masmorra (Verificado antes de "mina"/"dungeon")
	elif "combate" in chave or "dungeon_battle" in chave or "batalha" in chave:
		track_id = "stage1_castro"
		vol_alvo = -6.8
		pitch_alvo = 1.05

	# 8. Mina Antiga & Subterrâneo (Ecos graves, suspense e cristais)
	elif "mina" in chave or "dungeon" in chave or "escava" in chave or "carrinho" in chave:
		track_id = "mina_antiga"
		vol_alvo = -7.0
		pitch_alvo = 1.04 if tensao else 0.96

	# 9. Termas Romanas & Cripta da Pedra Formosa (Águas sagradas e santuário místico)
	elif "termas" in chave or "cripta" in chave or "pedra formosa" in chave:
		track_id = "termas_romanas"
		vol_alvo = -8.0
		pitch_alvo = 0.96

	# 10. Tongóbriga & Arena Arcade
	elif "tongobriga" in chave or "arena" in chave or "torneio" in chave:
		track_id = "stage1_castro"
		vol_alvo = -8.5
		pitch_alvo = 1.0

	# Fallback
	else:
		if de_noite:
			track_id = "praca_central"
			pitch_alvo = 0.94
		else:
			track_id = "praca_central"
			pitch_alvo = 1.0

	tocar_bgm_id(track_id, vol_alvo, pitch_alvo)

func parar_bgm(fade_segundos: float = 0.8) -> void:
	if _bgm_tween != null and _bgm_tween.is_valid():
		_bgm_tween.kill()
	if fade_segundos > 0.0 and bgm_player_ativo != null and bgm_player_ativo.playing:
		_bgm_tween = create_tween()
		_bgm_tween.tween_property(bgm_player_ativo, "volume_db", -45.0, fade_segundos)
		_bgm_tween.chain().tween_callback(bgm_player_ativo.stop)
	else:
		if bgm_player_a != null: bgm_player_a.stop()
		if bgm_player_b != null: bgm_player_b.stop()
	bgm_id_atual = ""
