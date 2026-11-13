class_name ClienteNPC extends CharacterBody2D

const TOTAL_PERFIS_VISUAIS: int = 4

signal venda_sucesso(item: ItemData, valor: int)
signal venda_fracassada(item: ItemData)

enum Estado { ENTRANDO, ESPERANDO, SAINDO }

@export var itens_possiveis: Array[ItemData] = []
@export var velocidade: float = 42.0
@export var paciencia_total: float = 40.0
@export_range(1, 5) var nivel_cliente: int = 1
@export_range(0.5, 5.0, 0.05) var multiplicador_preco: float = 1.0
@export var tipo_visual: int = -1
@export var e_vip: bool = false
@export var nome_vip: String = ""
@export var ponto_entrada: Vector2
@export var ponto_espera: Vector2
@export var ponto_saida: Vector2

# --- SWORDS & POTIONS: IDENTIDADE E DIÁLOGOS REGIONAIS ---
var nome_cliente: String = ""
var classe_cliente: String = ""
var fala_pedido: String = ""
var fala_reacao: String = ""
var multiplicador_pechincha: float = 1.0
var pechincha_tentada: bool = false
var desconto_aplicado: bool = false

@onready var timer_paciencia: Timer = get_node_or_null("TimerPaciencia")
@onready var pedido_label: Label = get_node_or_null("Pedido")
@onready var anim: AnimatedSprite2D = get_node_or_null("Anim")

var estado: Estado = Estado.ENTRANDO
var item_desejado: ItemData
var feliz: bool = false
var direcao_atual: String = "left"

func _ready() -> void:
	add_to_group("clientes")
	if timer_paciencia == null:
		push_error("ClienteNPC precisa de um Timer filho chamado TimerPaciencia.")
		set_physics_process(false)
		return
	timer_paciencia.one_shot = true
	timer_paciencia.timeout.connect(_on_timer_paciencia_timeout)
	if anim == null:
		push_error("ClienteNPC precisa de um AnimatedSprite2D filho chamado Anim.")
		set_physics_process(false)
		return
	_preparar_visual()
	_gerar_perfil_regional()
	global_position = ponto_entrada

	if itens_possiveis.is_empty():
		push_error("ClienteNPC precisa de pelo menos uma poção em itens_possiveis.")
		set_physics_process(false)
		return

func _gerar_perfil_regional() -> void:
	var idx := posmod(tipo_visual, TOTAL_PERFIS_VISUAIS)
	if e_vip:
		classe_cliente = "Nobre de Tongóbriga"
		var nomes_vips := ["Tribuno Flávio", "Senhora Aurélia", "Patrício Cláudio", "Dama Valéria"]
		nome_cliente = nomes_vips.pick_random()
	else:
		match idx:
			0:
				classe_cliente = "Lavrador de Vinho Verde"
				var nomes := ["Tiago das Vinhas", "Manuel da Ribeira", "Joaquim do Vale", "António do Souto"]
				nome_cliente = nomes.pick_random()
			1:
				classe_cliente = "Mercenário do Tâmega"
				var nomes := ["Rodrigo Espada-Rápida", "Vasco de Ancede", "Diogo da Ponte", "Afonso Rato-da-Mata"]
				nome_cliente = nomes.pick_random()
			2:
				classe_cliente = "Curandeira de Alpendurada"
				var nomes := ["Irmã Teresa", "Beata Rosa", "Madalena das Ervas", "Constança Benzedeira"]
				nome_cliente = nomes.pick_random()
			_:
				classe_cliente = "Cidadão de Canaveses"
				var nomes := ["Gonçalo Ferreiro", "Beatriz Moleira", "Duarte Almocreve", "Catarina do Mercado"]
				nome_cliente = nomes.pick_random()

func _gerar_fala_pedido() -> void:
	if item_desejado == null:
		fala_pedido = "Saudações, boticário!"
		return
	var nome_pocao := item_desejado.nome_do_item
	if e_vip:
		var falas_vip := [
			"Requeiro %s para o banquete cerimonial de Tongóbriga. Não aceito impurezas!" % nome_pocao,
			"Saudações, alquimista. A guarnição romana necessita de %s da mais alta têmpera." % nome_pocao,
			"Em nome do legado de Tongóbriga, trago ouro para adquirir %s perfeita." % nome_pocao
		]
		fala_pedido = falas_vip.pick_random()
	elif classe_cliente == "Lavrador de Vinho Verde":
		var falas_lavrador := [
			"Bom dia, vizinho! A poda das videiras deu-me cabo das costas... Tens %s aí no caldeirão?" % nome_pocao,
			"O dia no lagar vai ser duro. Arranja-me %s para aguentar o calor das encostas!" % nome_pocao,
			"A colheita do verde está à porta e preciso de %s de boa cepa!" % nome_pocao
		]
		fala_pedido = falas_lavrador.pick_random()
	elif classe_cliente == "Mercenário do Tâmega":
		var falas_merc := [
			"Vou descer às minas antigas de Canaveses. Passa cá %s se não quiseres ver-me em sarilhos!" % nome_pocao,
			"Os javalis da floresta estão bravos hoje. Preciso de %s antes de cruzar o rio!" % nome_pocao,
			"Negócio rápido, boticário! Dá-me %s e fico pronto pro combate." % nome_pocao
		]
		fala_pedido = falas_merc.pick_random()
	elif classe_cliente == "Curandeira de Alpendurada":
		var falas_curandeira := [
			"Que a paz reine nesta botica. Os enfermos do convento precisam de %s bendita." % nome_pocao,
			"Trago bênçãos do mosteiro. Precisamos de %s para curar os febris do vale." % nome_pocao
		]
		fala_pedido = falas_curandeira.pick_random()
	else:
		fala_pedido = "Olá! Vim à procura de %s. Tens em stock?" % nome_pocao

func _process(_delta: float) -> void:
	if pedido_label == null:
		return
	match estado:
		Estado.ENTRANDO:
			pedido_label.text = "A chegar..."
		Estado.ESPERANDO:
			if item_desejado != null:
				var prefixo: String = "👑 VIP TONGÓBRIGA\n" if e_vip else ""
				var pct: int = roundi(multiplicador_pechincha * 100.0)
				var tag_preco: String = " (%d%%)" % pct if pct != 100 else ""
				pedido_label.text = "%s%s%s\n%d s" % [
					prefixo,
					item_desejado.nome_do_item.replace("Poção ", ""),
					tag_preco,
					ceili(timer_paciencia.time_left),
				]
		Estado.SAINDO:
			pedido_label.text = fala_reacao if not fala_reacao.is_empty() else ("Obrigado!" if feliz else "Vou-me embora!")

func _physics_process(_delta: float) -> void:
	match estado:
		Estado.ENTRANDO:
			if _mover_para(ponto_espera):
				estado = Estado.ESPERANDO
				escolher_pocao_aleatoria()
				_gerar_fala_pedido()
				timer_paciencia.start(paciencia_total)
				direcao_atual = "up"
				_atualizar_animacao()
			else:
				_atualizar_animacao()
		Estado.ESPERANDO:
			velocity = Vector2.ZERO
			move_and_slide()
			_atualizar_animacao()
		Estado.SAINDO:
			if _mover_para(ponto_saida):
				queue_free()
			else:
				_atualizar_animacao()

func _mover_para(destino: Vector2) -> bool:
	var deslocamento: Vector2 = destino - global_position
	if deslocamento.length() <= 3.0:
		global_position = destino
		velocity = Vector2.ZERO
		move_and_slide()
		return true

	velocity = deslocamento.normalized() * velocidade
	move_and_slide()
	return false

func _atualizar_animacao() -> void:
	if anim == null or anim.sprite_frames == null:
		return

	if absf(velocity.x) > absf(velocity.y):
		direcao_atual = "right" if velocity.x > 0.0 else "left"
	elif absf(velocity.y) > 0.01:
		direcao_atual = "down" if velocity.y > 0.0 else "up"

	var nome_animacao: String = "walk_" + direcao_atual
	if not anim.sprite_frames.has_animation(nome_animacao):
		nome_animacao = "walk_down"
	anim.flip_h = false

	if velocity.length_squared() <= 0.01:
		if anim.animation != nome_animacao:
			anim.play(nome_animacao)
		anim.pause()
		anim.set_frame_and_progress(0, 0.0)
		return

	if anim.animation != nome_animacao or not anim.is_playing():
		anim.play(nome_animacao)

func _preparar_visual() -> void:
	if anim == null:
		return
	if tipo_visual < 0:
		tipo_visual = randi_range(0, TOTAL_PERFIS_VISUAIS - 1)
	var idx_cliente: int = posmod(tipo_visual, TOTAL_PERFIS_VISUAIS)

	var frames: SpriteFrames = SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	var direcoes_chaves: Array[String] = ["down", "up", "left", "right"]
	for dir_chave: String in direcoes_chaves:
		var nome_animacao: String = "walk_" + dir_chave
		frames.add_animation(nome_animacao)
		frames.set_animation_speed(nome_animacao, 6.0)
		frames.set_animation_loop(nome_animacao, true)
		for indice_quadro: int in range(1, 5):
			var caminho_frame: String = "res://Assets/Characters/Clientes/cliente_%d/%s_%d.png" % [
				idx_cliente,
				nome_animacao,
				indice_quadro,
			]
			var tex_frame: Texture2D = load(caminho_frame) as Texture2D
			if tex_frame != null:
				frames.add_frame(nome_animacao, tex_frame)

	anim.sprite_frames = frames
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	anim.scale = Vector2(0.42, 0.42)
	anim.offset = Vector2(0.0, -76.0)
	anim.visible = true
	anim.flip_h = false
	anim.play("walk_left")
	anim.pause()

func escolher_pocao_aleatoria() -> void:
	var opcoes_validas: Array[ItemData] = []
	for item in itens_possiveis:
		if item != null:
			opcoes_validas.append(item)
			# Se for a poção em alta do dia (Tendência), adiciona peso extra!
			if InventoryManager.e_pocao_tendencia(item.id):
				opcoes_validas.append(item)
	if opcoes_validas.is_empty():
		push_error("A lista itens_possiveis não contém poções válidas.")
		return
	item_desejado = opcoes_validas.pick_random()

func obter_chance_sugestao(pocao_sugerida: ItemData) -> int:
	if pocao_sugerida == null or item_desejado == null:
		return 0
	var chance: float = 0.70
	if e_vip:
		chance = 0.55
	if pocao_sugerida.valor_em_escudos >= item_desejado.valor_em_escudos:
		chance += 0.20
	if InventoryManager.e_pocao_tendencia(pocao_sugerida.id):
		chance += 0.10
	return clampi(roundi(chance * 100.0), 10, 95)

func obter_chance_pechincha() -> int:
	var chance_base: float = 0.65
	if e_vip:
		chance_base += 0.15
	elif classe_cliente == "Lavrador de Vinho Verde":
		chance_base -= 0.15
	chance_base += float(InventoryManager.renome_loja) * 0.001
	if timer_paciencia != null and timer_paciencia.time_left < 15.0:
		chance_base -= 0.20
	if item_desejado != null and InventoryManager.e_pocao_tendencia(item_desejado.id):
		chance_base += 0.12
	return clampi(roundi(chance_base * 100.0), 15, 95)

# --- MECÂNICAS DE BALCÃO ESTILO SWORDS & POTIONS ---

# 1. Sugerir poção alternativa
func tentar_sugestao(pocao_sugerida: ItemData) -> Dictionary:
	if estado != Estado.ESPERANDO or pocao_sugerida == null:
		return {"aceitou": false, "fala": "Ação inválida."}
	
	if InventoryManager.obter_quantidade(pocao_sugerida.id) <= 0:
		return {"aceitou": false, "fala": "Não tens essa poção em stock para sugerir!"}
		
	var chance: float = float(obter_chance_sugestao(pocao_sugerida)) / 100.0
	var aceitou := randf() < chance
	if aceitou:
		item_desejado = pocao_sugerida
		if e_vip:
			fala_reacao = "Excelente proposta! Esta fórmula é ainda mais refinada."
		else:
			fala_reacao = "Bem visto! Essa também resolve perfeitamente o meu problema."
		return {"aceitou": true, "fala": fala_reacao}
	else:
		timer_paciencia.start(maxf(3.0, timer_paciencia.time_left - 8.0))
		fala_reacao = "Não me parece adequada... Vim especificamente à procura da outra!"
		return {"aceitou": false, "fala": fala_reacao}

# 2. Pechinchar / Sobretaxa (+35% ou +50% Ouro)
func tentar_pechincha() -> Dictionary:
	if estado != Estado.ESPERANDO:
		return {"sucesso": false, "fala": "Ação inválida."}
	if pechincha_tentada:
		return {"sucesso": false, "fala": "Já negociaste o preço com este freguês!"}
		
	pechincha_tentada = true
	var taxa_aumento: float = 0.50 if e_vip else 0.35
	var chance_base: float = float(obter_chance_pechincha()) / 100.0
	var sucesso := randf() < chance_base
	if sucesso:
		multiplicador_pechincha = 1.0 + taxa_aumento
		var novo_preco := calcular_preco(item_desejado)
		if e_vip:
			fala_reacao = "A qualidade de Canaveses merece o tributo. Fechado!"
		else:
			fala_reacao = "É um pouco caro, mas confio no teu preparo. Eu pago!"
		return {"sucesso": true, "fala": fala_reacao, "novo_preco": novo_preco}
	else:
		timer_paciencia.start(maxf(2.0, timer_paciencia.time_left - 12.0))
		fala_reacao = "Que abuso! Não pago nem mais um cobre por isso!"
		return {"sucesso": false, "fala": fala_reacao, "novo_preco": calcular_preco(item_desejado)}

# 3. Dar Desconto (-20% Ouro) -> Sucesso 100% + Reputação
func aplicar_desconto() -> Dictionary:
	if estado != Estado.ESPERANDO:
		return {"sucesso": false, "fala": "Ação inválida."}
	desconto_aplicado = true
	multiplicador_pechincha = 0.80
	InventoryManager.adicionar_renome(10)
	var novo_preco := calcular_preco(item_desejado)
	fala_reacao = "Que nobreza de espírito! A tua botica será lendária no Tâmega!"
	return {"sucesso": true, "fala": fala_reacao, "novo_preco": novo_preco}

# 4. Dispensar educadamente
func dispensar_cliente() -> void:
	if estado != Estado.ESPERANDO:
		return
	fala_reacao = "Compreendo. Voltarei quando tiveres novas destilações!"
	feliz = false
	estado = Estado.SAINDO

# 5. Conclusão da venda
func receber_pocao(pocao: ItemData) -> bool:
	if estado != Estado.ESPERANDO or pocao == null or item_desejado == null:
		return false
	if pocao != item_desejado:
		return false

	timer_paciencia.stop()
	var valor: int = calcular_preco(pocao)
	var jogador := get_tree().get_first_node_in_group("player") as Player
	if jogador != null:
		jogador.escudos += valor
	var ganho_renome := (5 if e_vip else 2) + (3 if InventoryManager.e_pocao_tendencia(pocao.id) else 0)
	InventoryManager.adicionar_renome(ganho_renome)

	feliz = true
	fala_reacao = "Excelente! Até à próxima!"
	estado = Estado.SAINDO
	venda_sucesso.emit(pocao, valor)
	return true

func calcular_preco(pocao: ItemData) -> int:
	if pocao == null:
		return 0
	var preco_base := float(pocao.valor_em_escudos) * multiplicador_preco * multiplicador_pechincha
	preco_base *= InventoryManager.obter_multiplicador_preco_loja()
	if e_vip:
		preco_base *= 2.0
	if InventoryManager.e_pocao_tendencia(pocao.id):
		preco_base *= 1.35
	# Bônus de qualidade perfeita se a poção tiver versão ouro em stock
	var bonus_ouro: float = 1.0
	if InventoryManager.obter_quantidade_ouro(pocao.id) > 0:
		bonus_ouro = 1.5
	return maxi(1, roundi(preco_base * bonus_ouro))

func _on_timer_paciencia_timeout() -> void:
	if estado != Estado.ESPERANDO:
		return
	estado = Estado.SAINDO
	fala_reacao = "Demoraste demasiado! Vou procurar outro boticário..."
	if item_desejado != null:
		venda_fracassada.emit(item_desejado)
