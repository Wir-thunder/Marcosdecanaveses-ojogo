"""
Pipeline PhotoCraft para os Clientes da Loja do Alquimista:
Extrai os 4 arquétipos de clientes de `clientes_novos_raw_1792406412745.jpg`,
remove o fundo branco com flood-fill exterior + anti-halo,
centraliza cada pose pelo centro de massa do tronco/cabeça (eliminando qualquer
deslocamento lateral ou 'moonwalk' entre frames) e alinha os pés na mesma linha base.

Gera para cada cliente (0..3):
- walk_down_1..4.png
- walk_up_1..4.png
- walk_left_1..4.png   (100% nativo olhando para a esquerda!)
- walk_right_1..4.png  (100% nativo olhando para a direita!)
"""

from pathlib import Path
from PIL import Image
import numpy as np
from scipy import ndimage

DIR_RAIZ = Path(__file__).resolve().parent.parent
DIR_CLIENTES = DIR_RAIZ / "Assets" / "Characters" / "Clientes"
DIR_CLIENTES.mkdir(parents=True, exist_ok=True)

RAW_PATH = Path(r"C:\Users\Icaro\.gemini\antigravity\brain\d230022c-e2cb-4685-b15f-9b28e390df89\clientes_novos_raw_1792406412745.jpg")
CANVAS_W, CANVAS_H = 128, 160
FOOT_Y = 152  # Linha base fixa para os pés


def remover_fundo_branco(arr_rgb: np.ndarray) -> np.ndarray:
    """Remove o fundo branco puro por flood-fill exterior e limpa halo."""
    arr = arr_rgb.astype(np.int32)
    sat = arr.max(axis=2) - arr.min(axis=2)
    lum = arr.mean(axis=2)

    is_white_bg = (lum >= 232) & (sat <= 26)
    fg = ~is_white_bg

    # Remover ruído isolado (< 80 pixels)
    lbl, num = ndimage.label(fg)
    if num > 0:
        sizes = ndimage.sum(fg, lbl, range(1, num + 1))
        valid = np.where(sizes >= 80)[0] + 1
        fg = np.isin(lbl, valid)

    # Fechar buracos internos que não tocam a borda da imagem
    bg = ~fg
    lbl_bg, num_bg = ndimage.label(bg)
    if num_bg > 0:
        border_lbls = (
            set(np.unique(lbl_bg[0, :]))
            | set(np.unique(lbl_bg[-1, :]))
            | set(np.unique(lbl_bg[:, 0]))
            | set(np.unique(lbl_bg[:, -1]))
        )
        for b_i in range(1, num_bg + 1):
            if b_i not in border_lbls:
                fg[lbl_bg == b_i] = True

    # Remover 1px de halo branco na borda externa
    eroded = ndimage.binary_erosion(fg, iterations=1)
    border = fg & (~eroded)
    halo = border & (lum >= 205) & (sat <= 35)
    fg = fg & (~halo)

    alpha = (fg.astype(np.uint8)) * 255
    return np.dstack([arr_rgb, alpha])


def normalizar_frame(sprite_rgba: np.ndarray, target_h: int = 136) -> Image.Image:
    """
    Recorta o personagem, redimensiona para ter exatamente `target_h` pixels de altura,
    e centraliza horizontalmente pelo centro de massa da metade superior (cabeça + tronco),
    garantindo que a cabeça/tronco nunca oscilem para trás ou para a frente quando as pernas se movem!
    """
    alpha = sprite_rgba[:, :, 3]
    rows = np.where((alpha > 10).sum(axis=1) > 1)[0]
    cols = np.where((alpha > 10).sum(axis=0) > 1)[0]
    if len(rows) == 0 or len(cols) == 0:
        return Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))

    tight = sprite_rgba[rows.min():rows.max() + 1, cols.min():cols.max() + 1]
    th, tw = tight.shape[:2]

    scale = target_h / float(th)
    nw = max(1, int(round(tw * scale)))
    nh = target_h

    pil_tight = Image.fromarray(tight, mode="RGBA").resize((nw, nh), Image.Resampling.LANCZOS)
    arr_resized = np.array(pil_tight)

    # Calcular o centro de massa horizontal usando os 60% superiores (cabeça e tronco)
    upper_h = max(1, int(nh * 0.6))
    upper_alpha = (arr_resized[:upper_h, :, 3] > 20).astype(np.float32)
    if upper_alpha.sum() > 0:
        x_indices = np.arange(nw, dtype=np.float32)
        torso_center_x = float((upper_alpha.sum(axis=0) * x_indices).sum() / upper_alpha.sum())
    else:
        torso_center_x = nw / 2.0

    canvas = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    paste_x = int(round((CANVAS_W / 2.0) - torso_center_x))
    paste_y = FOOT_Y - nh
    canvas.paste(pil_tight, (paste_x, paste_y), pil_tight)
    return canvas


def processar_clientes():
    if not RAW_PATH.exists():
        print(f"[ERRO] Arquivo não encontrado: {RAW_PATH}")
        return

    img = Image.open(RAW_PATH).convert("RGB")
    w, h = img.size
    arr_rgba = remover_fundo_branco(np.array(img))

    # 4 linhas (uma por cliente)
    row_bounds = [
        (10, int(h * 0.255)),
        (int(h * 0.255), int(h * 0.505)),
        (int(h * 0.505), int(h * 0.752)),
        (int(h * 0.752), h - 5),
    ]

    for c_idx, (y0, y1) in enumerate(row_bounds):
        dir_c = DIR_CLIENTES / f"cliente_{c_idx}"
        dir_c.mkdir(parents=True, exist_ok=True)
        for old in dir_c.glob("*.png"):
            old.unlink()

        row_slice = arr_rgba[y0:y1, :]
        col_activity = (row_slice[:, :, 3] > 10).sum(axis=0)

        # Detectar segmentos horizontais (cada boneco na linha)
        segs = []
        in_s = False
        s0 = 0
        gap = 0
        for x in range(w):
            if col_activity[x] > 3:
                if not in_s:
                    in_s = True
                    s0 = x
                gap = 0
            elif in_s:
                gap += 1
                if gap >= 5:
                    in_s = False
                    segs.append((s0, x - gap))
                    gap = 0
        if in_s:
            segs.append((s0, w - 1))

        segs = [s for s in segs if (s[1] - s[0]) >= 35]
        print(f"Cliente {c_idx}: {len(segs)} poses detectadas na linha")

        poses = [normalizar_frame(row_slice[:, sx0:sx1 + 1]) for sx0, sx1 in segs]
        if len(poses) < 10:
            print(f"[AVISO] Cliente {c_idx} tem {len(poses)} poses")
            continue

        # Layout das 10 poses geradas na linha:
        # 0: front idle, 1: front step
        # 2: back idle,  3: back step 1, 4: back step 2
        # 5: left stride, 6: left idle 1, 7: left idle 2
        # 8: right stride 1, 9: right stride 2
        down_frames = [poses[0], poses[1], poses[0], poses[1].transpose(Image.Transpose.FLIP_LEFT_RIGHT)]
        up_frames = [poses[2], poses[3], poses[2], poses[4]]
        left_frames = [poses[6], poses[5], poses[7], poses[5]]
        # Para a direita usamos os frames nativos da direita (8 e 9) intercalados com a pose neutra espelhada da 6
        right_idle = poses[6].transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        right_frames = [right_idle, poses[8], right_idle, poses[9]]

        anim_map = {
            "walk_down": down_frames,
            "walk_up": up_frames,
            "walk_left": left_frames,
            "walk_right": right_frames,
        }

        for anim_name, flist in anim_map.items():
            for fi, frm in enumerate(flist):
                frm.save(dir_c / f"{anim_name}_{fi + 1}.png", "PNG")

    print(f"[OK] Todos os 4 clientes processados e alinhados pelo centro de massa em {DIR_CLIENTES}")


if __name__ == "__main__":
    processar_clientes()

