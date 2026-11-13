"""
Pipeline Técnico PhotoCraft v2.0:
1. Processamento e normalização dos novos cenários (Vila Celta de Tongóbriga e Praça Central de Marco de Canaveses).
2. Extração de máscara alfa sem artefatos de xadrez (flood-fill + poda morfológica de ilhas) e
   divisão inteligente por vales verticais (valley-splitting) para os 4 Guerreiros de Tongóbriga:
   - warrior (Viriato - Guerreiro Lusitano)
   - archer  (Nábia - Caçadora Castreja)
   - mage    (Endovélico - Druida do Castro)
   - healer  (Aunia - Sacerdotisa da Pedra Formosa)
"""

import os
from pathlib import Path
from PIL import Image, ImageFilter
import numpy as np
from scipy import ndimage

DIR_RAIZ = Path(__file__).resolve().parent.parent
DIR_TONGOBRIGA = DIR_RAIZ / "Assets" / "Characters" / "Tongobriga"
DIR_BG = DIR_RAIZ / "Assets" / "Environment" / "backgrounds"
DIR_OVERLAYS = DIR_RAIZ / "Assets" / "Environment" / "overlays"
DIR_RAW = DIR_RAIZ / "Assets" / "Source" / "raw"

DIR_TONGOBRIGA.mkdir(parents=True, exist_ok=True)
DIR_BG.mkdir(parents=True, exist_ok=True)
DIR_OVERLAYS.mkdir(parents=True, exist_ok=True)
DIR_RAW.mkdir(parents=True, exist_ok=True)

SRC_GUERREIROS = DIR_RAW / "references" / "Guerreiros de tongobriga.jpeg"

CLASSES = [
    ("warrior", 210, 710),
    ("archer",  840, 1360),
    ("mage",    1470, 2050),
    ("healer",  2150, 2710)
]

ESTADOS = [
    ("idle",     145, 285),
    ("move",     305, 445),
    ("jump",     475, 618),
    ("punch",    628, 760),
    ("kick",     775, 910),
    ("special",  932, 1068),
    ("block",    1078, 1215),
    ("damage",   1232, 1368),
    ("defeated", 1400, 1505)
]

CANVAS_SIZE = (160, 140)


def extrair_mascara_photocraft(arr_rgb: np.ndarray) -> np.ndarray:
    """
    Remove 100% do fundo xadrez (incluindo as linhas de transição 130-142 do JPEG),
    preservando detalhes internos metálicos (espadas/escudos) por flood-fill exterior
    combinado com remoção de buracos neutros de fundo.
    """
    arr = arr_rgb.astype(np.int32)
    sat = arr.max(axis=2) - arr.min(axis=2)
    media = arr.mean(axis=2)

    # Qualquer pixel neutro na faixa do xadrez (100..176) com saturação baixa
    is_checker_tone = (sat <= 18) & (media >= 96) & (media <= 178)

    # Também captura linhas ligeiramente mais escuras/claras na borda do xadrez
    is_soft_checker = (sat <= 12) & (media >= 88) & (media <= 186)
    bg_candidate = is_checker_tone | is_soft_checker

    fg = ~bg_candidate

    # Remover ilhas minúsculas de ruído JPEG (< 65 pixels)
    labeled, num = ndimage.label(fg)
    if num > 0:
        sizes = ndimage.sum(fg, labeled, range(1, num + 1))
        valid_labels = np.where(sizes >= 65)[0] + 1
        fg = np.isin(labeled, valid_labels)

    # Preencher pequenos buracos internos no aço/escudo (< 40 pixels), mas manter vazados entre pernas/braços
    bg_holes = ~fg
    lbl_bg, num_bg = ndimage.label(bg_holes)
    if num_bg > 0:
        bg_sizes = ndimage.sum(bg_holes, lbl_bg, range(1, num_bg + 1))
        # Descobrir quais componentes tocam a borda da imagem
        border_labels = set(np.unique(lbl_bg[0, :])) | set(np.unique(lbl_bg[-1, :])) | \
                        set(np.unique(lbl_bg[:, 0])) | set(np.unique(lbl_bg[:, -1]))
        for lbl_idx in range(1, num_bg + 1):
            if lbl_idx not in border_labels and bg_sizes[lbl_idx - 1] < 28:
                fg[lbl_bg == lbl_idx] = True

    # Erosão de 1px apenas nos pixels da borda que ainda tenham baixíssima saturação (halo cinza do JPEG)
    eroded = ndimage.binary_erosion(fg, iterations=1)
    boundary = fg & (~eroded)
    halo_pixels = boundary & (sat <= 24) & (media >= 90) & (media <= 185)
    fg = fg & (~halo_pixels)

    alpha = (fg.astype(np.uint8)) * 255
    return np.dstack([arr_rgb, alpha])


def dividir_segmento_largo(alpha_crop: np.ndarray, x_start: int, x_end: int, target_parts: int):
    """
    Divide um segmento horizontal largo (onde 2 ou 3 frames quase se tocam)
    encontrando os vales mínimos de contagem vertical de pixels alfa.
    """
    width = x_end - x_start + 1
    if target_parts <= 1 or width < 160:
        return [(x_start, x_end)]

    col_sums = (alpha_crop[:, x_start:x_end + 1] > 10).sum(axis=0)
    splits = []
    step = width / target_parts
    for i in range(1, target_parts):
        center = int(i * step)
        search_min = max(40, center - 55)
        search_max = min(width - 40, center + 55)
        if search_min < search_max:
            local_valley = search_min + int(np.argmin(col_sums[search_min:search_max]))
            splits.append(x_start + local_valley)

    result = []
    prev = x_start
    for sp in splits:
        result.append((prev, sp - 1))
        prev = sp + 1
    result.append((prev, x_end))
    return result


def encontrar_regioes_frames(alpha_canal: np.ndarray):
    col_sums = (alpha_canal > 10).sum(axis=0)
    raw_regions = []
    in_reg = False
    start = 0
    gap = 0

    for x in range(len(col_sums)):
        if col_sums[x] > 2:
            if not in_reg:
                in_reg = True
                start = x
            gap = 0
        elif in_reg:
            gap += 1
            if gap >= 3:
                in_reg = False
                raw_regions.append((start, x - gap))
                gap = 0
    if in_reg:
        raw_regions.append((start, len(col_sums) - 1))

    raw_regions = [r for r in raw_regions if (r[1] - r[0]) >= 20]

    final_regions = []
    for rx0, rx1 in raw_regions:
        w = rx1 - rx0 + 1
        if w >= 295:
            final_regions.extend(dividir_segmento_largo(alpha_canal, rx0, rx1, 3))
        elif w >= 200:
            final_regions.extend(dividir_segmento_largo(alpha_canal, rx0, rx1, 2))
        else:
            final_regions.append((rx0, rx1))

    return [r for r in final_regions if (r[1] - r[0]) >= 20]


def processar_guerreiros():
    if not SRC_GUERREIROS.exists():
        print(f"[ERRO] Não encontrado: {SRC_GUERREIROS}")
        return

    img = Image.open(SRC_GUERREIROS).convert("RGB")
    total_frames = 0

    for cname, x0, x1 in CLASSES:
        dir_classe = DIR_TONGOBRIGA / cname
        dir_classe.mkdir(parents=True, exist_ok=True)
        # Limpar frames antigos
        for old_png in dir_classe.glob("*.png"):
            old_png.unlink()

        sheet_rows = []

        for ename, y0, y1 in ESTADOS:
            crop = img.crop((x0, y0, x1, y1))
            arr_rgb = np.array(crop)
            arr_rgba = extrair_mascara_photocraft(arr_rgb)
            alpha = arr_rgba[:, :, 3]

            regions = encontrar_regioes_frames(alpha)
            row_frames = []

            for f_idx, (rx0, rx1) in enumerate(regions[:4]):
                sprite_box = arr_rgba[:, rx0:rx1 + 1].copy()
                # Remover fragmentos desconectados menores nas bordas do recorte (< 110 px)
                sub_fg = sprite_box[:, :, 3] > 10
                lbl_s, num_s = ndimage.label(sub_fg)
                if num_s > 1:
                    s_sizes = ndimage.sum(sub_fg, lbl_s, range(1, num_s + 1))
                    main_lbl = int(np.argmax(s_sizes)) + 1
                    for sl in range(1, num_s + 1):
                        if sl != main_lbl and s_sizes[sl - 1] < 110:
                            # Se toca a borda esquerda ou direita do recorte, é resquício do frame vizinho
                            comp_mask = (lbl_s == sl)
                            if comp_mask[:, 0].any() or comp_mask[:, -1].any() or s_sizes[sl - 1] < 80:
                                sprite_box[comp_mask, 3] = 0

                # Recortar novamente horizontal e verticalmente após limpar fragmentos de borda
                col_s = (sprite_box[:, :, 3] > 10).sum(axis=0)
                active_cols = np.where(col_s > 1)[0]
                row_sums = (sprite_box[:, :, 3] > 10).sum(axis=1)
                active_rows = np.where(row_sums > 1)[0]
                if len(active_rows) == 0 or len(active_cols) == 0:
                    continue
                top_y, bot_y = active_rows.min(), active_rows.max()
                left_x, right_x = active_cols.min(), active_cols.max()
                sprite_tight = sprite_box[top_y:bot_y + 1, left_x:right_x + 1]
                h, w = sprite_tight.shape[:2]

                sprite_img = Image.fromarray(sprite_tight, mode="RGBA")
                max_w, max_h = CANVAS_SIZE[0] - 12, CANVAS_SIZE[1] - 12
                if w > max_w or h > max_h:
                    ratio = min(max_w / w, max_h / h)
                    nw, nh = max(1, int(w * ratio)), max(1, int(h * ratio))
                    sprite_img = sprite_img.resize((nw, nh), Image.Resampling.LANCZOS)
                    w, h = nw, nh

                canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
                paste_x = (CANVAS_SIZE[0] - w) // 2
                paste_y = CANVAS_SIZE[1] - h - 6
                canvas.paste(sprite_img, (paste_x, paste_y), sprite_img)

                out_path = dir_classe / f"{ename}_{f_idx + 1}.png"
                canvas.save(out_path, "PNG")
                row_frames.append(canvas)
                total_frames += 1

            if row_frames:
                sheet_rows.append(row_frames)

        # Criar portrait.png (rosto/busto a partir do idle_1)
        idle1_path = dir_classe / "idle_1.png"
        if idle1_path.exists():
            idle_img = Image.open(idle1_path)
            bbox = idle_img.getbbox()
            if bbox:
                char_crop = idle_img.crop(bbox)
                cw, ch = char_crop.size
                # Busto superior (65% superior)
                bust = char_crop.crop((0, 0, cw, max(cw, int(ch * 0.72))))
                bust.thumbnail((64, 64), Image.Resampling.LANCZOS)
                portrait = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
                px = (64 - bust.width) // 2
                py = (64 - bust.height) // 2
                portrait.paste(bust, (px, py), bust)
                portrait.save(dir_classe / "portrait.png", "PNG")

        # Criar spritesheet consolidado da classe
        if sheet_rows:
            max_cols = max(len(r) for r in sheet_rows)
            sheet_img = Image.new(
                "RGBA",
                (max_cols * CANVAS_SIZE[0], len(sheet_rows) * CANVAS_SIZE[1]),
                (0, 0, 0, 0)
            )
            for r_i, r_list in enumerate(sheet_rows):
                for c_i, frm in enumerate(r_list):
                    sheet_img.paste(frm, (c_i * CANVAS_SIZE[0], r_i * CANVAS_SIZE[1]), frm)
            sheet_img.save(dir_classe / "spritesheet.png", "PNG")

        print(f"[OK] {cname}: processado sem artefatos em {dir_classe}")

    print(f"Total de frames limpos gerados: {total_frames}")


def processar_cenarios(tongobriga_src: Path, praca_src: Path):
    if tongobriga_src.exists():
        img_t = Image.open(tongobriga_src).convert("RGBA")
        img_t.save(DIR_RAW / "tongobriga_celta_raw.png", "PNG")
        # Redimensionar para 640x360 com nitidez
        bg_t = img_t.resize((640, 360), Image.Resampling.LANCZOS)
        bg_t.save(DIR_BG / "tongobriga_cenario.png", "PNG")
        print(f"[OK] Novo cenário Celta de Tongóbriga salvo em {DIR_BG / 'tongobriga_cenario.png'}")

    if praca_src.exists():
        img_p = Image.open(praca_src).convert("RGBA")
        img_p.save(DIR_RAW / "praca_canaveses_raw.png", "PNG")
        bg_p = img_p.resize((640, 360), Image.Resampling.LANCZOS)
        bg_p.save(DIR_BG / "praca_cenario.png", "PNG")
        print(f"[OK] Novo cenário da Praça Central salvo em {DIR_BG / 'praca_cenario.png'}")

        # Criar um overlay limpo de vinheta atmosférica suave (sem a barra marrom no topo!)
        overlay = Image.new("RGBA", (640, 360), (0, 0, 0, 0))
        ov_arr = np.zeros((360, 640, 4), dtype=np.uint8)
        yy, xx = np.mgrid[0:360, 0:640]
        nx = (xx - 320.0) / 320.0
        ny = (yy - 180.0) / 180.0
        dist = np.sqrt(nx * nx + ny * ny)
        vig = np.clip((dist - 0.88) / 0.55, 0.0, 1.0)
        ov_arr[:, :, 0] = 12
        ov_arr[:, :, 1] = 10
        ov_arr[:, :, 2] = 8
        ov_arr[:, :, 3] = (vig * 95).astype(np.uint8)
        Image.fromarray(ov_arr, mode="RGBA").save(DIR_OVERLAYS / "praca_foreground.png", "PNG")
        print(f"[OK] Overlay da Praça Central limpo salvo em {DIR_OVERLAYS / 'praca_foreground.png'}")


if __name__ == "__main__":
    t_src = Path(r"C:\Users\Icaro\.gemini\antigravity\brain\d230022c-e2cb-4685-b15f-9b28e390df89\tongobriga_celta_raw_1792364199555.jpg")
    p_src = Path(r"C:\Users\Icaro\.gemini\antigravity\brain\d230022c-e2cb-4685-b15f-9b28e390df89\praca_canaveses_raw_1792364204211.jpg")
    processar_cenarios(t_src, p_src)
    processar_guerreiros()
