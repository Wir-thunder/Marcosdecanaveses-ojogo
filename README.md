# A Loja do Alquimista — Alfa 0.1

Protótipo jogável em Godot 4.7 de uma loja de poções inspirada em Marco de Canaveses.

## Executar

Abra `project.godot` no Godot 4.7 e carregue em **Executar projeto (F6/F5)**. O jogo começa com a introdução em vídeo; carrega em **Espaço** ou **Enter** para a ignorar. Depois, o jogador entra na praça junto à saída para a floresta.

Para partilhar no Windows, envia `Distribuicao/Marcos-de-Canaveses.exe`; é um executável autónomo com os recursos do jogo incluídos. Para o recriar, usa o preset **Windows Desktop** em `export_presets.cfg` com o Godot 4.7.

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
5. Contrata aventureiros com o ouro das vendas, compara os níveis, atributos e preços das ofertas e seleciona até quatro para uma expedição jogável à dungeon. A expedição tem três salas ligadas por transições de cena e combates por turnos: escolhe o alvo, ataca, usa a habilidade de classe ou defende. O Curandeiro restaura vida, o Mago atinge vários inimigos, e o Guerreiro e o Arqueiro especializam-se em dano.
6. Vencer as salas concede ouro, materiais e experiência; a equipa recupera parte da vida entre salas e ganha experiência no fim da expedição. Ao subir de nível, os aventureiros aumentam o poder e a vida máxima. Recuar ou perder termina a expedição e regressa à taverna.
7. Visita a **Tongóbriga** a partir da praça para entrar na sala de guerra. Escolhe um dos oito campeões e disputa um torneio de três combates em tempo real: **A/D** ou setas para mover, **W/↑** para saltar, **J** soco, **K** pontapé, **L** defesa e **I** especial. Só podes disputar um torneio por dia; o campeão recebe ouro ao vencer.
8. Usa **Regressar à loja** na taverna para voltar à manhã do dia seguinte, mesmo que a expedição ainda esteja ativa.
9. As interações com estações e portas funcionam ao aproximar-se e carregar em **E**; atravessa a abertura da porta da loja para sair para a praça.
10. Os ambientes têm limites físicos e colisões nos principais objetos fixos, como fonte, árvores, rochas, balcão e mesas. A colisão do jogador é uma cápsula horizontal pequena ao nível dos pés; a câmara fica limitada ao mapa de 640 × 360 e a janela mantém esse rácio de aspeto.

O inventário inicial inclui quatro poções de demonstração, ingredientes para testar as receitas e 100 de ouro. O inventário e os aventureiros mantêm-se durante a sessão; as expedições avançam através dos combates jogáveis, não em segundo plano.

## Escopo desta alfa

Esta versão inclui movimento, interação, receitas, stock, turnos de atendimento, recrutamento, expedições RPG por turnos e torneio de luta em Tongóbriga. Os lutadores da arena usam personagens vetoriais provisórios; ainda faltam ícones individuais para ingredientes e poções, áudio, balanceamento e exportação para plataformas.
