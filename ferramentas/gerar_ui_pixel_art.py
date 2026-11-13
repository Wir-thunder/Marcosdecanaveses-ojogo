"""
Gerador de Assets de UI em Pixel Art:
1. quadro_missoes_madeira.png (Quadro de Avisos / Quests em Madeira Rústica com Ferragens)
2. moldura_hud_pixel.png (Moldura 9-slice em madeira de carvalho e frisos de latão)
3. botao_madeira_*.png (Botões de madeira entalhada em pixel art)
4. pergaminho_card.png (Cartão de pergaminho para contratos e avisos)
"""

from pathlib import Path
from PIL import Image, ImageDraw

DIR_RAIZ = Path(__file__).resolve().parent.parent
DIR_UI = DIR_RAIZ / "Assets" / "UI"
DIR_UI.mkdir(parents=True, exist_ok=True)

# Cores da Paleta Medieval / Pixel Art
C_TRANSP = (0, 0, 0, 0)

# Madeiras
MADEIRA_MUITO_ESCURA = (32, 20, 14, 255)
MADEIRA_ESCURA       = (52, 34, 22, 255)
MADEIRA_MEDIA        = (84, 56, 36, 255)
MADEIRA_CLARA        = (122, 82, 52, 255)
MADEIRA_DESTAQUE     = (158, 108, 70, 255)
MADEIRA_FUNDO        = (42, 28, 18, 255)

# Ferro e Bronze (Pregos, Cantoneiras)
FERRO_ESCURO = (24, 24, 26, 255)
FERRO_MEDIO  = (48, 50, 54, 255)
FERRO_CLARO  = (88, 92, 98, 255)
LATAO_OURO   = (198, 152, 58, 255)
LATAO_BRILHO = (240, 205, 110, 255)
LATAO_SOMBRA = (128, 92, 32, 255)

# Pergaminho / Papel Antigo
PERGAM_ESCURO = (165, 138, 95, 255)
PERGAM_MEDIO  = (212, 185, 138, 255)
PERGAM_CLARO  = (238, 218, 178, 255)
PERGAM_BORDA  = (135, 105, 68, 255)

def gerar_quadro_missoes():
    """Gera o quadro de avisos/quests estilizado em madeira nobre (520 x 330 px)"""
    w, h = 520, 330
    img = Image.new("RGBA", (w, h), C_TRANSP)
    draw = ImageDraw.Draw(img)

    # 1. Sombra externa suave do quadro
    draw.rectangle([4, 4, w - 1, h - 1], fill=(0, 0, 0, 110))

    # 2. Prancha de Fundo (Madeira de Carvalho com tábuas verticais)
    draw.rectangle([0, 0, w - 5, h - 5], fill=MADEIRA_FUNDO)
    
    # Desenho das tábuas verticais e ranhuras da madeira
    largura_tabua = 52
    for tx in range(0, w - 5, largura_tabua):
        # Linha de separação entre tábuas
        draw.line([tx, 0, tx, h - 5], fill=MADEIRA_MUITO_ESCURA, width=2)
        # Ranhuras de textura de madeira
        for y in range(8, h - 12, 14):
            offset_x = (y * 7) % 36
            draw.line([tx + 4 + offset_x, y, tx + 16 + offset_x, y], fill=MADEIRA_MEDIA)
            if y % 28 == 0:
                draw.line([tx + 2 + offset_x, y + 2, tx + 8 + offset_x, y + 2], fill=MADEIRA_ESCURA)

    # 3. Moldura Externa Robusta (Vigas de Madeira Chanfradas)
    borda = 14
    # Topo
    draw.rectangle([0, 0, w - 5, borda], fill=MADEIRA_ESCURA)
    draw.line([0, 0, w - 5, 0], fill=MADEIRA_DESTAQUE)
    draw.line([0, 1, w - 5, 1], fill=MADEIRA_CLARA)
    draw.line([0, borda, w - 5, borda], fill=MADEIRA_MUITO_ESCURA)

    # Base
    draw.rectangle([0, h - 5 - borda, w - 5, h - 5], fill=MADEIRA_ESCURA)
    draw.line([0, h - 5 - borda, w - 5, h - 5 - borda], fill=MADEIRA_MUITO_ESCURA)
    draw.line([0, h - 6, w - 5, h - 6], fill=MADEIRA_CLARA)

    # Lateral Esquerda
    draw.rectangle([0, 0, borda, h - 5], fill=MADEIRA_ESCURA)
    draw.line([0, 0, 0, h - 5], fill=MADEIRA_DESTAQUE)
    draw.line([1, 0, 1, h - 5], fill=MADEIRA_CLARA)
    draw.line([borda, 0, borda, h - 5], fill=MADEIRA_MUITO_ESCURA)

    # Lateral Direita
    draw.rectangle([w - 5 - borda, 0, w - 5, h - 5], fill=MADEIRA_ESCURA)
    draw.line([w - 5 - borda, 0, w - 5 - borda, h - 5], fill=MADEIRA_MUITO_ESCURA)
    draw.line([w - 6, 0, w - 6, h - 5], fill=MADEIRA_CLARA)

    # 4. Cantoneiras de Ferro Forjado e Rebites nos 4 cantos
    tam_canto = 30
    cantos = [
        (0, 0),
        (w - 5 - tam_canto, 0),
        (0, h - 5 - tam_canto),
        (w - 5 - tam_canto, h - 5 - tam_canto)
    ]
    for (cx, cy) in cantos:
        # Chapa metálica em L
        draw.rectangle([cx + 2, cy + 2, cx + tam_canto - 2, cy + tam_canto - 2], fill=FERRO_MEDIO)
        draw.line([cx + 2, cy + 2, cx + tam_canto - 2, cy + 2], fill=FERRO_CLARO)
        draw.line([cx + 2, cy + 2, cx + 2, cy + tam_canto - 2], fill=FERRO_CLARO)
        draw.line([cx + tam_canto - 2, cy + 2, cx + tam_canto - 2, cy + tam_canto - 2], fill=FERRO_ESCURO)
        draw.line([cx + 2, cy + tam_canto - 2, cx + tam_canto - 2, cy + tam_canto - 2], fill=FERRO_ESCURO)
        # Rebites dourados / latão nos cantos
        rebites = [(cx + 7, cy + 7), (cx + tam_canto - 8, cy + 7), (cx + 7, cy + tam_canto - 8), (cx + tam_canto - 8, cy + tam_canto - 8)]
        for (rx, ry) in rebites:
            draw.rectangle([rx - 2, ry - 2, rx + 2, ry + 2], fill=LATAO_SOMBRA)
            draw.rectangle([rx - 1, ry - 1, rx + 1, ry + 1], fill=LATAO_OURO)
            draw.point((rx, ry - 1), fill=LATAO_BRILHO)

    # 5. Placa de Título Superior em Madeira Esculpida (entalhe de tabuleta)
    px1, py1, px2, py2 = 120, 5, w - 125, 34
    draw.rectangle([px1 + 2, py1 + 2, px2 + 2, py2 + 2], fill=(0, 0, 0, 90)) # Sombra
    draw.rectangle([px1, py1, px2, py2], fill=MADEIRA_ESCURA)
    draw.rectangle([px1 + 2, py1 + 2, px2 - 2, py2 - 2], fill=MADEIRA_MEDIA)
    draw.line([px1, py1, px2, py1], fill=LATAO_OURO)
    draw.line([px1, py2, px2, py2], fill=LATAO_SOMBRA)
    draw.line([px1, py1, px1, py2], fill=LATAO_OURO)
    draw.line([px2, py1, px2, py2], fill=LATAO_SOMBRA)

    # 6. Painel Interno de Pergaminho Afixado (onde os contratos são lidos)
    ix1, iy1, ix2, iy2 = 24, 42, w - 29, h - 24
    # Fundo do pergaminho com tom envelhecido
    draw.rectangle([ix1, iy1, ix2, iy2], fill=(22, 16, 12, 235))
    draw.rectangle([ix1 + 4, iy1 + 4, ix2 - 4, iy2 - 4], fill=(32, 24, 18, 245))
    draw.line([ix1 + 4, iy1 + 4, ix2 - 4, iy1 + 4], fill=MADEIRA_CLARA)
    draw.line([ix1 + 4, iy2 - 4, ix2 - 4, iy2 - 4], fill=MADEIRA_MUITO_ESCURA)

    out = DIR_UI / "quadro_missoes_madeira.png"
    img.save(out, "PNG")
    print(f"[OK] Gerado: {out}")

def gerar_moldura_hud():
    """Gera moldura 9-slice para os painéis do HUD da loja (48 x 48 px)"""
    w, h = 48, 48
    img = Image.new("RGBA", (w, h), C_TRANSP)
    draw = ImageDraw.Draw(img)

    # Fundo central translúcido escuro
    draw.rectangle([6, 6, w - 7, h - 7], fill=(24, 18, 14, 235))

    # Borda externa chanfrada em madeira com detalhes de latão
    # Topo e Base
    draw.line([0, 0, w - 1, 0], fill=LATAO_BRILHO)
    draw.line([0, 1, w - 1, 1], fill=MADEIRA_CLARA)
    draw.line([0, 2, w - 1, 2], fill=MADEIRA_MEDIA)
    draw.line([0, 3, w - 1, 3], fill=MADEIRA_ESCURA)
    draw.line([0, 4, w - 1, 4], fill=MADEIRA_MUITO_ESCURA)

    draw.line([0, h - 5, w - 1, h - 5], fill=MADEIRA_MUITO_ESCURA)
    draw.line([0, h - 4, w - 1, h - 4], fill=MADEIRA_ESCURA)
    draw.line([0, h - 3, w - 1, h - 3], fill=MADEIRA_MEDIA)
    draw.line([0, h - 2, w - 1, h - 2], fill=MADEIRA_CLARA)
    draw.line([0, h - 1, w - 1, h - 1], fill=LATAO_SOMBRA)

    # Laterais
    draw.line([0, 0, 0, h - 1], fill=LATAO_BRILHO)
    draw.line([1, 0, 1, h - 1], fill=MADEIRA_CLARA)
    draw.line([2, 0, 2, h - 1], fill=MADEIRA_MEDIA)
    draw.line([3, 0, 3, h - 1], fill=MADEIRA_ESCURA)
    draw.line([4, 0, 4, h - 1], fill=MADEIRA_MUITO_ESCURA)

    draw.line([w - 5, 0, w - 5, h - 1], fill=MADEIRA_MUITO_ESCURA)
    draw.line([w - 4, 0, w - 4, h - 1], fill=MADEIRA_ESCURA)
    draw.line([w - 3, 0, w - 3, h - 1], fill=MADEIRA_MEDIA)
    draw.line([w - 2, 0, w - 2, h - 1], fill=MADEIRA_CLARA)
    draw.line([w - 1, 0, w - 1, h - 1], fill=LATAO_SOMBRA)

    # Cantos metálicos de latão (4x4)
    cantos = [(0, 0), (w - 4, 0), (0, h - 4), (w - 4, h - 4)]
    for (cx, cy) in cantos:
        draw.rectangle([cx, cy, cx + 3, cy + 3], fill=LATAO_OURO)
        draw.point((cx + 1, cy + 1), fill=LATAO_BRILHO)

    out = DIR_UI / "moldura_hud_pixel.png"
    img.save(out, "PNG")
    print(f"[OK] Gerado: {out}")

def gerar_botoes_madeira():
    """Gera três estados de botões entalhados em pixel art (64 x 24 px)"""
    w, h = 64, 24
    
    # 1. Normal
    img_n = Image.new("RGBA", (w, h), C_TRANSP)
    d_n = ImageDraw.Draw(img_n)
    d_n.rectangle([1, 1, w - 2, h - 2], fill=MADEIRA_MEDIA)
    # Chanfros de relevo
    d_n.line([1, 1, w - 2, 1], fill=MADEIRA_CLARA)
    d_n.line([1, 1, 1, h - 2], fill=MADEIRA_CLARA)
    d_n.line([1, h - 2, w - 2, h - 2], fill=MADEIRA_MUITO_ESCURA)
    d_n.line([w - 2, 1, w - 2, h - 2], fill=MADEIRA_MUITO_ESCURA)
    # Rebites de canto
    for (rx, ry) in [(3, 3), (w - 4, 3), (3, h - 4), (w - 4, h - 4)]:
        d_n.point((rx, ry), fill=LATAO_OURO)
    img_n.save(DIR_UI / "botao_madeira_normal.png", "PNG")

    # 2. Hover (iluminado em ouro)
    img_h = Image.new("RGBA", (w, h), C_TRANSP)
    d_h = ImageDraw.Draw(img_h)
    d_h.rectangle([1, 1, w - 2, h - 2], fill=MADEIRA_CLARA)
    d_h.line([1, 1, w - 2, 1], fill=LATAO_BRILHO)
    d_h.line([1, 1, 1, h - 2], fill=LATAO_BRILHO)
    d_h.line([1, h - 2, w - 2, h - 2], fill=MADEIRA_ESCURA)
    d_h.line([w - 2, 1, w - 2, h - 2], fill=MADEIRA_ESCURA)
    for (rx, ry) in [(3, 3), (w - 4, 3), (3, h - 4), (w - 4, h - 4)]:
        d_h.point((rx, ry), fill=LATAO_BRILHO)
    img_h.save(DIR_UI / "botao_madeira_hover.png", "PNG")

    # 3. Pressed (afundado com sombra)
    img_p = Image.new("RGBA", (w, h), C_TRANSP)
    d_p = ImageDraw.Draw(img_p)
    d_p.rectangle([1, 1, w - 2, h - 2], fill=MADEIRA_ESCURA)
    d_p.line([1, 1, w - 2, 1], fill=MADEIRA_MUITO_ESCURA)
    d_p.line([1, 1, 1, h - 2], fill=MADEIRA_MUITO_ESCURA)
    d_p.line([1, h - 2, w - 2, h - 2], fill=MADEIRA_MEDIA)
    d_p.line([w - 2, 1, w - 2, h - 2], fill=MADEIRA_MEDIA)
    for (rx, ry) in [(3, 3), (w - 4, 3), (3, h - 4), (w - 4, h - 4)]:
        d_p.point((rx, ry), fill=LATAO_SOMBRA)
    img_p.save(DIR_UI / "botao_madeira_pressed.png", "PNG")

    print("[OK] Botões de madeira gerados!")

def gerar_cartao_pergaminho():
    """Gera fundo de pergaminho para contratos e avisos (64 x 32 px)"""
    w, h = 64, 32
    img = Image.new("RGBA", (w, h), C_TRANSP)
    draw = ImageDraw.Draw(img)
    # Sombra
    draw.rectangle([2, 2, w - 1, h - 1], fill=(0, 0, 0, 60))
    # Fundo pergaminho
    draw.rectangle([0, 0, w - 3, h - 3], fill=PERGAM_MEDIO)
    draw.line([0, 0, w - 3, 0], fill=PERGAM_CLARO)
    draw.line([0, 0, 0, h - 3], fill=PERGAM_CLARO)
    draw.line([0, h - 3, w - 3, h - 3], fill=PERGAM_BORDA)
    draw.line([w - 3, 0, w - 3, h - 3], fill=PERGAM_BORDA)
    # Selo de cera ou pino nos cantos
    draw.point((3, 3), fill=(180, 50, 40, 255))
    draw.point((w - 6, 3), fill=(180, 50, 40, 255))
    img.save(DIR_UI / "pergaminho_card.png", "PNG")
    print("[OK] Cartão de pergaminho gerado!")

if __name__ == "__main__":
    gerar_quadro_missoes()
    gerar_moldura_hud()
    gerar_botoes_madeira()
    gerar_cartao_pergaminho()
    print("=== TODOS OS ASSETS DE UI EM PIXEL ART CRIADOS COM SUCESSO! ===")

