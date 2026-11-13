"""
Gerador de Assets de Profundidade e Novos Portais Temáticos
Projeto: A Loja do Alquimista - Marcos de Canaveses
Gera:
1. Portais temáticos detalhados em pixel art (substituindo as 'portinhas trash')
2. Overlays de primeiro plano (Foreground) e atmosfera 640x360 com canal Alpha
3. Indicadores de soleira e transição sutil no chão
"""

from pathlib import Path
from PIL import Image, ImageDraw
import math

DIR_RAIZ = Path(__file__).resolve().parent.parent
DIR_PROPS = DIR_RAIZ / "Assets" / "Environment" / "props"
DIR_OVERLAYS = DIR_RAIZ / "Assets" / "Environment" / "overlays"

DIR_PROPS.mkdir(parents=True, exist_ok=True)
DIR_OVERLAYS.mkdir(parents=True, exist_ok=True)

# ==============================================================================
# PALETAS DE CORES TEMÁTICAS (Inspiradas em Marco de Canaveses / Tâmega)
# ==============================================================================
C_TRANSPARENTE = (0, 0, 0, 0)

# Madeiras
MADEIRA_ESCURA = (45, 28, 18, 255)
MADEIRA_MEDIA  = (78, 48, 28, 255)
MADEIRA_CLARA  = (112, 72, 42, 255)
MADEIRA_BRILHO = (145, 96, 58, 255)

# Granito / Cantaria de Canaveses & Tongóbriga
GRANITO_SOMBRA = (42, 45, 46, 255)
GRANITO_BASE   = (70, 75, 76, 255)
GRANITO_MEDIO  = (95, 102, 104, 255)
GRANITO_CLARO  = (130, 138, 140, 255)
GRANITO_BRILHO = (168, 175, 178, 255)

# Metais (Ferro Forjado e Bronze)
FERRO_ESCURO   = (25, 26, 28, 255)
FERRO_MEDIO    = (48, 50, 54, 255)
BRONZE_BASE    = (138, 92, 36, 255)
BRONZE_BRILHO  = (194, 140, 54, 255)
OURO_LOURO     = (220, 175, 60, 255)

# Folhagens e Natureza
VERDE_PROFUNDO = (18, 38, 22, 255)
VERDE_FOLHA    = (35, 74, 38, 255)
VERDE_MEDIO    = (58, 118, 54, 255)
VERDE_CLARO    = (92, 168, 72, 255)
VERDE_MUSGO    = (75, 120, 48, 255)

# Iluminação e Atmosfera
LUZ_AMBAR      = (255, 210, 110, 220)
LUZ_AZUL_CRISTAL = (110, 215, 245, 200)
VINHO_TINTA    = (80, 25, 35, 255)


# ==============================================================================
# 1. PORTAL DA LOJA DO ALQUIMISTA (portal_loja.png - 48 x 52 px)
# Fachada de cantaria de granito com arco nobre, vitral alquímico, porta
# de carvalho com ferragens em ferro e tabuleta suspensa com frasco de poção.
# ==============================================================================
def criar_portal_loja():
    w, h = 48, 52
    img = Image.new("RGBA", (w, h), C_TRANSPARENTE)
    draw = ImageDraw.Draw(img)

    # Sombra projetada no chão
    draw.ellipse([4, h - 8, w - 4, h - 1], fill=(15, 15, 20, 110))

    # Arco de Pedra / Cantaria de Granito Exterior
    for y in range(4, h - 4):
        largura_arco = 18 if y < 14 else 20
        cx = w // 2
        draw.rectangle([cx - largura_arco, y, cx + largura_arco, y], fill=GRANITO_BASE)

    # Moldura de tijolos de cantaria
    for x in range(5, 11):
        for y in range(8, h - 4, 6):
            cor = GRANITO_CLARO if (x + y) % 5 == 0 else GRANITO_MEDIO
            draw.point((x, y), fill=cor)
    for x in range(w - 11, w - 5):
        for y in range(8, h - 4, 6):
            cor = GRANITO_CLARO if (x + y) % 5 == 0 else GRANITO_MEDIO
            draw.point((x, y), fill=cor)

    # Beiral superior com telha cerâmica de barro (estilo português)
    for x in range(3, w - 3):
        draw.point((x, 3), fill=(168, 65, 38, 255))
        draw.point((x, 4), fill=(138, 48, 26, 255))
        draw.point((x, 5), fill=(98, 32, 16, 255))

    # Vão interno da porta (profundidade / sombra interior)
    draw.rectangle([11, 14, 36, h - 5], fill=(20, 15, 12, 255))

    # Vitral arqueado superior com luz esmeralda de poções
    for vx in range(13, 35):
        for vy in range(14, 23):
            dist = math.sqrt((vx - 24)**2 + (vy - 23)**2 * 1.5)
            if dist < 10:
                brilho = int(max(40, 220 - dist * 18))
                draw.point((vx, vy), fill=(30, min(255, brilho + 20), int(brilho * 0.7), 240))
    # Grade de ferro do vitral
    draw.line([24, 14, 24, 23], fill=FERRO_ESCURO)
    draw.line([16, 19, 32, 19], fill=FERRO_ESCURO)

    # Porta de Carvalho com 2 batentes entreabertos
    # Batente esquerdo
    draw.rectangle([12, 24, 23, h - 5], fill=MADEIRA_MEDIA)
    draw.rectangle([13, 26, 22, h - 7], fill=MADEIRA_CLARA)
    draw.rectangle([15, 28, 20, 36], fill=MADEIRA_ESCURA)
    draw.rectangle([15, 39, 20, h - 9], fill=MADEIRA_ESCURA)
    # Dobradiças de ferro forjado
    draw.rectangle([11, 27, 15, 29], fill=FERRO_MEDIO)
    draw.rectangle([11, 42, 15, 44], fill=FERRO_MEDIO)

    # Batente direito (ligeiramente entreaberto revelando luz quente interior)
    draw.rectangle([24, 24, 35, h - 5], fill=(30, 20, 15, 255))
    draw.line([24, 24, 24, h - 5], fill=(255, 220, 120, 220)) # Fresta de luz âmbar acolhedora
    draw.rectangle([26, 24, 35, h - 5], fill=MADEIRA_MEDIA)
    draw.rectangle([27, 26, 34, h - 7], fill=MADEIRA_CLARA)
    draw.point((28, 35), fill=BRONZE_BRILHO) # Maçaneta de bronze

    # Tabuleta suspensa por haste de ferro na lateral direita com frasco de poção
    draw.line([37, 18, 45, 18], fill=FERRO_MEDIO) # Suporte de ferro
    draw.line([39, 19, 39, 21], fill=FERRO_ESCURO)
    draw.line([44, 19, 44, 21], fill=FERRO_ESCURO)
    # Placa de madeira
    draw.rectangle([38, 21, 45, 29], fill=MADEIRA_ESCURA)
    draw.rectangle([39, 22, 44, 28], fill=MADEIRA_MEDIA)
    # Símbolo do frasco de poção brilhante na placa
    draw.point((41, 24), fill=(120, 240, 255, 255))
    draw.point((42, 24), fill=(120, 240, 255, 255))
    draw.point((41, 25), fill=(80, 210, 240, 255))
    draw.point((42, 25), fill=(80, 210, 240, 255))
    draw.point((41, 26), fill=(40, 170, 220, 255))
    draw.point((42, 26), fill=(40, 170, 220, 255))

    # Soleira de pedra na base da porta
    draw.rectangle([10, h - 6, 37, h - 4], fill=GRANITO_CLARO)
    draw.rectangle([10, h - 4, 37, h - 3], fill=GRANITO_SOMBRA)

    out_file = DIR_PROPS / "portal_loja.png"
    img.save(out_file, "PNG")
    print(f"[OK] Criado: {out_file}")


# ==============================================================================
# 2. PORTAL DA FLORESTA DO TÂMEGA (portal_floresta.png - 48 x 52 px)
# Trilha rústica verdejante emoldurada por dois carvalhos com folhagens,
# placas de madeira talhadas apontando 'FLORESTA / TÂMEGA' e musgo no chão.
# ==============================================================================
def criar_portal_floresta():
    w, h = 48, 52
    img = Image.new("RGBA", (w, h), C_TRANSPARENTE)
    draw = ImageDraw.Draw(img)

    # Sombra do solo
    draw.ellipse([2, h - 9, w - 2, h - 1], fill=(12, 20, 14, 100))

    # Tronco da Árvore Esquerda (Carvalho tortuoso)
    for y in range(12, h - 4):
        bx = int(8 + math.sin(y * 0.2) * 2)
        draw.rectangle([bx - 4, y, bx + 3, y], fill=MADEIRA_ESCURA)
        draw.rectangle([bx - 2, y, bx + 1, y], fill=MADEIRA_MEDIA)

    # Tronco da Árvore Direita
    for y in range(14, h - 4):
        bx = int(39 - math.cos(y * 0.18) * 2)
        draw.rectangle([bx - 3, y, bx + 4, y], fill=MADEIRA_ESCURA)
        draw.rectangle([bx - 1, y, bx + 2, y], fill=MADEIRA_MEDIA)

    # Arco de Galhos e Folhagens no topo que une as árvores
    for x in range(4, w - 4):
        for y in range(2, 20):
            dist = math.sqrt((x - 24)**2 * 0.5 + (y - 5)**2 * 1.8)
            if dist < 16:
                cor = VERDE_PROFUNDO if dist > 12 else (VERDE_FOLHA if dist > 7 else VERDE_MEDIO)
                if (x + y * 3) % 4 == 0:
                    cor = VERDE_CLARO
                draw.point((x, y), fill=cor)

    # Vão aberto da trilha de terra batida (perspectiva de caminho para o fundo)
    for y in range(22, h - 4):
        largura_trilha = int(7 + (y - 22) * 0.5)
        cx = 24
        draw.rectangle([cx - largura_trilha, y, cx + largura_trilha, y], fill=(62, 50, 32, 255))
        # Pedrinhas e musgo no chão da trilha
        if y % 3 == 0:
            draw.point((cx - largura_trilha + 2, y), fill=VERDE_MUSGO)
            draw.point((cx + largura_trilha - 2, y), fill=(85, 70, 45, 255))

    # Placa Rústica de Trilha na Árvore Esquerda
    draw.rectangle([11, 20, 24, 25], fill=MADEIRA_CLARA)
    draw.rectangle([12, 21, 23, 24], fill=MADEIRA_BRILHO)
    draw.point((24, 22), fill=MADEIRA_CLARA) # Ponta da seta apontando para dentro
    draw.point((24, 23), fill=MADEIRA_CLARA)
    # Linhas de texto simulado em pixel art na placa
    draw.line([13, 22, 21, 22], fill=MADEIRA_ESCURA)
    draw.line([14, 24, 19, 24], fill=MADEIRA_ESCURA)

    # Cogumelos silvestres vermelhos com pintas brancas na base
    draw.rectangle([6, h - 8, 9, h - 6], fill=(210, 45, 35, 255))
    draw.point((7, h - 8), fill=(255, 255, 255, 255))
    draw.line([7, h - 5, 8, h - 5], fill=(240, 230, 210, 255))

    # Flores silvestres e relva alta nas bordas
    draw.line([37, h - 8, 37, h - 5], fill=VERDE_CLARO)
    draw.point((37, h - 9), fill=(245, 210, 60, 255)) # Florzinha amarela
    draw.line([41, h - 7, 41, h - 5], fill=VERDE_CLARO)
    draw.point((41, h - 8), fill=(230, 110, 160, 255)) # Florzinha púrpura

    out_file = DIR_PROPS / "portal_floresta.png"
    img.save(out_file, "PNG")
    print(f"[OK] Criado: {out_file}")


# ==============================================================================
# 3. PORTAL DA DUNGEON / MINA ANTIGA (portal_mina.png - 52 x 54 px)
# Entrada de mina escavada em cantaria de rocha maciça com escoras de carvalho,
# lanterna de ferro suspensa acesa, dormentes de madeira e escuridão misteriosa.
# ==============================================================================
def criar_portal_mina():
    w, h = 52, 54
    img = Image.new("RGBA", (w, h), C_TRANSPARENTE)
    draw = ImageDraw.Draw(img)

    # Sombra do solo
    draw.ellipse([4, h - 8, w - 4, h - 1], fill=(10, 10, 15, 120))

    # Encosta de rocha natural ao redor do túnel
    for x in range(3, w - 3):
        for y in range(4, h - 4):
            # Se for na área externa ao túnel
            if x < 12 or x > 39 or y < 14:
                dist_pedra = ((x * 7 + y * 13) % 11)
                cor = GRANITO_BASE if dist_pedra < 5 else (GRANITO_MEDIO if dist_pedra < 9 else GRANITO_CLARO)
                draw.point((x, y), fill=cor)

    # Galeria escura da mina (profundidade / gradiente para o preto do interior)
    for y in range(14, h - 4):
        for x in range(12, 40):
            fator = (y - 14) / (h - 18)
            tom_profundo = int(12 + fator * 10)
            draw.point((x, y), fill=(tom_profundo, tom_profundo + 2, tom_profundo + 6, 255))

    # Vigas de Sustentação de Carvalho (Escoras de Mina)
    # Coluna esquerda
    draw.rectangle([10, 10, 15, h - 4], fill=MADEIRA_ESCURA)
    draw.rectangle([11, 11, 14, h - 5], fill=MADEIRA_MEDIA)
    # Coluna direita
    draw.rectangle([36, 10, 41, h - 4], fill=MADEIRA_ESCURA)
    draw.rectangle([37, 11, 40, h - 5], fill=MADEIRA_MEDIA)
    # Viga transversal superior
    draw.rectangle([8, 8, 43, 14], fill=MADEIRA_ESCURA)
    draw.rectangle([9, 9, 42, 13], fill=MADEIRA_MEDIA)
    draw.line([9, 9, 42, 9], fill=MADEIRA_CLARA)
    # Rebites de ferro nas junções
    draw.rectangle([11, 10, 13, 12], fill=FERRO_MEDIO)
    draw.rectangle([38, 10, 40, 12], fill=FERRO_MEDIO)

    # Lanterna de Mina suspensa na viga superior
    draw.line([20, 14, 20, 18], fill=FERRO_ESCURO) # Corrente
    draw.rectangle([18, 18, 22, 24], fill=FERRO_MEDIO)
    draw.rectangle([19, 19, 21, 23], fill=(255, 235, 140, 255)) # Chapa de vidro iluminada
    draw.point((20, 21), fill=(255, 255, 220, 255)) # Chama intensa
    # Brilho suave da lanterna
    for bx in range(15, 26):
        for by in range(16, 28):
            d = math.sqrt((bx - 20)**2 + (by - 21)**2)
            if 2 < d < 6:
                draw.point((bx, by), fill=(255, 200, 80, int(90 - d * 14)))

    # Cristais azulados embutidos na rocha da direita emitindo luz tênue
    draw.point((43, 20), fill=LUZ_AZUL_CRISTAL)
    draw.point((44, 21), fill=(180, 245, 255, 255))
    draw.point((43, 22), fill=LUZ_AZUL_CRISTAL)
    draw.point((42, 32), fill=LUZ_AZUL_CRISTAL)
    draw.point((43, 33), fill=(180, 245, 255, 255))

    # Dormentes / carris de madeira no chão da entrada
    draw.rectangle([15, h - 8, 36, h - 6], fill=MADEIRA_ESCURA)
    draw.rectangle([16, h - 7, 35, h - 6], fill=MADEIRA_MEDIA)

    out_file = DIR_PROPS / "portal_mina.png"
    img.save(out_file, "PNG")
    print(f"[OK] Criado: {out_file}")


# ==============================================================================
# 4. PORTAL DA TAVERNA (portal_taverna.png - 48 x 52 px)
# Fachada rústica tradicional com vigas de enxaimel, tocha de parede acesa,
# porta de carvalho de 2 batentes, vitral âmbar e tabuleta de caneca/barril.
# ==============================================================================
def criar_portal_taverna():
    w, h = 48, 52
    img = Image.new("RGBA", (w, h), C_TRANSPARENTE)
    draw = ImageDraw.Draw(img)

    # Sombra do solo
    draw.ellipse([4, h - 8, w - 4, h - 1], fill=(18, 14, 12, 110))

    # Parede de adobe / enxaimel rústico da taverna
    for y in range(4, h - 4):
        for x in range(6, w - 6):
            draw.point((x, y), fill=(162, 138, 108, 255))

    # Vigas de enxaimel de carvalho escuro emoldurando a fachada
    draw.rectangle([6, 4, 11, h - 4], fill=MADEIRA_ESCURA)
    draw.rectangle([w - 12, 4, w - 7, h - 4], fill=MADEIRA_ESCURA)
    draw.rectangle([6, 4, w - 7, 9], fill=MADEIRA_ESCURA)
    draw.rectangle([8, 6, w - 9, 8], fill=MADEIRA_MEDIA)

    # Telhado português com beiral de telhas
    for x in range(3, w - 3):
        draw.point((x, 2), fill=(160, 60, 32, 255))
        draw.point((x, 3), fill=(125, 42, 22, 255))

    # Janela superior redonda com vitral âmbar aconchegante
    for vx in range(19, 29):
        for vy in range(11, 21):
            if (vx - 24)**2 + (vy - 16)**2 <= 16:
                draw.point((vx, vy), fill=(255, 185, 65, 240))
    # Cruzeta da janela
    draw.line([24, 12, 24, 20], fill=MADEIRA_ESCURA)
    draw.line([20, 16, 28, 16], fill=MADEIRA_ESCURA)

    # Porta de Carvalho Nobre da Taverna
    draw.rectangle([13, 22, 34, h - 5], fill=MADEIRA_ESCURA)
    draw.rectangle([15, 24, 22, h - 6], fill=MADEIRA_MEDIA)
    draw.rectangle([24, 24, 32, h - 6], fill=MADEIRA_MEDIA)
    # Postigo de ferro com barras
    draw.rectangle([17, 26, 20, 32], fill=(25, 20, 15, 255))
    draw.line([18, 26, 18, 32], fill=FERRO_MEDIO)
    draw.rectangle([26, 26, 29, 32], fill=(25, 20, 15, 255))
    draw.line([27, 26, 27, 32], fill=FERRO_MEDIO)
    # Reforços de ferro com cravos
    draw.line([14, 36, 33, 36], fill=FERRO_ESCURO)
    draw.point((16, 36), fill=FERRO_MEDIO)
    draw.point((31, 36), fill=FERRO_MEDIO)

    # Tocha de Ferro na parede esquerda com chama viva
    draw.line([8, 22, 8, 27], fill=FERRO_ESCURO)
    draw.rectangle([7, 21, 9, 23], fill=FERRO_MEDIO)
    # Chama da tocha
    draw.point((8, 18), fill=(255, 240, 160, 255))
    draw.rectangle([7, 19, 9, 21], fill=(255, 130, 20, 255))
    draw.point((8, 20), fill=(255, 210, 60, 255))

    # Tabuleta de Ferro Forjado suspensa à direita com caneca espumante
    draw.line([36, 14, 45, 14], fill=FERRO_MEDIO)
    draw.line([38, 15, 38, 17], fill=FERRO_ESCURO)
    draw.line([43, 15, 43, 17], fill=FERRO_ESCURO)
    # Placa de madeira
    draw.rectangle([37, 17, 44, 25], fill=MADEIRA_ESCURA)
    draw.rectangle([38, 18, 43, 24], fill=MADEIRA_MEDIA)
    # Caneca de cerveja em pixel art na tabuleta
    draw.rectangle([39, 20, 41, 23], fill=BRONZE_BRILHO)
    draw.point((42, 21), fill=BRONZE_BRILHO) # Asa da caneca
    draw.point((42, 22), fill=BRONZE_BRILHO)
    draw.rectangle([39, 19, 41, 19], fill=(255, 255, 240, 255)) # Espuma branca

    out_file = DIR_PROPS / "portal_taverna.png"
    img.save(out_file, "PNG")
    print(f"[OK] Criado: {out_file}")


# ==============================================================================
# 5. PORTAL DE TONGÓBRIGA (portal_tongobriga.png - 56 x 56 px)
# Arco monumental romano em cantaria pura de granito de Tongóbriga, com colunas
# caneladas, arquitrave clássica com relevos, louros dourados e passagem profunda.
# ==============================================================================
def criar_portal_tongobriga():
    w, h = 56, 56
    img = Image.new("RGBA", (w, h), C_TRANSPARENTE)
    draw = ImageDraw.Draw(img)

    # Sombra no chão
    draw.ellipse([4, h - 8, w - 4, h - 1], fill=(15, 15, 18, 110))

    # Vão profundo interno em perspectiva
    for y in range(16, h - 4):
        for x in range(14, w - 14):
            prof = (y - 16) / (h - 20)
            cor_v = int(24 + prof * 18)
            draw.point((x, y), fill=(cor_v + 6, cor_v + 2, cor_v, 255))

    # Degraus de pedra entrando no arco (ilusão 3D de profundidade)
    for dy in range(h - 12, h - 4, 3):
        draw.line([15, dy, w - 15, dy], fill=GRANITO_CLARO)
        draw.line([15, dy + 1, w - 15, dy + 1], fill=GRANITO_SOMBRA)

    # Pilares Romanos Canelados (Esquerda e Direita)
    # Coluna Esquerda
    draw.rectangle([6, 12, 14, h - 4], fill=GRANITO_MEDIO)
    draw.line([8, 14, 8, h - 6], fill=GRANITO_CLARO) # Canelura clara
    draw.line([10, 14, 10, h - 6], fill=GRANITO_SOMBRA) # Canelura sombra
    draw.line([12, 14, 12, h - 6], fill=GRANITO_CLARO)
    # Base e capitel esquerdo
    draw.rectangle([5, 10, 15, 13], fill=GRANITO_CLARO)
    draw.rectangle([4, h - 6, 16, h - 4], fill=GRANITO_CLARO)

    # Coluna Direita
    draw.rectangle([w - 15, 12, w - 7, h - 4], fill=GRANITO_MEDIO)
    draw.line([w - 13, 14, w - 13, h - 6], fill=GRANITO_CLARO)
    draw.line([w - 11, 14, w - 11, h - 6], fill=GRANITO_SOMBRA)
    draw.line([w - 9, 14, w - 9, h - 6], fill=GRANITO_CLARO)
    # Base e capitel direito
    draw.rectangle([w - 16, 10, w - 6, 13], fill=GRANITO_CLARO)
    draw.rectangle([w - 17, h - 6, w - 5, h - 4], fill=GRANITO_CLARO)

    # Arco de Volta Perfeita Romano Superior
    cx, cy = w // 2, 18
    for angle in range(0, 181, 2):
        rad = math.radians(angle)
        for r in range(11, 16):
            px = int(cx + r * math.cos(rad))
            py = int(cy - r * math.sin(rad))
            cor = GRANITO_CLARO if r == 15 else (GRANITO_MEDIO if r > 12 else GRANITO_SOMBRA)
            draw.point((px, py), fill=cor)

    # Pedra de Fecho (Chave do Arco) no centro superior
    draw.rectangle([cx - 3, 2, cx + 3, 8], fill=GRANITO_BRILHO)
    draw.rectangle([cx - 2, 3, cx + 2, 7], fill=OURO_LOURO) # Detalhe imperial dourado

    # Entablamento / Frontão Superior Romano
    draw.rectangle([4, 4, w - 5, 8], fill=GRANITO_MEDIO)
    draw.line([3, 4, w - 4, 4], fill=GRANITO_BRILHO)
    draw.line([3, 8, w - 4, 8], fill=GRANITO_SOMBRA)

    # Estandarte romano carmesim suspenso na entrada com franja dourada
    draw.rectangle([cx - 5, 15, cx + 5, 23], fill=VINHO_TINTA)
    draw.line([cx - 5, 23, cx + 5, 23], fill=OURO_LOURO)
    draw.point((cx, 18), fill=OURO_LOURO)
    draw.point((cx - 2, 19), fill=OURO_LOURO)
    draw.point((cx + 2, 19), fill=OURO_LOURO)

    out_file = DIR_PROPS / "portal_tongobriga.png"
    img.save(out_file, "PNG")
    print(f"[OK] Criado: {out_file}")


# ==============================================================================
# 6. PORTAL DE SAÍDA / RETORNO À PRAÇA (portal_saida_trilha.png & portal_saida_mina.png)
# ==============================================================================
def criar_portais_retorno():
    # Saída da Floresta: Marco de Pedra com sinalização de Canaveses
    w, h = 42, 46
    img = Image.new("RGBA", (w, h), C_TRANSPARENTE)
    draw = ImageDraw.Draw(img)

    draw.ellipse([4, h - 8, w - 4, h - 1], fill=(12, 18, 12, 90))

    # Marco Geodésico / Marco Românico de Pedra de Canaveses
    draw.rectangle([8, 16, 16, h - 5], fill=GRANITO_BASE)
    draw.rectangle([9, 17, 15, h - 6], fill=GRANITO_MEDIO)
    draw.point((10, 16), fill=GRANITO_CLARO)
    # Cruz / Marca Românica gravada na pedra
    draw.line([12, 22, 12, 28], fill=GRANITO_SOMBRA)
    draw.line([10, 24, 14, 24], fill=GRANITO_SOMBRA)

    # Placa de madeira com seta apontando para a Praça
    draw.rectangle([14, 12, 36, 20], fill=MADEIRA_ESCURA)
    draw.rectangle([15, 13, 35, 19], fill=MADEIRA_CLARA)
    # Seta direcional "-> PRAÇA"
    draw.line([20, 16, 29, 16], fill=MADEIRA_ESCURA)
    draw.point((28, 15), fill=MADEIRA_ESCURA)
    draw.point((28, 17), fill=MADEIRA_ESCURA)

    # Arbustos e flores
    draw.ellipse([26, h - 12, 38, h - 4], fill=VERDE_FOLHA)
    draw.point((30, h - 10), fill=VERDE_CLARO)
    draw.point((34, h - 8), fill=(255, 230, 80, 255))

    out_trilha = DIR_PROPS / "portal_saida_trilha.png"
    img.save(out_trilha, "PNG")
    print(f"[OK] Criado: {out_trilha}")

    # Saída da Mina: Pórtico de escoras com iluminação externa entrando
    w2, h2 = 44, 46
    img2 = Image.new("RGBA", (w2, h2), C_TRANSPARENTE)
    draw2 = ImageDraw.Draw(img2)

    draw2.ellipse([4, h2 - 8, w2 - 4, h2 - 1], fill=(10, 10, 15, 110))
    # Claridade exterior da praça
    for y in range(12, h2 - 4):
        for x in range(10, w2 - 10):
            draw2.point((x, y), fill=(230, 240, 210, 210))

    # Vigas de madeira emoldurando
    draw2.rectangle([6, 8, 11, h2 - 4], fill=MADEIRA_ESCURA)
    draw2.rectangle([w2 - 12, 8, w2 - 7, h2 - 4], fill=MADEIRA_ESCURA)
    draw2.rectangle([4, 6, w2 - 5, 11], fill=MADEIRA_ESCURA)
    draw2.rectangle([5, 7, w2 - 6, 10], fill=MADEIRA_MEDIA)

    # Placa rústica no topo: "SAÍDA"
    draw2.rectangle([14, 12, 30, 17], fill=MADEIRA_CLARA)
    draw2.line([16, 14, 28, 14], fill=MADEIRA_ESCURA)

    out_mina = DIR_PROPS / "portal_saida_mina.png"
    img2.save(out_mina, "PNG")
    print(f"[OK] Criado: {out_mina}")


# ==============================================================================
# 7. INDICADOR DE TRANSIÇÃO ELEGANTE NO CHÃO (indicador_passagem.png - 36 x 18 px)
# Substitui o visual tosco por uma demarcação suave de soleira em relevo
# ==============================================================================
def criar_indicador_passagem():
    w, h = 36, 18
    img = Image.new("RGBA", (w, h), C_TRANSPARENTE)
    draw = ImageDraw.Draw(img)

    # Elipse suave de sombra e pedra polida
    draw.ellipse([2, 2, w - 3, h - 3], fill=(30, 32, 35, 110))
    draw.ellipse([4, 4, w - 5, h - 5], fill=(70, 75, 78, 140))
    draw.ellipse([6, 5, w - 7, h - 6], fill=(110, 118, 122, 160))

    # Marcadores sutis dourados em arco
    pontos = [(10, 8), (14, 11), (18, 12), (22, 11), (26, 8)]
    for px, py in pontos:
        draw.point((px, py), fill=(240, 210, 120, 210))

    out_file = DIR_PROPS / "indicador_passagem.png"
    img.save(out_file, "PNG")
    print(f"[OK] Criado: {out_file}")

    # Também atualizamos porta_pixel.png como fallback de qualidade superior
    out_fallback = DIR_PROPS / "porta_pixel.png"
    img_fallback = Image.open(DIR_PROPS / "portal_loja.png")
    img_fallback.save(out_fallback, "PNG")
    print(f"[OK] Fallback atualizado: {out_fallback}")


# ==============================================================================
# 8. OVERLAYS DE PRIMEIRO PLANO E PROFUNDIDADE ATMOSFÉRICA (640 x 360 px)
# Transforma as telas chapadas em ambientes imersivos com profundidade 2.5D:
# - Copas de árvores e beirais no topo (o jogador passa por baixo)
# - Vinheta suave de oclusão de cantos
# - Raios solares filtrados / névoa subterrânea translúcida
# ==============================================================================

def aplicar_vinheta_suave(draw, w, h, cor_vinheta=(10, 12, 15), opacidade_max=120):
    """Aplica vinheta radial suave que atrai o olhar para o centro da ação."""
    cx, cy = w / 2.0, h / 2.0
    max_dist = math.sqrt(cx**2 + cy**2)
    raio_limpo = 180.0 # Centro livre sem escurecimento

    for y in range(0, h, 2):
        for x in range(0, w, 2):
            dist = math.sqrt((x - cx)**2 + (y - cy)**2)
            if dist > raio_limpo:
                fator = min(1.0, (dist - raio_limpo) / (max_dist - raio_limpo))
                alpha = int((fator ** 1.8) * opacidade_max)
                if alpha > 4:
                    draw.rectangle([x, y, x + 1, y + 1], fill=(*cor_vinheta, alpha))


def criar_overlay_praca():
    w, h = 640, 360
    img = Image.new("RGBA", (w, h), C_TRANSPARENTE)
    draw = ImageDraw.Draw(img)

    # 1. Beirais de telhado superior projetando sombra arquitetônica
    for x in range(0, w):
        # Pequena variação de telha
        draw.line([x, 0, x, 6], fill=(135, 45, 25, 255))
        draw.line([x, 7, x, 10], fill=(105, 32, 18, 255))
        # Sombra suave da fachada sobre a calçada
        draw.line([x, 11, x, 18], fill=(20, 20, 25, 120))
        draw.line([x, 19, x, 24], fill=(20, 20, 25, 60))

    # 2. Copas de árvores em primeiro plano nos cantos superiores
    # Canto superior esquerdo
    for cx, cy, r in [(0, 0, 75), (55, 15, 60), (110, 0, 50)]:
        for x in range(max(0, cx - r), min(w, cx + r)):
            for y in range(max(0, cy - r), min(h, cy + r)):
                d = math.sqrt((x - cx)**2 + (y - cy)**2)
                if d < r:
                    noise = (x * 13 + y * 17) % 7
                    cor = VERDE_PROFUNDO if d > r - 12 else (VERDE_FOLHA if noise < 4 else VERDE_MEDIO)
                    alpha = int(min(240, 255 * (1.0 - (d / r)**3)))
                    draw.point((x, y), fill=(*cor[:3], alpha))

    # Canto superior direito
    for cx, cy, r in [(w, 0, 75), (w - 55, 15, 60), (w - 110, 0, 50)]:
        for x in range(max(0, cx - r), min(w, cx + r)):
            for y in range(max(0, cy - r), min(h, cy + r)):
                d = math.sqrt((x - cx)**2 + (y - cy)**2)
                if d < r:
                    noise = (x * 19 + y * 23) % 7
                    cor = VERDE_PROFUNDO if d > r - 12 else (VERDE_FOLHA if noise < 4 else VERDE_MEDIO)
                    alpha = int(min(240, 255 * (1.0 - (d / r)**3)))
                    draw.point((x, y), fill=(*cor[:3], alpha))

    # 3. Vinheta cinematográfica suave
    aplicar_vinheta_suave(draw, w, h, cor_vinheta=(15, 20, 22), opacidade_max=95)

    out_file = DIR_OVERLAYS / "praca_foreground.png"
    img.save(out_file, "PNG")
    print(f"[OK] Criado: {out_file}")


def criar_overlay_floresta():
    w, h = 640, 360
    img = Image.new("RGBA", (w, h), C_TRANSPARENTE)
    draw = ImageDraw.Draw(img)

    # 1. Dossel florestal denso cobrindo todo o topo da tela
    for x in range(0, w, 2):
        altura_copa = int(32 + math.sin(x * 0.04) * 14 + math.cos(x * 0.08) * 8)
        for y in range(0, altura_copa):
            fator_y = y / altura_copa
            cor = VERDE_PROFUNDO if fator_y < 0.6 else VERDE_FOLHA
            alpha = int(240 * (1.0 - fator_y * 0.2))
            draw.rectangle([x, y, x + 1, y], fill=(*cor[:3], alpha))
        # Sombra da copa projetada no chão
        for sy in range(altura_copa, altura_copa + 16):
            s_alpha = int(80 * (1.0 - (sy - altura_copa) / 16.0))
            draw.rectangle([x, sy, x + 1, sy], fill=(10, 25, 12, s_alpha))

    # Copas adicionais nas bordas laterais
    for cy in [60, 160, 260]:
        # Borda esquerda
        for x in range(0, 48):
            for y in range(max(0, cy - 36), min(h, cy + 36)):
                d = math.sqrt(x**2 + (y - cy)**2)
                if d < 44:
                    draw.point((x, y), fill=(*VERDE_PROFUNDO[:3], int(190 * (1 - d/44))))
        # Borda direita
        for x in range(w - 48, w):
            for y in range(max(0, cy - 36), min(h, cy + 36)):
                d = math.sqrt((w - x)**2 + (y - cy)**2)
                if d < 44:
                    draw.point((x, y), fill=(*VERDE_PROFUNDO[:3], int(190 * (1 - d/44))))

    # 2. Feixes de luz solar volumétrica filtrada (God Rays) através das árvores
    raios = [(120, 240), (280, 420), (460, 580)]
    for r_ini, r_fim in raios:
        for rx in range(r_ini, r_fim, 3):
            for ry in range(30, h - 20, 2):
                # Inclinação diagonal suave
                desloc = ry * 0.35
                px = int(rx + desloc)
                if 0 <= px < w:
                    intensidade = math.sin((rx - r_ini) / (r_fim - r_ini) * math.pi)
                    alpha = int(intensidade * 22 * (1.0 - ry / h * 0.5))
                    draw.rectangle([px, ry, px + 2, ry + 1], fill=(255, 250, 210, alpha))

    # 3. Vinheta orgânica de floresta
    aplicar_vinheta_suave(draw, w, h, cor_vinheta=(8, 22, 12), opacidade_max=115)

    out_file = DIR_OVERLAYS / "floresta_foreground.png"
    img.save(out_file, "PNG")
    print(f"[OK] Criado: {out_file}")


def criar_overlay_dungeon():
    w, h = 640, 360
    img = Image.new("RGBA", (w, h), C_TRANSPARENTE)
    draw = ImageDraw.Draw(img)

    # 1. Teto rochoso de estalactites no topo da tela
    for x in range(0, w, 2):
        comp = int(24 + (math.sin(x * 0.12) * 12 + ((x * 19) % 17)))
        for y in range(0, comp):
            cor = GRANITO_SOMBRA if y > comp - 6 else (22, 22, 26)
            alpha = int(250 * (1.0 - y / comp * 0.15))
            draw.rectangle([x, y, x + 1, y], fill=(*cor[:3], alpha))
        # Sombra projetada
        for sy in range(comp, comp + 20):
            s_alpha = int(110 * (1.0 - (sy - comp) / 20.0))
            draw.rectangle([x, sy, x + 1, sy], fill=(8, 8, 12, s_alpha))

    # 2. Paredes de rocha nas laterais em primeiro plano
    for y in range(0, h, 2):
        larg_esq = int(18 + math.sin(y * 0.05) * 8)
        draw.rectangle([0, y, larg_esq, y + 1], fill=(16, 18, 22, 220))
        larg_dir = int(18 + math.cos(y * 0.05) * 8)
        draw.rectangle([w - larg_dir, y, w, y + 1], fill=(16, 18, 22, 220))

    # 3. Névoa subterrânea translúcida e pontos de luz mineral azul
    for mx in range(60, w - 60, 4):
        for my in range(120, h - 30, 4):
            nevoa = (math.sin(mx * 0.02 + my * 0.03) + 1.0) * 0.5
            if nevoa > 0.6:
                alpha = int((nevoa - 0.6) * 35)
                draw.rectangle([mx, my, mx + 3, my + 3], fill=(80, 140, 180, alpha))

    # 4. Vinheta de escuridão profunda
    aplicar_vinheta_suave(draw, w, h, cor_vinheta=(6, 8, 12), opacidade_max=150)

    out_file = DIR_OVERLAYS / "dungeon_foreground.png"
    img.save(out_file, "PNG")
    print(f"[OK] Criado: {out_file}")


def criar_overlay_loja():
    w, h = 640, 360
    img = Image.new("RGBA", (w, h), C_TRANSPARENTE)
    draw = ImageDraw.Draw(img)

    # 1. Vigas de madeira maciça de teto correndo horizontalmente
    draw.rectangle([0, 0, w, 14], fill=MADEIRA_ESCURA)
    draw.rectangle([0, 12, w, 16], fill=(30, 18, 12, 255))
    draw.line([0, 14, w, 14], fill=MADEIRA_CLARA)
    # Sombra da viga do teto sobre o ambiente
    for y in range(16, 32):
        alpha = int(120 * (1.0 - (y - 16) / 16.0))
        draw.line([0, y, w, y], fill=(15, 10, 8, alpha))

    # Vigas transversais verticais sustentando o teto
    for vx in [120, 280, 440, 600]:
        draw.rectangle([vx - 6, 0, vx + 6, 26], fill=MADEIRA_ESCURA)
        draw.line([vx - 5, 0, vx - 5, 24], fill=MADEIRA_CLARA)

    # 2. Maços de ervas secas e frascos pendurados na viga do teto (passam por cima do jogador!)
    pendurados = [
        (80, "erva_verde"), (160, "frasco"), (220, "erva_roxa"),
        (360, "erva_amarela"), (400, "frasco"), (510, "erva_verde")
    ]
    for px, tipo in pendurados:
        # Fio de suspensão
        draw.line([px, 14, px, 24], fill=(80, 60, 40, 255))
        if tipo == "frasco":
            draw.rectangle([px - 2, 24, px + 2, 32], fill=(120, 230, 255, 190))
            draw.point((px - 1, 26), fill=(255, 255, 255, 240))
        else:
            cor_erva = VERDE_FOLHA if tipo == "erva_verde" else ((120, 60, 140, 255) if tipo == "erva_roxa" else (210, 180, 60, 255))
            draw.ellipse([px - 4, 23, px + 4, 34], fill=cor_erva)
            draw.ellipse([px - 2, 25, px + 2, 32], fill=VERDE_CLARO)

    # 3. Iluminação volumétrica acolhedora emanando do caldeirão (em torno de x=455, y=190)
    cx, cy = 455, 190
    for r in range(10, 90, 2):
        alpha = int(45 * (1.0 - r / 90.0)**1.5)
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(80, 240, 180, alpha))

    # 4. Vinheta aconchegante de interior de alquimia
    aplicar_vinheta_suave(draw, w, h, cor_vinheta=(18, 12, 10), opacidade_max=105)

    out_file = DIR_OVERLAYS / "loja_foreground.png"
    img.save(out_file, "PNG")
    print(f"[OK] Criado: {out_file}")


def criar_overlay_taverna():
    w, h = 640, 360
    img = Image.new("RGBA", (w, h), C_TRANSPARENTE)
    draw = ImageDraw.Draw(img)

    # Vigas de teto da taverna
    draw.rectangle([0, 0, w, 14], fill=MADEIRA_ESCURA)
    draw.line([0, 14, w, 14], fill=(30, 18, 12, 255))
    for y in range(15, 30):
        alpha = int(120 * (1.0 - (y - 15) / 15.0))
        draw.line([0, y, w, y], fill=(12, 8, 6, alpha))

    # Canecas e enchidos suspensos nas vigas
    for px in [110, 180, 320, 460, 530]:
        draw.line([px, 14, px, 22], fill=FERRO_ESCURO)
        draw.rectangle([px - 3, 22, px + 3, 30], fill=MADEIRA_CLARA)

    # Brilho de fogo e velas (quente âmbar)
    for cx, cy in [(220, 160), (385, 270)]:
        for r in range(10, 75, 2):
            alpha = int(35 * (1.0 - r / 75.0)**1.4)
            draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 170, 50, alpha))

    aplicar_vinheta_suave(draw, w, h, cor_vinheta=(18, 10, 8), opacidade_max=110)

    out_file = DIR_OVERLAYS / "taverna_foreground.png"
    img.save(out_file, "PNG")
    print(f"[OK] Criado: {out_file}")


# ==============================================================================
# EXECUÇÃO PRINCIPAL
# ==============================================================================
if __name__ == "__main__":
    print("=== Gerando Portais Temáticos de Alta Qualidade ===")
    criar_portal_loja()
    criar_portal_floresta()
    criar_portal_mina()
    criar_portal_taverna()
    criar_portal_tongobriga()
    criar_portais_retorno()
    criar_indicador_passagem()

    print("\n=== Gerando Camadas de Primeiro Plano e Profundidade 640x360 ===")
    criar_overlay_praca()
    criar_overlay_floresta()
    criar_overlay_dungeon()
    criar_overlay_loja()
    criar_overlay_taverna()

    print("\n=== [SUCESSO] Todos os novos assets foram gerados com perfeição! ===")
