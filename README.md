# A Loja do Alquimista — Alfa 0.1

Protótipo jogável em Godot 4.7 de uma loja de poções inspirada em Marco de Canaveses.

## Executar

Abra `project.godot` no Godot 4.7 e carregue em **Executar projeto (F6/F5)**. O jogo começa com a introdução em vídeo; carrega em **Espaço** ou **Enter** para a ignorar. Depois, o jogador entra na praça junto à saída para a floresta.

## Controlos

- **WASD / setas** — mover o alquimista.
- **E / Espaço** — preparar uma poção no caldeirão, entregar a poção pedida ou comprar ingredientes junto do fornecedor.
- **Q** — selecionar a próxima poção que tenha stock.
- **Tab** — selecionar a próxima receita quando estiver junto do caldeirão.
- **F** — selecionar um ingrediente quando estiver junto do fornecedor.
- **Esc** — pausar/retomar; o menu também permite reiniciar o turno ou sair.

## Ciclo de jogo

1. Cada dia começa de manhã com o relógio parado para poderes abastecer e preparar poções. **Play** inicia o atendimento de três minutos; **Pause** congela a simulação e **2×** alterna a aceleração. Durante o turno chegam cinco clientes, um de cada visual do spritesheet, por uma ordem aleatória. O nível, o preço e a velocidade/paciência variam por cliente. A janela abre a 1280 × 720 e a interface da loja foi compactada para ampliar a área de jogo.
2. Aproxima-te do balcão e carrega em **E** para entregar a poção pedida. Usa **Q** para trocar de poção; junto ao caldeirão, **Tab** escolhe a receita e **E** prepara-a.
3. As vendas rendem ouro. Usa **F** e **E** junto do fornecedor para comprar ingredientes.
4. Quando o turno termina, o Marco sai para a praça. À noite, aproxima-se do balcão da taverna e carrega em **E** para abrir ou fechar o painel de ofertas: há um mercenário de cada profissão — guerreiro, arqueiro, mago e curandeiro — com níveis, habilidades e preços diferentes. **Esc** também fecha o painel. As ofertas ficam mais fortes e caras à medida que os dias avançam.
5. Contrata aventureiros com o ouro das vendas, seleciona até quatro e envia a equipa à dungeon. A expedição dura de dois a cinco dias de jogo: começa à noite e continua durante os turnos da loja e os dias seguintes. Podes consultar o progresso na taverna quando voltares à noite.
6. A qualidade do saque aumenta com os dias passados na expedição, o nível médio da equipa e o avanço da campanha. A equipa traz ingredientes mais raros, ouro e experiência para subir de nível; as habilidades também influenciam as recompensas.
7. Usa **Regressar à loja** na taverna para voltar à manhã do dia seguinte, mesmo que a expedição ainda esteja ativa.
8. As interações com estações e portas funcionam ao aproximar-se e carregar em **E**; atravessa a abertura da porta da loja para sair para a praça.
9. Os ambientes têm limites físicos e colisões nos principais objetos fixos, como fonte, árvores, rochas, balcão e mesas.

O inventário inicial inclui quatro poções de demonstração, ingredientes para testar as receitas e 100 de ouro. O inventário, os mercenários e as expedições mantêm-se durante a sessão; as expedições progridem enquanto o jogo está aberto e despausado, mas não avançam quando está fechado.

## Escopo desta alfa

Esta versão inclui movimento, interação, receitas, stock, turnos de atendimento, recrutamento e expedições idle. O jogador, os clientes, os cenários das áreas jogáveis, as portas e os recursos recolhíveis usam arte pixel art com filtro nearest-neighbor. Ainda faltam ícones individuais para ingredientes e poções, áudio, balanceamento e exportação para plataformas.
