#!/usr/bin/env python3
"""
Pipeline PhotoCraft para processamento técnico de todos os novos assets 16-bit Pixel Art:
1. Cenários (Floresta do Tâmega e Mina Antiga / Dungeon) sem grelhas nem xadrez.
2. Overlays atmosféricos limpos (sem barras retangulares de Paint no topo).
3. Personagens da Taverna (Taberneiro Afonso, Bardo, Freguês e Aventureiros).
4. Retratos/Sprites de Aventureiros (Guerreiro, Arqueiro, Mago, Curandeiro) limpos.
5. Props da Loja e Taverna (Prateleira do Fornecedor, Caneca, Vinho Verde, Ensopado, Moedas, Balcão).
6. Monstros da Dungeon (Goblin, Lobo das Cavernas, Saqueador, Morcego Sombrio, Guardião Antigo, Sentinela).
"""

import shutil
from collections import deque
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
BRAIN_DIR = Path(r"C:\Users\Icaro\.gemini\antigravity\brain\d230022c-e2cb-4685-b15f-9b28e390df89")

RAW_TAVERNA = BRAIN_DIR / "taverna_personagens_raw_1792408577386.jpg"
RAW_FLORESTA = BRAIN_DIR / "floresta_tamega_raw_1792408566600.jpg"
RAW_MINA = BRAIN_DIR / "mina_antiga_raw_1792408573365.jpg"
RAW_MONSTROS = BRAIN_DIR / "inimigos_dungeon_raw_notext_1792408586847.jpg"


def remover_fundo_branco_floodfill(img: Image.Image, limiar: int = 236) -> Image.Image:
    """Remove o fundo branco conectado às bordas preservando brancos internos (avental, espuma, olhos)."""
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size

    visitado = [[False] * w for _ in range(h)]
    fila = deque()

    def eh_fundo(r: int, g: int, b: int, a: int) -> bool:
        if a == 0:
            return True
        if r >= limiar and g >= limiar and b >= limiar:
            return True
        brightness = (r + g + b) / 3.0
        sat = max(r, g, b) - min(r, g, b)
        return brightness >= 230 and sat <= 18

    for x in range(w):
        for y in (0, h - 1):
            r, g, b, a = px[x, y]
            if eh_fundo(r, g, b, a):
                visitado[y][x] = True
                fila.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if not visitado[y][x]:
                r, g, b, a = px[x, y]
                if eh_fundo(r, g, b, a):
                    visitado[y][x] = True
                    fila.append((x, y))

    dirs = [(-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (1, -1), (-1, 1), (1, 1)]
    while fila:
        cx, cy = fila.popleft()
        px[cx, cy] = (0, 0, 0, 0)
        for dx, dy in dirs:
            nx, ny = cx + dx, cy + dy
            if 0 <= nx < w and 0 <= ny < h and not visitado[ny][nx]:
                r, g, b, a = px[nx, ny]
                if eh_fundo(r, g, b, a):
                    visitado[ny][nx] = True
                    fila.append((nx, ny))

    # Descontaminação de halo branco nas bordas
    copia = rgba.copy()
    cpx = copia.load()
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            r, g, b, a = cpx[x, y]
            if a == 0:
                continue
            viz_transp = 0
            for dx, dy in dirs:
                if cpx[x + dx, y + dy][3] == 0:
                    viz_transp += 1
            if viz_transp > 0:
                brightness = (r + g + b) / 3.0
                sat = max(r, g, b) - min(r, g, b)
                if brightness > 218 and sat < 24:
                    px[x, y] = (0, 0, 0, 0)
                elif brightness > 195 and sat < 28:
                    novo_a = int(a * 0.45)
                    px[x, y] = (int(r * 0.8), int(g * 0.8), int(b * 0.8), novo_a)

    return rgba


def obter_bbox_alfa(img: Image.Image) -> tuple[int, int, int, int] | None:
    w, h = img.size
    px = img.load()
    min_x, min_y, max_x, max_y = w, h, -1, -1
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > 20:
                if x < min_x:
                    min_x = x
                if x > max_x:
                    max_x = x
                if y < min_y:
                    min_y = y
                if y > max_y:
                    max_y = y
    if max_x < min_x:
        return None
    return (min_x, min_y, max_x + 1, max_y + 1)


def centralizar_em_canvas(
    recorte: Image.Image,
    largura_canvas: int,
    altura_canvas: int,
    margem_base: int = 8,
) -> Image.Image:
    bbox = obter_bbox_alfa(recorte)
    if bbox is None:
        return Image.new("RGBA", (largura_canvas, altura_canvas), (0, 0, 0, 0))
    justo = recorte.crop(bbox)
    bw, bh = justo.size
    max_w = largura_canvas - 8
    max_h = altura_canvas - margem_base - 6
    escala = min(max_w / float(bw), max_h / float(bh))
    nw = max(1, int(round(bw * escala)))
    nh = max(1, int(round(bh * escala)))
    redim = justo.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (largura_canvas, altura_canvas), (0, 0, 0, 0))
    pos_x = (largura_canvas - nw) // 2
    pos_y = altura_canvas - margem_base - nh
    canvas.alpha_composite(redim, (pos_x, pos_y))
    return canvas


def processar_cenarios_e_overlays() -> None:
    raw_dir = ROOT / "Assets" / "Source" / "raw"
    raw_dir.mkdir(parents=True, exist_ok=True)
    bg_dir = ROOT / "Assets" / "Environment" / "backgrounds"
    ov_dir = ROOT / "Assets" / "Environment" / "overlays"

    if RAW_FLORESTA.exists():
        img_floresta = Image.open(RAW_FLORESTA).convert("RGB")
        img_floresta.save(raw_dir / "floresta_tamega_raw.png", "PNG")
        img_floresta_640 = img_floresta.resize((640, 360), Image.Resampling.LANCZOS)
        img_floresta_640.save(bg_dir / "floresta_cenario.png", "PNG")
        print("Cenário Floresta do Tâmega atualizado (640x360).")

    if RAW_MINA.exists():
        img_mina = Image.open(RAW_MINA).convert("RGB")
        img_mina.save(raw_dir / "mina_antiga_raw.png", "PNG")
        img_mina_640 = img_mina.resize((640, 360), Image.Resampling.LANCZOS)
        img_mina_640.save(bg_dir / "dungeon_cenario.png", "PNG")
        print("Cenário Mina Antiga / Dungeon atualizado (640x360).")

    # Criar overlays limpos (sem retângulos de Paint no topo)
    configs_overlay = {
        "taverna_foreground.png": (18, 10, 6, 65),
        "loja_foreground.png": (16, 10, 8, 55),
        "floresta_foreground.png": (8, 18, 10, 45),
        "dungeon_foreground.png": (6, 8, 14, 95),
    }
    for nome_arq, (cr, cg, cb, max_alpha) in configs_overlay.items():
        ov = Image.new("RGBA", (640, 360), (0, 0, 0, 0))
        px = ov.load()
        cx, cy = 320.0, 180.0
        for y in range(360):
            for x in range(640):
                dx = (x - cx) / 320.0
                dy = (y - cy) / 180.0
                dist = (dx * dx + dy * dy) ** 0.5
                if dist > 0.78:
                    fator = min(1.0, (dist - 0.78) / 0.65)
                    a = int(max_alpha * (fator ** 1.5))
                    px[x, y] = (cr, cg, cb, a)
        ov.save(ov_dir / nome_arq, "PNG")
    print("Overlays de atmosfera limpos (Taverna, Loja, Floresta, Dungeon).")


def limpar_balcao_loja() -> None:
    caminho_balcao = ROOT / "Assets" / "Environment" / "props" / "balcao.png"
    if not caminho_balcao.exists():
        return
    img = Image.open(caminho_balcao).convert("RGBA")
    w, h = img.size
    # Se ainda tiver os objetos soltos à direita (w > 370), recorta apenas o balcão completo
    if w > 370:
        balcao_limpo = img.crop((0, 0, 356, h))
        bbox = obter_bbox_alfa(balcao_limpo)
        if bbox:
            balcao_limpo = balcao_limpo.crop(bbox)
        balcao_limpo.save(caminho_balcao, "PNG")
        print(f"Balcão da loja limpo: {balcao_limpo.size}")


def processar_taverna_aventureiros_props() -> None:
    if not RAW_TAVERNA.exists():
        print("Aviso: RAW_TAVERNA não encontrado.")
        return

    raw_dir = ROOT / "Assets" / "Source" / "raw"
    img = Image.open(RAW_TAVERNA).convert("RGBA")
    img.save(raw_dir / "taverna_personagens_raw.png", "PNG")
    w, h = img.size
    cw = w / 4.0
    ch = h / 3.0

    def extrair_celula(linha: int, col: int, pad: int = 8) -> Image.Image:
        x0 = max(0, int(round(col * cw)) + pad)
        y0 = max(0, int(round(linha * ch)) + pad)
        x1 = min(w, int(round((col + 1) * cw)) - pad)
        y1 = min(h, int(round((linha + 1) * ch)) - pad)
        sub = img.crop((x0, y0, x1, y1))
        return remover_fundo_branco_floodfill(sub)

    # 1. Personagens da Taverna e Aventureiros
    tab1 = centralizar_em_canvas(extrair_celula(0, 0), 128, 144, margem_base=8)
    tab2 = centralizar_em_canvas(extrair_celula(0, 1), 128, 144, margem_base=8)
    bardo = centralizar_em_canvas(extrair_celula(0, 2), 128, 144, margem_base=8)
    fregues = centralizar_em_canvas(extrair_celula(0, 3), 128, 144, margem_base=8)

    guerreiro = centralizar_em_canvas(extrair_celula(1, 0), 128, 144, margem_base=8)
    arqueiro = centralizar_em_canvas(extrair_celula(1, 1), 128, 144, margem_base=8)
    mago = centralizar_em_canvas(extrair_celula(1, 2), 128, 144, margem_base=8)
    curandeiro = centralizar_em_canvas(extrair_celula(1, 3), 128, 144, margem_base=8)

    # Salvar Aventureiros em Assets/Characters/Adventurers/
    adv_dir = ROOT / "Assets" / "Characters" / "Adventurers"
    adv_dir.mkdir(parents=True, exist_ok=True)
    guerreiro.save(adv_dir / "guerreiro.png", "PNG")
    arqueiro.save(adv_dir / "arqueiro.png", "PNG")
    mago.save(adv_dir / "mago.png", "PNG")
    curandeiro.save(adv_dir / "curandeiro.png", "PNG")
    print("Sprites de Aventureiros atualizados em Assets/Characters/Adventurers/.")

    # Salvar Taberneiro e Mercenários da Taverna em Assets/Characters/Taverna/
    tav_dir = ROOT / "Assets" / "Characters" / "Taverna"
    tav_dir.mkdir(parents=True, exist_ok=True)
    sheet_tab = Image.new("RGBA", (256, 144), (0, 0, 0, 0))
    sheet_tab.alpha_composite(tab1, (0, 0))
    sheet_tab.alpha_composite(tab2, (128, 0))
    sheet_tab.save(tav_dir / "taberneiro_sheet.png", "PNG")

    # mercenarios_sentados.png: 8 células de 128x144 (1024x144)
    # 0: Taberneiro 1, 1: Arqueira (Inês), 2: Mago (Baltasar), 3: Guerreiro (Rodrigo),
    # 4: Bardo (Martim), 5: Curandeira (Beatriz), 6: Freguês (Vasco), 7: Taberneiro 2
    poses_taverna = [tab1, arqueiro, mago, guerreiro, bardo, curandeiro, fregues, tab2]
    sheet_merc = Image.new("RGBA", (128 * len(poses_taverna), 144), (0, 0, 0, 0))
    for idx, sprite_p in enumerate(poses_taverna):
        sheet_merc.alpha_composite(sprite_p, (idx * 128, 0))
    sheet_merc.save(tav_dir / "mercenarios_sentados.png", "PNG")
    print("Sprites da Taverna atualizados em Assets/Characters/Taverna/.")

    # 2. Props da Loja e Taverna (Linha 2)
    props_dir = ROOT / "Assets" / "Environment" / "props"
    items_dir = ROOT / "Assets" / "Environment" / "items"

    # Fornecedor (Linha 2, Col 0)
    fornecedor_raw = extrair_celula(2, 0)
    fornecedor_prop = centralizar_em_canvas(fornecedor_raw, 128, 112, margem_base=4)
    fornecedor_prop.save(props_dir / "fornecedor_pixel.png", "PNG")

    # Caneca de Cerveja (Linha 2, Col 1)
    caneca_raw = extrair_celula(2, 1)
    caneca_prop = centralizar_em_canvas(caneca_raw, 32, 36, margem_base=2)
    caneca_prop.save(props_dir / "caneca_cerveja.png", "PNG")

    # Garrafa de Vinho Verde (Linha 2, Col 2)
    vinho_raw = extrair_celula(2, 2)
    vinho_prop = centralizar_em_canvas(vinho_raw, 36, 44, margem_base=2)
    vinho_prop.save(props_dir / "garrafa_vinho_verde.png", "PNG")

    # Prato de Ensopado & Moedas de Ouro (Linha 2, Col 3)
    celula_3 = extrair_celula(2, 3)
    c3w, c3h = celula_3.size
    # Parte esquerda/central (x < 72%): ensopado + pão
    ensopado_crop = celula_3.crop((0, 0, int(c3w * 0.72), c3h))
    ensopado_prop = centralizar_em_canvas(ensopado_crop, 44, 36, margem_base=2)
    ensopado_prop.save(props_dir / "prato_ensopado.png", "PNG")

    # Parte direita (x >= 68%): saco e pilha de moedas de ouro
    moedas_crop = celula_3.crop((int(c3w * 0.68), int(c3h * 0.25), c3w, c3h))
    moeda_prop = centralizar_em_canvas(moedas_crop, 48, 48, margem_base=2)
    moeda_prop.save(items_dir / "moeda_pixel.png", "PNG")
    print("Props da Loja e Taverna (fornecedor, caneca, vinho, ensopado, moedas) atualizados.")


def processar_monstros_dungeon() -> None:
    if not RAW_MONSTROS.exists():
        print("Aviso: RAW_MONSTROS não encontrado.")
        return

    raw_dir = ROOT / "Assets" / "Source" / "raw"
    img = Image.open(RAW_MONSTROS).convert("RGBA")
    img.save(raw_dir / "inimigos_dungeon_raw.png", "PNG")
    w, h = img.size
    cw = w / 3.0
    ch = h / 2.0

    monstros_dir = ROOT / "Assets" / "Characters" / "Monsters"
    monstros_dir.mkdir(parents=True, exist_ok=True)

    mapa_monstros = [
        (0, 0, "goblin.png"),
        (0, 1, "lobo.png"),
        (0, 2, "saqueador.png"),
        (1, 0, "morcego.png"),
        (1, 1, "guardiao.png"),
        (1, 2, "sentinela.png"),
    ]
    for linha, col, nome_arq in mapa_monstros:
        x0 = max(0, int(round(col * cw)) + 8)
        y0 = max(0, int(round(linha * ch)) + 8)
        x1 = min(w, int(round((col + 1) * cw)) - 8)
        y1 = min(h, int(round((linha + 1) * ch)) - 8)
        sub = img.crop((x0, y0, x1, y1))
        limpo = remover_fundo_branco_floodfill(sub)
        canvas = centralizar_em_canvas(limpo, 140, 140, margem_base=6)
        canvas.save(monstros_dir / nome_arq, "PNG")
    print("6 Monstros da Dungeon extraídos e salvos em Assets/Characters/Monsters/.")


def main() -> None:
    processar_cenarios_e_overlays()
    limpar_balcao_loja()
    processar_taverna_aventureiros_props()
    processar_monstros_dungeon()


if __name__ == "__main__":
    main()

