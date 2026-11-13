from pathlib import Path
from PIL import Image
from rembg import remove

# Diretórios do projeto
DIR_RAIZ = Path(__file__).resolve().parent.parent
DIR_ORIGEM = DIR_RAIZ / "Sprites"
DIR_PROPS = DIR_RAIZ / "Assets" / "Environment" / "props"
DIR_CHARS = DIR_RAIZ / "Assets" / "Characters"

DIR_PROPS.mkdir(parents=True, exist_ok=True)
DIR_CHARS.mkdir(parents=True, exist_ok=True)

def limpar_e_salvar_prop(nome_arquivo, nome_saida, tamanho_alvo=None):
    caminho_in = DIR_ORIGEM / nome_arquivo
    caminho_out = DIR_PROPS / nome_saida
    
    if not caminho_in.exists():
        print(f"[!] Ficheiro não encontrado: {caminho_in}")
        return

    print(f"-> A carregar '{nome_arquivo}'...")
    with Image.open(caminho_in) as img:
        # Reduz resoluções exageradas para acelerar a inferência na CPU
        if max(img.size) > 512:
            img.thumbnail((512, 512), Image.Resampling.BILINEAR)

        print(f"-> A remover fundo de '{nome_arquivo}' (isto pode levar alguns segundos)...")
        img_sem_fundo = remove(img)
        
        # Recorta bordas vazias
        bbox = img_sem_fundo.getbbox()
        if bbox:
            img_sem_fundo = img_sem_fundo.crop(bbox)
            
        # Redimensionamento final com interpolação Nearest para pixel art
        if tamanho_alvo:
            img_sem_fundo = img_sem_fundo.resize(tamanho_alvo, resample=Image.Resampling.NEAREST)
            
        img_sem_fundo.save(caminho_out, "PNG")
        print(f"[OK] Concluído: {caminho_out}\n")

if __name__ == "__main__":
    print("=== Início do Processamento de Assets ===")
    
    # 1. Processar Caldeirão
    limpar_e_salvar_prop("Caldeirão.jpeg", "caldeirao.png", tamanho_alvo=(64, 64))

    # 2. Processar Balcão
    limpar_e_salvar_prop("Balcao.jpeg", "balcao.png")
    
    print("=== Processamento Concluído ===")