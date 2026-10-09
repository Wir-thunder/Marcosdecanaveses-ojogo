# A Loja do Alquimista — Alfa 0.1

Protótipo jogável em Godot 4.7 de uma loja de poções inspirada em Marco de Canaveses.

## Executar

Abra `project.godot` no Godot 4.7 e carregue em **Executar projeto (F6/F5)**. A cena principal é `Cenas/cena_principal.tscn`.

## Controlos

- **WASD / setas** — mover o alquimista.
- **E / Espaço** — preparar uma poção no caldeirão, entregar a poção pedida ou comprar ingredientes junto do fornecedor.
- **Q** — selecionar a próxima poção que tenha stock.
- **Tab** — selecionar a próxima receita quando estiver junto do caldeirão.
- **F** — selecionar um ingrediente quando estiver junto do fornecedor.
- **Esc** — pausar/retomar; o menu também permite reiniciar o turno ou sair.

## Ciclo de jogo

1. O primeiro cliente pede a poção que já tens selecionada; aproxima-te do balcão e carrega em **E**.
2. Para os pedidos seguintes, usa **Q** até selecionares a poção pedida e entrega-a no balcão.
3. Ganha escudos com as vendas e acompanha o pedido, a poção selecionada e o stock no painel.
4. Junto ao caldeirão, usa **Tab** para escolher a receita e **E** para preparar a poção.
5. No fornecedor, usa **F** para escolher um ingrediente e **E** para o comprar.
6. As interações funcionam ao aproximar-se da estação; não é preciso acertar num pixel ou alinhar o boneco.

O inventário inicial inclui quatro poções de demonstração e ingredientes para testar as quatro receitas. O inventário é mantido pelo autoload `InventoryManager` durante a sessão.

## Escopo desta alfa

Esta versão valida movimento, interação, receitas, stock, pedidos aleatórios, paciência e vendas. Os gráficos são formas provisórias e o progresso não é guardado entre execuções. Arte final, áudio, menu, balanceamento e exportação para plataformas ficam para versões seguintes.
