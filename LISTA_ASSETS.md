# Lista de assets — A Loja do Alquimista

Brief para criar arte e áudio fora do projeto e depois importar para Godot 4.7.

## Direção visual recomendada

- Jogo 2D top-down, fantasia artesanal inspirada no Vale do Tâmega.
- Manter formas e silhuetas legíveis à escala pequena, com contornos consistentes e paleta curta: madeira quente, pedra verde/cinza, latão e cores vivas reservadas para ingredientes e poções.
- A janela de jogo é 640 × 360. Desenhar para esta escala; não depender de detalhes que só se vejam ampliados.
- Entregar imagens em PNG com transparência, sem texto embutido nos objetos. Guardar fontes editáveis e exportações finais.
- A direção visual é pixel art em todo o jogo. Usar filtro nearest-neighbor, pixels inteiros e uma paleta coerente; não misturar imagens suavizadas ou ilustração pintada com os sprites.

## Pacote de arte final a criar

O jogo já está configurado para pixel art, mas boa parte da arte de cenário atualmente ligada é um protótipo simples e deve ser substituída por sprites mais acabados e coerentes entre si. A prioridade é melhorar a qualidade visual, sem refazer spritesheets de personagens que já estão em pixel art utilizável.

### 1. Cenários e ambientes — prioridade máxima

Criar fundos finais 640 × 360 px ou tilesets modulares em grelha de 16 × 16 px, com camadas separadas quando houver elementos que devam ficar atrás ou à frente do jogador:

| Cena | Entrega a criar | O que existe hoje |
|---|---|---|
| **Loja** | Interior de loja de alquimia com parede, chão, janela e iluminação. Deixar as estações e a área de circulação legíveis. Exportar fundo sem balcão, caldeirão ou objetos que precisem de colisão/interação. | A loja usa `Sprites/Cenário_loja.jpeg`; `cenario_loja.png` é um protótipo antigo guardado em `referências_descartável/prototipos/`. |
| **Praça** | Praça portuguesa de fantasia: pavimento modular, caminhos, fonte, fachada da taverna, entradas para a loja/floresta/mina, bancos, postes e vegetação. | Cenário de `Assets/Environment/room/praça.jpeg`, convertido para 640 × 360 e ligado como fundo. Separar fachadas e objetos que devam ficar por cima do jogador na próxima passagem. |
| **Taverna** | Interior completo com paredes, vigas, lareira, balcão, prateleiras, mesas, cadeiras, copos e iluminação quente. Reservar uma zona livre para o painel de recrutamento. | Cenário de `Assets/Environment/room/Taverna.jpeg`, convertido para 640 × 360 e ligado como fundo; mobiliário ainda está todo atrás da interface/jogador. |
| **Floresta** | Tiles de relva, terra, caminho, água e limites; árvores em camadas, arbustos, flores, cogumelos, pedras e troncos. Fazer o caminho ligar corretamente à porta. | Cenário de `Assets/Environment/room/floresta.jpeg`, convertido para 640 × 360 e ligado como fundo; a grelha sobreposta foi atenuada, mas falta separar elementos para ordenação Y. |
| **Mina / dungeon** | Tiles de rocha e chão, paredes, entrada, vigas, galerias, cristais/minérios, carris ou entulho e lanternas. | Cenário de `Assets/Environment/room/Dungeon.jpeg`, convertido para 640 × 360 e ligado como fundo; continuar a limpeza da grelha/quadriculado e separar elementos interativos. |

### 2. Objetos das cenas

- **Loja:** redesenhar como conjunto coerente o balcão de atendimento, caldeirão, banca do fornecedor, prateleiras, frascos decorativos, ingredientes expostos, placas e pequenos objetos de bancada. Os sprites atuais de balcão, caldeirão e fornecedor já estão ligados, mas são protótipos, não uma lista de novos objetos necessários.
- **Praça:** fonte modular, bancos, candeeiros, vasos, sinalização e portas que correspondam aos destinos do jogo.
- **Taverna:** balcão, estante de garrafas, mesas, cadeiras, bancos, canecas, pratos, barris, sacos e detalhes de lareira.
- **Floresta:** variações de árvores e copas, arbustos, pedras, troncos, flores e versões visuais distintas dos quatro ingredientes que podem ser recolhidos.
- **Mina:** variações de parede/chão, suportes, entulho, veios de minério, cristais e moedas.
- **Portas e coleta:** sprite de porta diferente por destino, cristal para recursos e moeda para ouro; as versões simples existentes podem ser substituídas junto do novo conjunto.
- Entregar objetos em PNG transparente, com ponto de origem apropriado para ordenação Y. Não incluir texto nos sprites; as labels do jogo mantêm-se localizadas.

### 3. Personagens e expedições

- O Marco e os cinco clientes **já têm spritesheets pixel art ligados**. Não é necessário recriá-los para preencher uma lacuna funcional; substituir apenas se quiser redesenhar o estilo ou melhorar as folhas atuais.
- Criar **quatro spritesheets de aventureiro**, um por profissão (guerreiro, arqueiro, mago e curandeiro), com idle e caminhada nas quatro direções. Os recortes da referência `referências_descartável/sprites/aventureiros.jpeg` já fornecem retratos provisórios para a lista da taverna, mas não animações nem personagens visíveis durante a expedição.
- Criar estados do cliente (pedido, espera, impaciência e satisfação) como ícones pixel art ou pequenos balões, caso a informação deixe de aparecer apenas como texto.

### 4. Ícones, HUD e feedback

- Criar **70 ícones de itens**: 50 ingredientes e 20 poções, em PNG transparente de 32 × 32 px, um ficheiro por ID.
- Começar pelos **7 ingredientes e 4 poções** usados no inventário inicial/receitas ativas; completar os outros itens quando entrarem no ciclo jogável.
- Criar ícones de ouro, pedido de cliente, interação, receita, fornecedor, pausa, dia/noite e expedição. A seleção de poções agora tem teclas rápidas e botões funcionais; ícones próprios melhoram a leitura, mas não são bloqueio para essa mecânica.
- Criar uma moldura pixel art reutilizável em 9-slice para os painéis/HUD, mais estados de botão normal, selecionado, hover, pressionado e desativado.

### 5. Efeitos e áudio

- Efeitos pixel art: borbulhas/vapor do caldeirão, poção pronta, venda concluída, erro/falta de ingredientes, coleta e saída de cliente.
- Efeitos sonoros: passos, interação, fabricar poção, venda, compra, erro, abrir/fechar pausa e transição dia/noite.
- Música ambiente em loop para loja, taverna, floresta e mina; OGG para música e WAV mono (44,1 ou 48 kHz) para efeitos.

## Prioridade 1 — assets integrados que podem ser mantidos ou redesenhados

| Asset | Quantidade e entrega | Ligação no projeto |
|---|---|---|
| Alquimista/jogador | **Já existe:** spritesheet pixel art do Marco com quatro direções e animações. | `Cenas/Player.tscn`, usando `Sprites/Marco_prausar.png`. |
| Clientes | **Já existe:** spritesheet pixel art com cinco clientes e cópia transparente pronta para o jogo. | `Cenas/ClienteNPC.tscn` e `Scripts/ClienteNPC.gd`; a aparência é escolhida a partir de `Sprites/5clientes_transparente.png`. |
| Expressões/estado do cliente | Estados visuais `a chegar`, `à espera`, `satisfeito` e `impaciente`; pode ser animação curta ou ícone/balão acima da cabeça. | `ClienteNPC.gd` já tem os estados `ENTRANDO`, `ESPERANDO`, `SAINDO`, mas hoje mostra o estado só num `Label`. |
| Fundos e cenários jogáveis | **Existem e estão ligados**: loja, praça, taverna, floresta e mina. Alguns fundos são adaptações de folhas de cenário, não camadas finais prontas para colisão/ordenação. | `Sprites/` para fontes ainda usadas e `Assets/Environment/backgrounds/` para os cenários ligados; protótipos antigos estão em `referências_descartável/`. |
| Balcão, caldeirão e fornecedor | **Existem como sprites ligados**, mas podem ser redesenhados para casar com os novos cenários. | `Assets/Environment/props/` e `Cenas/cena_principal.tscn`. |
| Portas e recursos coletáveis | **Existem versões simples funcionais**, prontas para substituição artística. | `Assets/Environment/props/`, `Assets/Environment/items/` e cenas reutilizáveis. |
| Placas das estações | 3 símbolos sem palavras: atendimento, preparar poção e fornecedor; cada um legível a 16–24 px. | Complementam as labels `ATENDIMENTO`, `CALDEIRÃO` e `FORNECEDOR`; o texto continua localizado no jogo. |
| Sombra dos personagens | Sombra suave oval, PNG transparente de 16 × 8 px, com aproximadamente 40% de opacidade. | Reutilizar `Assets/Characters/sombra_personagem.png` num `Sprite2D` independente no pivô dos pés. |

## Prioridade 2 — ícones para itens e interface

Criar **um PNG quadrado de 32 × 32 px por item**, fundo transparente, silhueta distinta e sem letras ou números. Nomear pelo `id` indicado. Os recursos `ItemData` já têm o campo `icone: Texture2D`; preencher esse campo em cada `.tres`. A UI atual ainda apresenta nomes e quantidades como texto, por isso mostrar estes ícones na interface requer adicioná-los aos controlos de stock/pedido.

### Ingredientes — 50 ícones

Exportar um ficheiro por ID para `Assets/Icons/Ingredients/<id>.png`:

`acacia_branca`, `agua_tamega`, `alecrim_do_monte`, `alga_do_rio`, `amora_silvestre`, `aneto_do_campo`, `arnica_selvagem`, `azeite_do_olival`, `baga_escura`, `basalto_fervente`, `beterraba_da_lenda`, `calcedonia_fina`, `canela_da_cova`, `carqueja_do_solar`, `casca_ameixoeira`, `cebola_das_montanhas`, `centaurea_violeta`, `erva_cidreira`, `erva_lavanda`, `essencia_vinho_verde`, `figueira_carmim`, `flor_de_urze`, `fumo_de_lupulo`, `gengibre_do_vale`, `giesta_ardente`, `hortela_nobre`, `lagrima_douro`, `limao_selvagem`, `linho_do_curro`, `malagueta_piri-piri_ardente`, `malva_do_pombal`, `mel_do_olival`, `musgo_aboboreira`, `musgo_do_pombal`, `nectarina_do_sol`, `orvalho_do_pico`, `pimenta_do_verde`, `pinho_resinato`, `planta_de_lapa`, `po_granito_tongobriga`, `raiz_celeste`, `raiz_mandrago`, `roma_do_campo`, `salsa_cervina`, `sementes_do_sol`, `silva_do_veado`, `tomilho_do_mar`, `urze_azul`, `uva_do_conde`, `verbena_do_porto`.

### Poções — 20 ícones

Exportar um ficheiro por ID para `Assets/Icons/Potions/<id>.png`:

`elixir_da_flor`, `elixir_saudade`, `pocao_ascensao_dourada`, `pocao_bola_de_nuvem`, `pocao_escudo_do_lago`, `pocao_espinheira_real`, `pocao_fogo_do_paineiro`, `pocao_furia_do_trigo`, `pocao_luz_peregrina`, `pocao_mente_limpida`, `pocao_olhar_fino`, `pocao_pedra_viva`, `pocao_pele_de_ferro`, `pocao_raio_de_ouro`, `pocao_rio_ensolarado`, `pocao_sombra_longa`, `pocao_sono_puro`, `pocao_sussurro_do_vale`, `pocao_vento_ligeiro`, `pocao_vida_fertil`.

Começar pelos quatro itens usados nas receitas ativas:

| Poção | Ingredientes da receita |
|---|---|
| `pocao_vento_ligeiro` | `hortela_nobre` |
| `pocao_espinheira_real` | `musgo_aboboreira` + `arnica_selvagem` |
| `pocao_mente_limpida` | `calcedonia_fina` + `erva_cidreira` |
| `pocao_escudo_do_lago` | `po_granito_tongobriga` + `azeite_do_olival` |

### Interface e marcadores

- Ícone de escudo/moeda, 16 × 16 px.
- Ícones de ação/interação, receita, stock e pausa, 16 × 16 px, com silhuetas simples.
- Marcador de pedido do cliente: ícone da poção pedida com espaço visual para o temporizador.
- Estados de botão do menu de pausa: normal, hover, pressionado e desativado; entregar apenas se a UI for receber um tema gráfico.
- Uma moldura/painel reutilizável para HUD e menu de pausa, em 9-slice, para se adaptar ao tamanho dos controlos sem esticar cantos.

## Prioridade 3 — feedback visual e áudio

Estes elementos ainda não têm nós de áudio ou partículas ligados; são um lote posterior, depois de a arte base estar integrada:

- Caldeirão: 3–5 bolhas, vapor contínuo e brilho curto quando uma poção é preparada.
- Venda concluída: brilho/moedas ou pequeno indicador de escudos ganhos.
- Erro/falta de ingrediente: indicador curto e discreto junto da estação.
- Sons curtos: passos, interação, preparar poção, venda, compra, erro e abrir/fechar pausa.
- Música ambiente em loop para a loja, sem competir com os efeitos.

Para áudio, entregar WAV para efeitos (mono, 44,1 kHz ou 48 kHz) e OGG para música em loop; confirmar que os loops não têm clique no início/fim.

## Estrutura de entrega sugerida

```text
Assets/
  Characters/
    alchemist.png
    customers/
  Environment/
    room/
    props/
  Icons/
    Ingredients/
    Potions/
    UI/
  Effects/
  Audio/
    SFX/
    Music/
```

Manter os nomes de ficheiro em minúsculas, sem espaços e iguais aos IDs quando forem itens. Ao importar, conservar o ponto de pivô dos personagens nos pés (centro inferior) e deixar transparência à volta das sprites.

## Estado verificado no projeto

- O projeto usa viewport lógica de 640 × 360 px, filtro nearest-neighbor e alinhamento de sprites a pixels inteiros.
- A loja usa `Sprites/Cenário_loja.jpeg`; praça, floresta, mina e taverna usam versões preparadas em `Assets/Environment/backgrounds/`. Praça e taverna estão convertidas para 640 × 360; a grelha da floresta foi removida. A mina ainda precisa de limpeza e separação de camadas.
- O jogador usa `Sprites/Marco_prausar.png`; os cinco clientes usam `Sprites/5clientes_transparente.png`. Fontes e imagens sem uso direto no jogo foram preservadas em `referências_descartável/`, por categoria, em vez de apagadas.
- As áreas continuam ligadas por portas com `E`; os recursos e escudos recolhidos persistem enquanto a sessão estiver aberta.
- Há 50 recursos de ingredientes e 20 recursos de poções. Todos podem receber ícone através de `ItemData.icone`.
- Apenas 4 receitas estão ligadas ao caldeirão e só 4 poções fazem parte do stock inicial/pedidos jogáveis. Os restantes itens têm dados, mas ainda não estão no ciclo principal. Os 70 ícones específicos de ingredientes e poções continuam por criar.
