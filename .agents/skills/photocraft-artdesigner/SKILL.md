---
name: photocraft-artdesigner
description: >-
  Especialidade avançada em processamento técnico de imagens, arte 2D, máscaras alfa,
  fatiamento de spritesheets e pipeline gráfica utilizando a arquitetura do PhotoCraft
  (Rust/MCP/CLI) e scripts de automação para o jogo 'A Loja do Alquimista - Marcos de Canaveses'.
---

# Skill: PhotoCraft Art Designer & Asset Pipeline

Esta skill capacita o agente a operar como Diretor Técnico de Arte e Designer Gráfico do jogo, aproveitando o código-fonte, os algoritmos e a automação do **PhotoCraft** (localizado em `ferramentas/photocraft/photocraft-main`) combinados com os padrões visuais em Pixel Art estabelecidos em `LISTA_ASSETS.md`.

---

## 1. Capacidades e Ferramentas do PhotoCraft

O PhotoCraft é uma reimplementação limpa em Rust do Adobe Photoshop, fornecendo:
- **Camadas e Máscaras**: Processamento multicanal (RGBA 8-bit, 16-bit e 32-bit float), suporte a blend modes (Multiply, Screen, Overlay, etc.) e máscaras vetoriais/rasterizadas.
- **Fatiamento e Normalização (Batch Slicing)**: Algoritmos de detecção de bounding box, recorte automático com centralização de pivô nos pés e normalização de canvas (128x128, 96x96, etc.).
- **Remoção de Fundo e Chroma Keying**: Extração limpa de fundos sólidos ou xadrez (checkerboard) sem resíduos cinzentos nem halos nas bordas dos sprites.
- **Quantização de Cores e Paletas**: Redução para paleta estrita de 16/32 cores preservando o estilo SNES / GBA pixel art.
- **Automação Headless e MCP**: O crate `crates/automation` permite orquestração via linha de comando ou JSON-RPC (`photocraft-cli mcp`).

---

## 2. Padrões Visuais de 'A Loja do Alquimista'

Todos os assets criados para o projeto devem obedecer rigorosamente às diretrizes:
1. **Resolução de Tela**: Viewport lógica de **640 × 360** (proporção 16:9).
2. **Escala dos Personagens**:
   - Marco (Jogador) e Clientes: **~36 a 38 px** de altura, pivô nos pés `(0, 0)`.
   - Lutadores de Tongóbriga (Combate 2D): **~50 a 60 px** de altura, proporção arcade fighting game.
   - Mobiliário: Balcões e mesas na linha da cintura (~20 a 24 px do chão).
3. **Paleta Regional (Marco de Canaveses & Vale do Tâmega)**:
   - Granito verde-acinzentado (`#464b4c`, `#5f6668`, `#828a8c`).
   - Madeira de carvalho quente e castanheiro (`#2d1c12`, `#4e301c`, `#70482a`).
   - Latão e bronze envelhecido (`#8a5c24`, `#c28c36`).
   - Verde esmeralda e musgo das serras (`#122616`, `#234a26`, `#3a7636`).

---

## 3. Fluxo de Trabalho do Art Designer

Quando solicitado para criar ou fatiar assets:
1. **Verificação de Referências**: Consultar `Assets/Source/raw/references/` e `LISTA_ASSETS.md`.
2. **Processamento / Geração**:
   - Executar scripts em `ferramentas/` (ou scripts Python/PhotoCraft) para fatiar, limpar canal alfa e centrar frames.
   - Gerar spritesheets horizontais limpos e organizados por animação (`idle`, `move`, `jump`, `punch`, `kick`, `special`, etc.).
3. **Empacotamento para Godot**:
   - Exportar para `Assets/Characters/`, `Assets/Environment/` ou `Assets/Icons/`.
   - Garantir PNG 32-bit com transparência real.
   - Criar ou atualizar os arquivos `.tscn` e `.tres` (`SpriteFrames`) correspondentes.
4. **Validação de Proporções**: Testar a colisão e altura em relação ao cenário e aos outros personagens.

