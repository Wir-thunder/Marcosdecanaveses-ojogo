"""
Gerador de Assets Animados de Fogo, Efeitos e Iluminação
Projeto: A Loja do Alquimista - Marcos de Canaveses
Gera spritesheets em Pixel Art para:
1. fogo_lareira.png (6 frames, 32x32) - Lareira da Taverna com chamas dançantes e brasas
2. fogo_caldeirao.png (6 frames, 32x18) - Fogo sob o caldeirão da Loja
3. caldeirao_borbulhas.png (4 frames, 28x12) - Superfície borbulhante da poção mágica
4. tocha_parede.png (6 frames, 16x24) - Arandela de ferro e chama bruxuleante
5. braseiro_arena.png (6 frames, 24x32) - Braseiro de pedra para Tongóbriga e Dungeon
6. luz_radial.png (128x128) - Textura de gradiente radial suave para PointLight2D
"""

import math
import random
from pathlib import Path
from PIL import Image, ImageDraw

DIR_RAIZ = Path(__file__).resolve().parent.parent
DIR_EFFECTS = DIR_RAIZ / "Assets" / "Effects"
DIR_EFFECTS.mkdir(parents=True, exist_ok=True)

# Paletas de Cor para Fogo e Brilho (Estilo Pixel Art Fantasia Quente)
C_TRANSP = (0, 0, 0, 0)

BRANCO_CALOR   = (255, 255, 230, 255)
AMARELO_VIVO   = (255, 230, 80, 255)
AMARELO_MEDIO  = (255, 190, 40, 255)
LARANJA_VIVO   = (255, 125, 20, 255)
LARANJA_ESCURO = (220, 75, 15, 255)
VERMELHO_FOGO  = (175, 35, 15, 255)
VERMELHO_BRASA = (110, 20, 10, 255)
CARVAO_ESCURO  = (40, 20, 18, 255)
CARVAO_CINZA   = (65, 45, 40, 255)
FERRO_ESCURO   = (32, 34, 38, 255)
FERRO_MEDIO    = (58, 62, 68, 255)
BRONZE_BASE    = (140, 95, 45, 255)
BRONZE_CLARO   = (190, 140, 70, 255)

# Paleta da Poção do Caldeirão (Esmeralda Alquímica)
POCAO_VERDE_CLARO   = (130, 255, 190, 255)
POCAO_VERDE_MEDIO   = (50, 200, 140, 255)
POCAO_VERDE_ESCURO  = (25, 120, 85, 255)
POCAO_VERDE_FUNDO   = (15, 65, 50, 255)
ESPUMA_BRILHO       = (220, 255, 240, 255)


def gerar_luz_radial():
    """Gera máscara de luz radial 128x128 suave com queda quadrática para PointLight2D."""
    size = 128
    img = Image.new("RGBA", (size, size), C_TRANSP)
    draw = ImageDraw.Draw(img)
    cx, cy = size / 2.0, size / 2.0
    raio_max = size / 2.0

    for y in range(size):
        for x in range(size):
            dist = math.hypot(x - cx, y - cy)
            if dist < raio_max:
                norm = dist / raio_max
                # Queda suave (smoothstep quadrático)
                alpha = int(255 * (1.0 - norm) * (1.0 - norm * 0.7))
                alpha = max(0, min(255, alpha))
                draw.point((x, y), fill=(255, 245, 220, alpha))

    caminho = DIR_EFFECTS / "luz_radial.png"
    img.save(caminho, "PNG")
    print(f"[OK] Gerado: {caminho}")


def gerar_fogo_lareira():
    """
    Spritesheet da Lareira: 6 frames de 32x32 (192x32).
    Lenha na base e labaredas volumosas que oscilam organicamente.
    """
    fw, fh = 32, 32
    num_frames = 6
    img = Image.new("RGBA", (fw * num_frames, fh), C_TRANSP)
    draw = ImageDraw.Draw(img)

    for i in range(num_frames):
        ox = i * fw

        # 1. Base de lenha e carvão incandescente (y: 26 a 31)
        # Tronco inclinado esquerdo
        draw.line([ox + 6, 29, ox + 14, 27], fill=CARVAO_ESCURO, width=2)
        # Tronco direito
        draw.line([ox + 18, 27, ox + 26, 29], fill=CARVAO_ESCURO, width=2)
        # Brasas sob os troncos
        for bx in range(ox + 8, ox + 25):
            c_brasa = VERMELHO_BRASA if (bx + i) % 2 == 0 else LARANJA_ESCURO
            draw.point((bx, 29), fill=c_brasa)
            if (bx + i) % 3 == 0:
                draw.point((bx, 30), fill=AMARELO_MEDIO)

        # 2. Labaredas principais simuladas por curvas senoidais com ruído orgânico
        fase = (i / float(num_frames)) * math.pi * 2.0

        # Posições dos bicos de chama principais
        alt_central = 14 + int(5.0 * math.sin(fase))
        alt_esq = 10 + int(4.0 * math.sin(fase + 2.1))
        alt_dir = 11 + int(4.0 * math.sin(fase + 4.2))

        # Desenho das massas de chama de fora para dentro (camadas de cor)
        # Camada Externa (Vermelho/Laranja Escuro)
        for y in range(8, 28):
            prog = (28 - y) / 20.0  # 0 na base, 1 no topo
            desv = math.sin(fase + y * 0.4) * 2.0
            largura = max(0, int((1.0 - prog * 0.8) * 9.0 + math.sin(y * 0.5 + fase) * 1.5))
            cx = ox + 16 + int(desv)
            for x in range(cx - largura, cx + largura + 1):
                if 0 <= (x - ox) < fw:
                    draw.point((x, y), fill=LARANJA_ESCURO)

        # Camada Média (Laranja Vivo / Amarelo)
        for y in range(12, 28):
            prog = (28 - y) / 16.0
            desv = math.sin(fase + y * 0.5) * 1.5
            largura = max(0, int((1.0 - prog * 0.9) * 6.5))
            cx = ox + 16 + int(desv)
            for x in range(cx - largura, cx + largura + 1):
                if 0 <= (x - ox) < fw:
                    cor = AMARELO_MEDIO if y > 18 else LARANJA_VIVO
                    draw.point((x, y), fill=cor)

        # Núcleo Incandescente (Amarelo Claro / Branco de calor)
        for y in range(18, 28):
            prog = (28 - y) / 10.0
            largura = max(0, int((1.0 - prog) * 3.5))
            cx = ox + 16 + int(math.sin(fase) * 0.8)
            for x in range(cx - largura, cx + largura + 1):
                if 0 <= (x - ox) < fw:
                    cor = BRANCO_CALOR if y >= 23 else AMARELO_VIVO
                    draw.point((x, y), fill=cor)

        # Faíscas e brasas voadoras flutuando
        sparks = [
            (ox + 16 + int(math.sin(fase * 1.5) * 6), 6 + (i * 3) % 12),
            (ox + 12 + int(math.cos(fase) * 4), 9 + ((i + 2) * 4) % 14),
            (ox + 20 + int(math.sin(fase + 1) * 5), 4 + ((i + 4) * 3) % 15)
        ]
        for sx, sy in sparks:
            if 0 <= (sx - ox) < fw and 0 <= sy < fh:
                draw.point((sx, sy), fill=AMARELO_MEDIO)
                draw.point((sx, sy + 1), fill=LARANJA_ESCURO)

    caminho = DIR_EFFECTS / "fogo_lareira.png"
    img.save(caminho, "PNG")
    print(f"[OK] Gerado: {caminho}")


def gerar_fogo_caldeirao():
    """
    Spritesheet para baixo do Caldeirão: 6 frames de 32x18 (192x18).
    Formato achatado para encaixar perfeitamente sob os pés e fundo curvo do caldeirão.
    """
    fw, fh = 32, 18
    num_frames = 6
    img = Image.new("RGBA", (fw * num_frames, fh), C_TRANSP)
    draw = ImageDraw.Draw(img)

    for i in range(num_frames):
        ox = i * fw
        fase = (i / float(num_frames)) * math.pi * 2.0

        # Pedras ou lenha de sustentação
        draw.rectangle([ox + 4, 14, ox + 9, 17], fill=CARVAO_CINZA)
        draw.rectangle([ox + 23, 14, ox + 28, 17], fill=CARVAO_CINZA)
        draw.line([ox + 7, 15, ox + 25, 15], fill=CARVAO_ESCURO, width=2)

        # Brasas intensas
        for x in range(ox + 8, ox + 24):
            c = AMARELO_MEDIO if (x + i) % 2 == 0 else LARANJA_VIVO
            draw.point((x, 15), fill=c)
            draw.point((x, 16), fill=VERMELHO_BRASA)

        # Chamas baixas que lambem para cima (y: 2 a 14)
        for y in range(4, 15):
            prog = (14 - y) / 10.0
            largura = max(0, int((1.0 - prog * 0.7) * 8.0))
            ondulacao = math.sin(fase + y * 0.8) * 1.5
            cx = ox + 16 + int(ondulacao)
            for x in range(cx - largura, cx + largura + 1):
                if 0 <= (x - ox) < fw:
                    cor = LARANJA_ESCURO if y < 7 else (LARANJA_VIVO if y < 11 else AMARELO_MEDIO)
                    draw.point((x, y), fill=cor)

        # Núcleo branco no centro
        for y in range(10, 15):
            prog = (14 - y) / 5.0
            largura = max(0, int((1.0 - prog) * 4.0))
            cx = ox + 16
            for x in range(cx - largura, cx + largura + 1):
                draw.point((x, y), fill=BRANCO_CALOR if y >= 12 else AMARELO_VIVO)

        # Brasinha subindo pelas laterais do caldeirão
        bx = ox + 16 + int(math.sin(fase * 2) * 9)
        by = 2 + (i * 2) % 6
        draw.point((bx, by), fill=AMARELO_MEDIO)

    caminho = DIR_EFFECTS / "fogo_caldeirao.png"
    img.save(caminho, "PNG")
    print(f"[OK] Gerado: {caminho}")


def gerar_caldeirao_borbulhas():
    """
    Spritesheet da Poção Borbulhante: 4 frames de 28x12 (112x12).
    Líquido mágico com anéis concêntricos que expandem e estouram em vapor.
    """
    fw, fh = 28, 12
    num_frames = 4
    img = Image.new("RGBA", (fw * num_frames, fh), C_TRANSP)
    draw = ImageDraw.Draw(img)

    for i in range(num_frames):
        ox = i * fw

        # Base oval do líquido dentro do caldeirão
        draw.ellipse([ox + 2, 2, ox + fw - 3, fh - 2], fill=POCAO_VERDE_FUNDO)
        draw.ellipse([ox + 4, 3, ox + fw - 5, fh - 3], fill=POCAO_VERDE_ESCURO)
        draw.ellipse([ox + 6, 4, ox + fw - 7, fh - 4], fill=POCAO_VERDE_MEDIO)

        # Bolhas que crescem e estouram em diferentes posições
        bolhas = [
            (ox + 8, 5, (i % 4)),              # Bolha 1 esquerda
            (ox + 15, 6, ((i + 2) % 4)),       # Bolha 2 central
            (ox + 21, 5, ((i + 1) % 4)),       # Bolha 3 direita
            (ox + 12, 7, ((i + 3) % 4))        # Bolha 4 inferior
        ]

        for bx, by, estagio in bolhas:
            if estagio == 0:
                # Ponto brilhante nascendo
                draw.point((bx, by), fill=POCAO_VERDE_CLARO)
            elif estagio == 1:
                # Bolha média
                draw.point((bx, by), fill=ESPUMA_BRILHO)
                draw.point((bx - 1, by), fill=POCAO_VERDE_CLARO)
                draw.point((bx + 1, by), fill=POCAO_VERDE_CLARO)
                draw.point((bx, by - 1), fill=POCAO_VERDE_CLARO)
            elif estagio == 2:
                # Bolha grande prestes a estourar
                draw.ellipse([bx - 2, by - 2, bx + 2, by + 1], outline=ESPUMA_BRILHO, fill=POCAO_VERDE_CLARO)
                draw.point((bx - 1, by - 1), fill=(255, 255, 255, 255))
            elif estagio == 3:
                # Bolha estourada (gotícula e anel)
                draw.point((bx - 2, by), fill=ESPUMA_BRILHO)
                draw.point((bx + 2, by), fill=ESPUMA_BRILHO)
                draw.point((bx, by - 2), fill=(240, 255, 250, 220))  # Respingo no ar

    caminho = DIR_EFFECTS / "caldeirao_borbulhas.png"
    img.save(caminho, "PNG")
    print(f"[OK] Gerado: {caminho}")


def gerar_tocha_parede():
    """
    Spritesheet da Tocha/Arandela: 6 frames de 16x24 (96x24).
    Suporte de ferro medieval fixo e chama superior bruxuleante.
    """
    fw, fh = 16, 24
    num_frames = 6
    img = Image.new("RGBA", (fw * num_frames, fh), C_TRANSP)
    draw = ImageDraw.Draw(img)

    for i in range(num_frames):
        ox = i * fw
        fase = (i / float(num_frames)) * math.pi * 2.0

        # 1. Suporte fixo de ferro na parede (y: 11 a 23)
        cx = ox + 8
        # Haste vertical e braço angulado
        draw.line([cx, 14, cx, 22], fill=FERRO_ESCURO, width=2)
        draw.line([cx - 3, 20, cx, 23], fill=FERRO_MEDIO)
        # Cesto da tocha
        draw.rectangle([cx - 3, 11, cx + 3, 13], fill=FERRO_ESCURO)
        draw.point((cx - 2, 11), fill=FERRO_MEDIO)
        draw.point((cx + 2, 11), fill=FERRO_MEDIO)
        # Pano embebido em óleo / brasa dentro do cesto
        draw.line([cx - 2, 11, cx + 2, 11], fill=VERMELHO_BRASA)

        # 2. Chama viva superior (y: 2 a 10)
        desv = math.sin(fase) * 1.5
        alt_topo = 3 + int(math.cos(fase * 1.5) * 1.5)

        # Camada externa de fogo
        for y in range(alt_topo, 11):
            prog = (11 - y) / float(11 - alt_topo + 1)
            largura = max(0, int((1.0 - prog * 0.7) * 3.2))
            flame_x = cx + int(desv * prog)
            for px in range(flame_x - largura, flame_x + largura + 1):
                cor = LARANJA_ESCURO if y <= alt_topo + 1 else LARANJA_VIVO
                draw.point((px, y), fill=cor)

        # Núcleo da tocha
        for y in range(alt_topo + 2, 11):
            prog = (11 - y) / float(11 - alt_topo - 1)
            largura = max(0, int((1.0 - prog) * 1.8))
            flame_x = cx + int(desv * prog * 0.5)
            for px in range(flame_x - largura, flame_x + largura + 1):
                cor = BRANCO_CALOR if y >= 8 else AMARELO_MEDIO
                draw.point((px, y), fill=cor)

        # Fagulha desprendida
        if i % 2 == 0:
            draw.point((cx + int(desv * 2), alt_topo - 1), fill=AMARELO_MEDIO)

    caminho = DIR_EFFECTS / "tocha_parede.png"
    img.save(caminho, "PNG")
    print(f"[OK] Gerado: {caminho}")


def gerar_braseiro_arena():
    """
    Spritesheet do Braseiro (Tongóbriga / Dungeon): 6 frames de 24x32 (144x32).
    Pedestal de pedra/bronze com taça flamejante.
    """
    fw, fh = 24, 32
    num_frames = 6
    img = Image.new("RGBA", (fw * num_frames, fh), C_TRANSP)
    draw = ImageDraw.Draw(img)

    for i in range(num_frames):
        ox = i * fw
        fase = (i / float(num_frames)) * math.pi * 2.0
        cx = ox + 12

        # 1. Pedestal e Taça de Bronze/Granito (y: 17 a 31)
        # Base de pedra
        draw.rectangle([cx - 7, 28, cx + 7, 31], fill=(50, 52, 54, 255))
        draw.line([cx - 6, 28, cx + 6, 28], fill=(90, 95, 98, 255))
        # Coluna central
        draw.rectangle([cx - 3, 22, cx + 3, 27], fill=BRONZE_BASE)
        draw.line([cx - 2, 22, cx - 2, 27], fill=BRONZE_CLARO)
        # Taça côncava
        draw.polygon([(cx - 8, 17), (cx + 8, 17), (cx + 4, 22), (cx - 4, 22)], fill=BRONZE_BASE)
        draw.line([cx - 8, 17, cx + 8, 17], fill=BRONZE_CLARO)
        # Brasas na taça
        draw.line([cx - 6, 17, cx + 6, 17], fill=VERMELHO_BRASA, width=2)
        draw.point((cx - 2, 17), fill=LARANJA_VIVO)
        draw.point((cx + 2, 17), fill=AMARELO_MEDIO)

        # 2. Chama crepitante (y: 4 a 16)
        alt_flame = 5 + int(math.sin(fase) * 2)
        desv = math.sin(fase * 1.3) * 1.8

        for y in range(alt_flame, 17):
            prog = (17 - y) / float(17 - alt_flame + 1)
            largura = max(0, int((1.0 - prog * 0.8) * 6.0))
            fx = cx + int(desv * prog)
            for px in range(fx - largura, fx + largura + 1):
                cor = LARANJA_ESCURO if y <= alt_flame + 2 else (LARANJA_VIVO if y < 13 else AMARELO_MEDIO)
                draw.point((px, y), fill=cor)

        # Núcleo quente
        for y in range(alt_flame + 4, 17):
            prog = (17 - y) / 10.0
            largura = max(0, int((1.0 - prog) * 2.8))
            for px in range(cx - largura, cx + largura + 1):
                draw.point((px, y), fill=BRANCO_CALOR if y >= 14 else AMARELO_VIVO)

        # Faísca
        draw.point((cx + int(desv * 2), alt_flame - 1), fill=AMARELO_MEDIO)

    caminho = DIR_EFFECTS / "braseiro_arena.png"
    img.save(caminho, "PNG")
    print(f"[OK] Gerado: {caminho}")


if __name__ == "__main__":
    print("=== Gerando Assets de Fogo, Efeitos e Iluminação ===")
    gerar_luz_radial()
    gerar_fogo_lareira()
    gerar_fogo_caldeirao()
    gerar_caldeirao_borbulhas()
    gerar_tocha_parede()
    gerar_braseiro_arena()
    print("=== [SUCESSO] Todos os efeitos visuais e chamas foram gerados! ===")

