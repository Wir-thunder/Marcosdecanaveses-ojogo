extends Node

signal renome_alterado(novo_renome: int, titulo: String)
signal mestria_desbloqueada(pocao_id: String, nova_receita_caminho: String, nome_nova_pocao: String)
signal loja_melhorada(id_upgrade: String, novo_nivel: int)

# Um dicionário que guarda o ID do item e a quantidade que tens. Ex: {"musgo_aboboreira": 5}
var inventario: Dictionary = {}
# Dicionário para ingredientes e itens de qualidade ouro/perfeita
var inventario_ouro: Dictionary = {}
var escudos: int = 0
var recolhas: Dictionary = {}

# --- PROGRESSÃO DA BOTICA ("COMEÇA QUEBRADO E VAI CRESCENDO") ---
var nivel_receitas: int = 1      # 1: Vento Ligeiro | 2: +Cura | 3: +Mente | 4: +Escudo & Mestrias
var nivel_vitrine: int = 0       # 0: Quebrada | 1: Estante Reparada (2 slots) | 2: Vitrine Real (4 slots)
var nivel_caldeirao: int = 1     # 1: Ferro Enferrujado | 2: Cobre Polido (25% 2x) | 3: Athanor Dourado (50% 2x)
var nivel_balcao: int = 1        # 1: Tábuas Velhas | 2: Carvalho (+15% ouro) | 3: Salão Nobre (+35% ouro)
var nivel_fornecedor: int = 1    # 1: Ervanário Básico (5🪙) | 2: Caravana (4🪙) | 3: Guilda Imperial (3🪙)
var bonus_ouro_vitrine_atual: float = 1.0

# --- SWORDS & POTIONS / RECETTEAR: MESTRIA, FAMA E TENDÊNCIA DO DIA ---
# Rastreio de quantas vezes cada poção foi preparada no caldeirão
var mestria_pocao: Dictionary = {}
var renome_loja: int = 0 # Começa do zero (Botica Abandonada)
var pocao_tendencia_dia_id: String = "pocao_vento_ligeiro"
var nome_pocao_tendencia_dia: String = "Poção Vento Ligeiro"
var motivo_tendencia_dia: String = "Colheita nas Encostas"
var receitas_desbloqueadas: Array[String] = [
	"res://Recursos/Recursos_receitas/receita_vento_ligeiro.tres",
]

const MOTIVOS_TENDENCIA: Dictionary = {
	"pocao_vento_ligeiro": "Colheita apressada nas encostas (+35% Ouro)",
	"pocao_espinheira_real": "Acidentes na Mina Antiga (+35% Ouro)",
	"pocao_mente_limpida": "Vigília dos Monges de Alpendurada (+35% Ouro)",
	"pocao_escudo_do_lago": "Treinos da Guarnição de Tongóbriga (+35% Ouro)",
	"pocao_rio_ensolarado": "Romaria às Margens do Tâmega (+35% Ouro)",
	"pocao_fogo_do_paineiro": "Noite fria na Serra da Aboboreira (+35% Ouro)",
	"pocao_sono_puro": "Insónia após a Feira Medieval (+35% Ouro)",
	"pocao_pele_de_ferro": "Expedição às Ruínas Profundas (+35% Ouro)",
	"pocao_pedra_viva": "Torneio de Gladiadores em Tongóbriga (+35% Ouro)",
	"pocao_furia_do_trigo": "Desafio dos Campeões Lusitanos (+35% Ouro)",
	"elixir_da_flor": "Banquete Nobre no Fórum Romano (+35% Ouro)",
	"pocao_ascensao_dourada": "Decreto Imperial de César (+35% Ouro)",
}

func sortear_tendencia_diaria() -> Dictionary:
	var opcoes: Array[ItemData] = []
	for caminho in receitas_desbloqueadas:
		var rec := load(caminho) as PotionRecipeData
		if rec != null and rec.pocao_resultante != null:
			opcoes.append(rec.pocao_resultante)
	if opcoes.is_empty():
		pocao_tendencia_dia_id = "pocao_vento_ligeiro"
		nome_pocao_tendencia_dia = "Poção Vento Ligeiro"
	else:
		var escolhida: ItemData = opcoes.pick_random()
		pocao_tendencia_dia_id = escolhida.id
		nome_pocao_tendencia_dia = escolhida.nome_do_item
	motivo_tendencia_dia = str(MOTIVOS_TENDENCIA.get(pocao_tendencia_dia_id, "Alta procura na praça (+35% Ouro)"))
	return {
		"id": pocao_tendencia_dia_id,
		"nome": nome_pocao_tendencia_dia,
		"motivo": motivo_tendencia_dia
	}

func e_pocao_tendencia(pocao_id: String) -> bool:
	return not pocao_id.is_empty() and pocao_id == pocao_tendencia_dia_id

# Árvore de Mestria Alquímica: 5 preparos desbloqueiam a próxima receita na linha!
const ARVORE_MESTRIA: Dictionary = {
	"pocao_vento_ligeiro": {
		"caminho_receita": "res://Recursos/Recursos_receitas/receita_rio_ensolarado.tres",
		"nome": "Poção Rio Ensolarado"
	},
	"pocao_espinheira_real": {
		"caminho_receita": "res://Recursos/Recursos_receitas/receita_fogo_do_paineiro.tres",
		"nome": "Poção Fogo do Paineiro"
	},
	"pocao_mente_limpida": {
		"caminho_receita": "res://Recursos/Recursos_receitas/receita_sono_puro.tres",
		"nome": "Poção Sono Puro"
	},
	"pocao_escudo_do_lago": {
		"caminho_receita": "res://Recursos/Recursos_receitas/receita_pele_de_ferro.tres",
		"nome": "Poção Pele de Ferro"
	},
	"pocao_pele_de_ferro": {
		"caminho_receita": "res://Recursos/Recursos_receitas/receita_pedra_viva.tres",
		"nome": "Poção Pedra Viva"
	},
	"pocao_fogo_do_paineiro": {
		"caminho_receita": "res://Recursos/Recursos_receitas/receita_furia_do_trigo.tres",
		"nome": "Poção Fúria do Trigo"
	},
	"pocao_rio_ensolarado": {
		"caminho_receita": "res://Recursos/Recursos_receitas/receita_elixir_da_flor.tres",
		"nome": "Elixir da Flor"
	},
	"elixir_da_flor": {
		"caminho_receita": "res://Recursos/Recursos_receitas/receita_ascensao_dourada.tres",
		"nome": "Poção Ascensão Dourada"
	}
}

# Função para registrar preparo de poção e checar mestria (Swords & Potions)
func registrar_preparo_pocao(pocao_id: String) -> Dictionary:
	var contagem: int = int(mestria_pocao.get(pocao_id, 0)) + 1
	mestria_pocao[pocao_id] = contagem
	adicionar_renome(2)
	
	var desbloqueou_receita: bool = false
	var caminho_desbloqueado: String = ""
	var nome_desbloqueado: String = ""
	
	if contagem >= 5 and ARVORE_MESTRIA.has(pocao_id):
		var dados: Dictionary = ARVORE_MESTRIA[pocao_id]
		caminho_desbloqueado = dados["caminho_receita"]
		nome_desbloqueado = dados["nome"]
		if not receitas_desbloqueadas.has(caminho_desbloqueado):
			receitas_desbloqueadas.append(caminho_desbloqueado)
			desbloqueou_receita = true
			adicionar_renome(25)
			mestria_desbloqueada.emit(pocao_id, caminho_desbloqueado, nome_desbloqueado)
			print("🌟 MESTRIA ALCANÇADA! Desbloqueaste a receita de ", nome_desbloqueado)

	return {
		"contagem": contagem,
		"nivel_mestria": obter_nivel_mestria(pocao_id),
		"desbloqueou_receita": desbloqueou_receita,
		"nova_receita": caminho_desbloqueado,
		"nome_nova_pocao": nome_desbloqueado
	}

func obter_mestria(pocao_id: String) -> int:
	return int(mestria_pocao.get(pocao_id, 0))

func obter_nivel_mestria(pocao_id: String) -> String:
	var c: int = obter_mestria(pocao_id)
	if c >= 10:
		return "Grão-Mestre"
	elif c >= 5:
		return "Mestre"
	elif c >= 3:
		return "Praticante"
	elif c >= 1:
		return "Iniciante"
	return "Não Praticada"

func adicionar_renome(pontos: int) -> void:
	renome_loja = maxi(0, renome_loja + pontos)
	renome_alterado.emit(renome_loja, obter_titulo_fama())

func obter_titulo_fama() -> String:
	if renome_loja >= 300:
		return "Fornecedor Imperial de Tongóbriga"
	elif renome_loja >= 150:
		return "Alquimia Nobre de Canaveses"
	elif renome_loja >= 60:
		return "Boticário do Vale do Tâmega"
	elif renome_loja >= 20:
		return "Botica Remendada"
	return "Cabana Alquímica Quebrada"

func obter_soma_niveis_loja() -> int:
	return nivel_receitas + nivel_vitrine + nivel_caldeirao + nivel_balcao + nivel_fornecedor

func obter_max_clientes_turno() -> int:
	var soma := obter_soma_niveis_loja()
	if soma <= 5:
		return 3 # Começa humilde: 3 clientes por dia para dar fôlego
	elif soma <= 8:
		return 4
	elif soma <= 11:
		return 5
	return 6

func obter_multiplicador_preco_loja() -> float:
	var mult_balcao := 1.0
	if nivel_balcao == 2:
		mult_balcao = 1.18
	elif nivel_balcao >= 3:
		mult_balcao = 1.38
	var mult_renome := 1.0 + minf(0.30, float(renome_loja) * 0.001)
	return mult_balcao * bonus_ouro_vitrine_atual * mult_renome

func obter_bonus_paciencia_loja() -> float:
	if nivel_balcao == 2:
		return 8.0
	elif nivel_balcao >= 3:
		return 16.0
	return 0.0

func obter_chance_dose_dupla() -> float:
	if nivel_caldeirao == 2:
		return 0.25
	elif nivel_caldeirao >= 3:
		return 0.50
	return 0.0

func obter_catalogo_upgrades() -> Array[Dictionary]:
	return [
		{
			"id": "receitas",
			"icone": "📜",
			"titulo": "Grimório de Fórmulas",
			"nivel": nivel_receitas,
			"max_nivel": 4,
			"custo": 18 if nivel_receitas == 1 else (32 if nivel_receitas == 2 else (50 if nivel_receitas == 3 else 0)),
			"desc_atual": "Apenas Vento Ligeiro" if nivel_receitas == 1 else ("+Cura (Espinheira Real)" if nivel_receitas == 2 else ("+Mente Límpida" if nivel_receitas == 3 else "Todas as 4 bases + Mestrias Tier 2/3!")),
			"desc_prox": "Desbloqueia Poção de Espinheira Real (Cura)" if nivel_receitas == 1 else ("Desbloqueia Poção de Mente Límpida" if nivel_receitas == 2 else ("Desbloqueia Escudo do Lago & Mestrias" if nivel_receitas == 3 else "MÁXIMO ALCANÇADO"))
		},
		{
			"id": "vitrine",
			"icone": "🪟",
			"titulo": "Vitrine de Exibição",
			"nivel": nivel_vitrine,
			"max_nivel": 2,
			"custo": 15 if nivel_vitrine == 0 else (42 if nivel_vitrine == 1 else 0),
			"desc_atual": "QUEBRADA (Sem bónus)" if nivel_vitrine == 0 else ("Estante Reparada (2 poções · +10% cada)" if nivel_vitrine == 1 else "Vitrine Real de Cristal (4 poções · +12% cada)"),
			"desc_prox": "Consertar Vitrine (Exibe até 2 poções)" if nivel_vitrine == 0 else ("Expandir para Vitrine Real (4 poções)" if nivel_vitrine == 1 else "MÁXIMO ALCANÇADO")
		},
		{
			"id": "caldeirao",
			"icone": "⚗️",
			"titulo": "Caldeirão Alquímico",
			"nivel": nivel_caldeirao,
			"max_nivel": 3,
			"custo": 28 if nivel_caldeirao == 1 else (65 if nivel_caldeirao == 2 else 0),
			"desc_atual": "Ferro Enferrujado (1x dose)" if nivel_caldeirao == 1 else ("Cobre Polido (25% chance Dose Dupla)" if nivel_caldeirao == 2 else "Athanor Dourado (50% Dose Dupla + Ouro)"),
			"desc_prox": "Forjar Cobre Polido (25% chance de 2x poções)" if nivel_caldeirao == 1 else ("Erguer Athanor Dourado (50% 2x poções)" if nivel_caldeirao == 2 else "MÁXIMO ALCANÇADO")
		},
		{
			"id": "balcao",
			"icone": "🛎️",
			"titulo": "Balcão & Salão",
			"nivel": nivel_balcao,
			"max_nivel": 3,
			"custo": 24 if nivel_balcao == 1 else (58 if nivel_balcao == 2 else 0),
			"desc_atual": "Tábuas Rachadas (Preço base)" if nivel_balcao == 1 else ("Carvalho Esculpido (+18% ouro, +8s paciência)" if nivel_balcao == 2 else "Salão Nobre (+38% ouro, +16s paciência, +VIPs)"),
			"desc_prox": "Reformar em Carvalho (+18% valor nas vendas)" if nivel_balcao == 1 else ("Decorar Salão Nobre (+38% valor nas vendas)" if nivel_balcao == 2 else "MÁXIMO ALCANÇADO")
		},
		{
			"id": "fornecedor",
			"icone": "📦",
			"titulo": "Rota de Fornecedores",
			"nivel": nivel_fornecedor,
			"max_nivel": 3,
			"custo": 22 if nivel_fornecedor == 1 else (52 if nivel_fornecedor == 2 else 0),
			"desc_atual": "Ervanário Local (3 ervas a 5🪙)" if nivel_fornecedor == 1 else ("Caravana do Tâmega (5 itens a 4🪙)" if nivel_fornecedor == 2 else "Guilda de Tongóbriga (7 itens a 3🪙)"),
			"desc_prox": "Contratar Caravana (Mais ingredientes a 4🪙)" if nivel_fornecedor == 1 else ("Pacto com a Guilda (Todos os itens a 3🪙)" if nivel_fornecedor == 2 else "MÁXIMO ALCANÇADO")
		}
	]

func comprar_upgrade_loja(id_upgrade: String) -> Dictionary:
	for upg in obter_catalogo_upgrades():
		if str(upg["id"]) != id_upgrade:
			continue
		var niv_atual := int(upg["nivel"])
		var max_niv := int(upg["max_nivel"])
		var custo := int(upg["custo"])
		if niv_atual >= max_niv:
			return {"sucesso": false, "mensagem": "Esta melhoria já está no nível máximo!"}
		if escudos < custo:
			return {"sucesso": false, "mensagem": "Escudos insuficientes! Precisas de %d escudos." % custo}
		escudos -= custo
		var novo_nivel := niv_atual + 1
		match id_upgrade:
			"receitas":
				nivel_receitas = novo_nivel
				if novo_nivel >= 2 and not receitas_desbloqueadas.has("res://Recursos/Recursos_receitas/receita_espinheira_real.tres"):
					receitas_desbloqueadas.append("res://Recursos/Recursos_receitas/receita_espinheira_real.tres")
				if novo_nivel >= 3 and not receitas_desbloqueadas.has("res://Recursos/Recursos_receitas/receita_mente_limpida.tres"):
					receitas_desbloqueadas.append("res://Recursos/Recursos_receitas/receita_mente_limpida.tres")
				if novo_nivel >= 4 and not receitas_desbloqueadas.has("res://Recursos/Recursos_receitas/receita_escudo_do_lago.tres"):
					receitas_desbloqueadas.append("res://Recursos/Recursos_receitas/receita_escudo_do_lago.tres")
			"vitrine":
				nivel_vitrine = novo_nivel
			"caldeirao":
				nivel_caldeirao = novo_nivel
			"balcao":
				nivel_balcao = novo_nivel
			"fornecedor":
				nivel_fornecedor = novo_nivel
		adicionar_renome(15)
		loja_melhorada.emit(id_upgrade, novo_nivel)
		return {
			"sucesso": true,
			"novo_nivel": novo_nivel,
			"mensagem": "🔨 Melhoria concluída: %s (Nível %d)! (+15 Fama)" % [str(upg["titulo"]), novo_nivel]
		}
	return {"sucesso": false, "mensagem": "Melhoria desconhecida."}

# Função para adicionar itens normais
func adicionar_item(item_id: String, quantidade: int = 1) -> void:
	if inventario.has(item_id):
		inventario[item_id] += quantidade
	else:
		inventario[item_id] = quantidade
	print("Adicionaste ", quantidade, "x ", item_id, ". Total: ", inventario[item_id])

# Função para adicionar itens de qualidade Ouro / Perfeita
func adicionar_item_ouro(item_id: String, quantidade: int = 1) -> void:
	if inventario_ouro.has(item_id):
		inventario_ouro[item_id] += quantidade
	else:
		inventario_ouro[item_id] = quantidade
	# Também conta no inventário geral para receitas
	adicionar_item(item_id, quantidade)
	print("✨ Adicionaste ", quantidade, "x ", item_id, " (QUALIDADE OURO)!")

# Função para remover itens (ex: quando gastas num caldeirão)
# Preserva itens de qualidade Ouro sempre que houver stock normal suficiente.
func remover_item(item_id: String, quantidade: int = 1) -> bool:
	return remover_item_qualidade(item_id, quantidade, false)

func remover_item_qualidade(item_id: String, quantidade: int = 1, priorizar_ouro: bool = false) -> bool:
	if quantidade <= 0:
		return true
	var total: int = int(inventario.get(item_id, 0))
	if total < quantidade:
		print("Não tens ingredientes suficientes!")
		return false

	var ouro: int = int(inventario_ouro.get(item_id, 0))
	var normal: int = maxi(0, total - ouro)
	if priorizar_ouro:
		var ouro_consumido: int = mini(ouro, quantidade)
		ouro -= ouro_consumido
	else:
		if quantidade > normal:
			var excesso_ouro: int = quantidade - normal
			ouro = maxi(0, ouro - excesso_ouro)

	var novo_total: int = total - quantidade
	if novo_total <= 0:
		inventario.erase(item_id)
	else:
		inventario[item_id] = novo_total

	ouro = mini(ouro, novo_total)
	if ouro <= 0:
		inventario_ouro.erase(item_id)
	else:
		inventario_ouro[item_id] = ouro

	print("Removeste ", quantidade, "x ", item_id)
	return true

func obter_quantidade(item_id: String) -> int:
	return int(inventario.get(item_id, 0))

func obter_quantidade_ouro(item_id: String) -> int:
	return int(inventario_ouro.get(item_id, 0))

func foi_recolhido(recolha_id: String) -> bool:
	return recolhas.has(recolha_id)

func marcar_recolhido(recolha_id: String) -> void:
	recolhas[recolha_id] = true

# Perde recursos ao ser atingido por perigos (ex: Javali ou batida de carrinho)
func perder_recursos_aleatorios(quantidade: int = 2) -> Array[String]:
	var perdidos: Array[String] = []
	var chaves := inventario.keys()
	if chaves.is_empty():
		return perdidos
		
	for i in range(quantidade):
		if chaves.is_empty():
			break
		var item_sorteado: String = chaves[randi() % chaves.size()]
		if remover_item(item_sorteado, 1):
			perdidos.append(item_sorteado)
		if obter_quantidade(item_sorteado) <= 0:
			chaves.erase(item_sorteado)
			
	return perdidos
