from pathlib import Path
from PIL import Image, ImageDraw
import random

# Garante reproducibilidade da textura
random.seed(42)

DIR_OUT = Path("Assets/Environment/room")
DIR_OUT.mkdir(parents=True, exist_ok=True)
FILE_OUT = DIR_OUT / "cenario_loja.png"

LARGURA = 640
ALTURA = 360
Y_PAREDE_FIM = 124

img = Image.new("RGBA", (LARGURA, ALTURA), (0, 0, 0, 255))
draw = ImageDraw.Draw(img)

# 1. PAREDE DE PEDRA/GRANITO DO TÂMEGA (y = 0 até 124)
paleta_pedra = [
    (58, 68, 60),   # Tom base cinza-esverdeado
    (50, 59, 52),   # Tom escuro
    (72, 84, 74),   # Tom claro
]
cor_rejunte = (36, 42, 37)

altura_bloco = 16
largura_bloco = 32

for y in range(0, Y_PAREDE_FIM, altura_bloco):
    deslocamento = (y // altura_bloco % 2) * (largura_bloco // 2)
    for x in range(-largura_bloco, LARGURA + largura_bloco, largura_bloco):
        bx = x + deslocamento
        tom = random.choice(paleta_pedra)
        draw.rectangle([bx, y, bx + largura_bloco - 1, y + altura_bloco - 1], fill=tom)
        # Borda sutil de tijolo
        draw.rectangle([bx, y, bx + largura_bloco - 1, y + altura_bloco - 1], outline=cor_rejunte)

# 2. VIGA DE MADEIRA / RODAPÉ DA PAREDE (y = 120 até 128)
draw.rectangle([0, 120, LARGURA, 123], fill=(86, 52, 33))   # Borda clara
draw.rectangle([0, 124, LARGURA, 127], fill=(54, 32, 20))   # Sombra da viga

# 3. PISO DE TÁBUAS DE MADEIRA QUENTE (y = 128 até 360)
paleta_madeira = [
    (115, 77, 47),   # Madeira média
    (105, 70, 42),   # Madeira escura
    (124, 83, 51),   # Madeira clara
]
cor_linha_tabua = (62, 40, 24)

altura_tabua = 20
for y in range(128, ALTURA, altura_tabua):
    # Desenha a tábua horizontal
    tom = random.choice(paleta_madeira)
    draw.rectangle([0, y, LARGURA, y + altura_tabua - 1], fill=tom)
    
    # Junções verticais das tábuas
    deslocamento_x = (y // altura_tabua * 73) % 80
    for x in range(deslocamento_x, LARGURA, 96):
        draw.line([x, y, x, y + altura_tabua - 1], fill=cor_linha_tabua)
        # Prego sutil na ponta da tábua
        draw.point((x + 2, y + 2), fill=(40, 25, 15))
        draw.point((x - 2, y + 2), fill=(40, 25, 15))

    # Linha divisória horizontal entre tábuas
    draw.line([0, y + altura_tabua - 1, LARGURA, y + altura_tabua - 1], fill=cor_linha_tabua)

img.save(FILE_OUT, "PNG")
print(f"[OK] Fundo gerado com sucesso em: {FILE_OUT}")