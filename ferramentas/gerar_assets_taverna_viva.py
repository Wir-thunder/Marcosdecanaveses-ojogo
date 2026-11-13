"""
Gerador de Assets para a Taverna Viva: Adereços de Mesa e Personagens
Projeto: A Loja do Alquimista - Marcos de Canaveses
Gera:
1. caneca_cerveja.png (16x16) - Caneca de madeira com espuma cremosa
2. garrafa_vinho_verde.png (16x20) - Garrafa verde tradicional de Marco de Canaveses
3. prato_ensopado.png (20x16) - Prato de barro com cozido fumegante
4. taberneiro_idle.png (64x32) - Spritesheet do taberneiro atendendo e limpando caneca
5. mercenarios_sentados.png (96x32) - Sprites de mercenários sentados brindando
"""

from pathlib import Path
from PIL import Image, ImageDraw

DIR_RAIZ = Path(__file__).resolve().parent.parent
DIR_PROPS = DIR_RAIZ / "Assets" / "Environment" / "props"
DIR_CHARS = DIR_RAIZ / "Assets" / "Characters" / "Taverna"

DIR_PROPS.mkdir(parents=True, exist_ok=True)
DIR_CHARS.mkdir(parents=True, exist_ok=True)

C_TRANSP = (0, 0, 0, 0)

# Paletas de cores
MADEIRA_ESCURA = (48, 28, 16, 255)
MADEIRA_MEDIA  = (85, 52, 28, 255)
MADEIRA_CLARA  = (130, 85, 45, 255)
CERVEJA_OURO   = (235, 175, 40, 255)
ESPUMA_BRANCA  = (250, 248, 235, 255)
FERRO_ESCURO   = (30, 32, 35, 255)

VINHO_VERDE_GARRAFA = (25, 75, 45, 255)
VINHO_VERDE_VIDRO   = (45, 125, 75, 255)
ROLHA_CORTICA       = (185, 140, 95, 255)

BARRO_PRATO    = (150, 75, 45, 255)
BARRO_SOMBREADO= (105, 50, 30, 255)
ENSOPADO_CALDO = (165, 80, 25, 255)
CARNE_PEDACO   = (95, 40, 20, 255)
LEGUME_VERDE   = (65, 125, 50, 255)


def gerar_caneca():
    img = Image.new("RGBA", (16, 16), C_TRANSP)
    draw = ImageDraw.Draw(img)
    # Sombra
    draw.ellipse([3, 12, 13, 15], fill=(15, 10, 8, 110))
    # Corpo da caneca de madeira com aros de ferro
    draw.rectangle([4, 6, 11, 13], fill=MADEIRA_MEDIA)
    draw.line([4, 7, 11, 7], fill=FERRO_ESCURO)
    draw.line([4, 12, 11, 12], fill=FERRO_ESCURO)
    draw.line([4, 9, 4, 11], fill=MADEIRA_CLARA)
    # Asa da caneca
    draw.line([12, 7, 13, 8], fill=FERRO_ESCURO)
    draw.line([13, 9, 13, 10], fill=FERRO_ESCURO)
    draw.line([12, 11, 13, 10], fill=FERRO_ESCURO)
    # Espuma de cerveja
    draw.ellipse([4, 3, 11, 6], fill=ESPUMA_BRANCA)
    draw.point((4, 7), fill=ESPUMA_BRANCA)  # Gota escorrendo
    draw.point((10, 4), fill=(255, 255, 255, 255))
    
    out = DIR_PROPS / "caneca_cerveja.png"
    img.save(out, "PNG")
    print(f"[OK] Gerado: {out}")


def gerar_garrafa():
    img = Image.new("RGBA", (16, 20), C_TRANSP)
    draw = ImageDraw.Draw(img)
    # Sombra
    draw.ellipse([4, 16, 12, 19], fill=(15, 10, 8, 110))
    # Corpo da garrafa
    draw.rectangle([5, 8, 11, 17], fill=VINHO_VERDE_GARRAFA)
    draw.line([6, 9, 6, 16], fill=VINHO_VERDE_VIDRO)
    # Rótulo tradicional branco
    draw.rectangle([6, 11, 10, 14], fill=(240, 238, 220, 255))
    draw.line([7, 12, 9, 12], fill=(160, 40, 40, 255))
    # Gargalo
    draw.rectangle([7, 4, 9, 7], fill=VINHO_VERDE_GARRAFA)
    # Rolha
    draw.rectangle([7, 2, 9, 3], fill=ROLHA_CORTICA)
    
    out = DIR_PROPS / "garrafa_vinho_verde.png"
    img.save(out, "PNG")
    print(f"[OK] Gerado: {out}")


def gerar_ensopado():
    img = Image.new("RGBA", (20, 16), C_TRANSP)
    draw = ImageDraw.Draw(img)
    # Sombra
    draw.ellipse([2, 11, 18, 15], fill=(15, 10, 8, 110))
    # Tigela de barro
    draw.ellipse([2, 4, 18, 13], fill=BARRO_SOMBREADO)
    draw.ellipse([3, 5, 17, 12], fill=BARRO_PRATO)
    # Cozido / Caldo fumegante
    draw.ellipse([5, 6, 15, 11], fill=ENSOPADO_CALDO)
    draw.rectangle([7, 7, 9, 8], fill=CARNE_PEDACO)
    draw.rectangle([11, 8, 12, 9], fill=LEGUME_VERDE)
    draw.point((8, 7), fill=(210, 120, 40, 255))

    out = DIR_PROPS / "prato_ensopado.png"
    img.save(out, "PNG")
    print(f"[OK] Gerado: {out}")


def gerar_taberneiro():
    """Spritesheet do Taberneiro: 4 frames de 32x38 px (128x38 px)"""
    w, h = 32, 38
    num_frames = 4
    img = Image.new("RGBA", (w * num_frames, h), C_TRANSP)
    draw = ImageDraw.Draw(img)

    pele = (235, 180, 140, 255)
    avental = (245, 240, 225, 255)
    camisa = (160, 50, 40, 255)
    cabelo = (75, 45, 30, 255)
    calca = (45, 40, 38, 255)

    for i in range(num_frames):
        ox = i * w
        bob = 1 if i % 2 == 1 else 0
        cx = ox + 16

        # Sombra
        draw.ellipse([cx - 8, h - 5, cx + 8, h - 1], fill=(15, 10, 8, 120))
        # Pernas
        draw.rectangle([cx - 5, h - 10, cx - 2, h - 3], fill=calca)
        draw.rectangle([cx + 1, h - 10, cx + 4, h - 3], fill=calca)
        # Tronco e Avental
        draw.rectangle([cx - 7, 16 + bob, cx + 7, h - 9], fill=camisa)
        draw.rectangle([cx - 5, 20 + bob, cx + 5, h - 9], fill=avental)
        # Braço limpando caneca
        if i == 0 or i == 2:
            draw.rectangle([cx + 6, 21 + bob, cx + 9, 27 + bob], fill=camisa)
            draw.rectangle([cx + 8, 26 + bob, cx + 11, 31 + bob], fill=pele)
            draw.rectangle([cx + 9, 27 + bob, cx + 13, 33 + bob], fill=MADEIRA_CLARA)
        else:
            draw.rectangle([cx + 5, 20 + bob, cx + 8, 26 + bob], fill=camisa)
            draw.rectangle([cx + 7, 24 + bob, cx + 10, 29 + bob], fill=pele)
            draw.rectangle([cx + 8, 25 + bob, cx + 12, 31 + bob], fill=MADEIRA_CLARA)

        # Cabeça
        draw.ellipse([cx - 6, 5 + bob, cx + 6, 17 + bob], fill=pele)
        # Bigode farto e cabelo
        draw.rectangle([cx - 7, 4 + bob, cx + 7, 8 + bob], fill=cabelo)
        draw.line([cx - 4, 14 + bob, cx + 4, 14 + bob], fill=cabelo, width=2)
        # Olhos
        draw.point((cx - 2, 10 + bob), fill=(25, 20, 15, 255))
        draw.point((cx + 2, 10 + bob), fill=(25, 20, 15, 255))

    out = DIR_CHARS / "taberneiro_sheet.png"
    img.save(out, "PNG")
    print(f"[OK] Gerado: {out}")


def gerar_mercenarios_sentados():
    """Gera mercenários em poses sentadas para colocar nas cadeiras das mesas (32x34 px por pose)"""
    w, h = 32, 34
    # Pose 1: Guerreiro com armadura e caneca
    # Pose 2: Arqueiro rindo
    # Pose 3: Mago encapuzado conversando
    img = Image.new("RGBA", (w * 3, h), C_TRANSP)
    draw = ImageDraw.Draw(img)

    # 1. Guerreiro
    ox = 0
    draw.ellipse([8, h - 5, 24, h - 1], fill=(15, 10, 8, 120))
    draw.rectangle([11, 14, 21, 28], fill=(110, 115, 120, 255)) # Cota de malha
    draw.rectangle([10, 18, 22, 24], fill=(160, 40, 30, 255))   # Túnica vermelha
    draw.ellipse([10, 4, 22, 15], fill=(225, 180, 140, 255))
    draw.rectangle([9, 3, 23, 7], fill=(120, 70, 40, 255))      # Cabelo castanho
    # Braço levantando caneca
    draw.rectangle([21, 15, 25, 22], fill=(110, 115, 120, 255))
    draw.rectangle([23, 13, 27, 18], fill=MADEIRA_CLARA)
    draw.point((25, 12), fill=ESPUMA_BRANCA)

    # 2. Arqueiro
    ox = 32
    draw.ellipse([ox + 8, h - 5, ox + 24, h - 1], fill=(15, 10, 8, 120))
    draw.rectangle([ox + 11, 14, ox + 21, 28], fill=(45, 95, 60, 255)) # Colete verde
    draw.ellipse([ox + 10, 4, ox + 22, 15], fill=(235, 190, 150, 255))
    draw.polygon([(ox + 9, 3), (ox + 23, 3), (ox + 21, 7), (ox + 11, 7)], fill=(80, 120, 50, 255)) # Gorro verde
    draw.point((ox + 14, 9), fill=(30, 20, 15, 255)) # Olho piscando
    draw.line([ox + 13, 12, ox + 17, 12], fill=(160, 40, 40, 255)) # Sorriso largo

    # 3. Mago
    ox = 64
    draw.ellipse([ox + 8, h - 5, ox + 24, h - 1], fill=(15, 10, 8, 120))
    draw.rectangle([ox + 9, 13, ox + 23, 29], fill=(60, 40, 95, 255)) # Manto roxo
    draw.polygon([(ox + 8, 13), (ox + 24, 13), (ox + 16, 2)], fill=(85, 55, 130, 255)) # Capuz pontiagudo
    draw.ellipse([ox + 12, 8, ox + 20, 15], fill=(220, 180, 140, 255))
    draw.line([ox + 12, 14, ox + 20, 17], fill=(230, 230, 230, 255), width=2) # Barba branca

    out = DIR_CHARS / "mercenarios_sentados.png"
    img.save(out, "PNG")
    print(f"[OK] Gerado: {out}")


if __name__ == "__main__":
    print("=== Gerando Adereços e NPCs da Taverna Viva ===")
    gerar_caneca()
    gerar_garrafa()
    gerar_ensopado()
    gerar_taberneiro()
    gerar_mercenarios_sentados()
    print("=== [SUCESSO] Todos os assets da Taverna foram criados! ===")

