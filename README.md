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

1. Veja o pedido e o tempo de paciência do cliente.
2. Selecione e entregue a poção pedida no balcão antes que o tempo termine.
3. Ganhe escudos com as vendas e acompanhe o stock no painel.
4. Prepare poções no caldeirão. Cada receita consome os ingredientes listados no painel.
5. Reponha ingredientes no fornecedor com os escudos ganhos nas vendas.
6. Clientes só pedem poções que estejam disponíveis em stock.

O inventário inicial inclui quatro poções de demonstração e ingredientes para testar as quatro receitas. O inventário é mantido pelo autoload `InventoryManager` durante a sessão.

## Escopo desta alfa

Esta versão valida movimento, interação, receitas, stock, pedidos aleatórios, paciência e vendas. Os gráficos são formas provisórias e o progresso não é guardado entre execuções. Arte final, áudio, menu, balanceamento e exportação para plataformas ficam para versões seguintes.
