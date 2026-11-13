#!/usr/bin/env python3
"""
aplicar_icones.py — liga icones criados em Assets/Icons aos recursos .tres.

Uso (na raiz do projeto):
    python ferramentas/aplicar_icones.py            # aplica as alteracoes
    python ferramentas/aplicar_icones.py --dry-run  # so mostra o que faria

O que faz:
- Percorre Recursos/Recursos_ingredientes e Recursos/Recursos_pocoes.
- Para cada .tres cujo "id" tenha um PNG com o mesmo nome em
  Assets/Icons/Ingredients ou Assets/Icons/Potions, preenche o campo
  "icone" do ItemData.
- E seguro correr varias vezes: nao duplica referencias e ignora quem ja tem icone.

Requisitos: Python 3 (sem dependencias externas).
"""

import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent

# (pasta dos .tres, pasta dos PNG, prefixo do caminho res://)
MAPAS = [
    (RAIZ / "Recursos/Recursos_ingredientes",
     RAIZ / "Assets/Icons/Ingredients",
     "res://Assets/Icons/Ingredients"),
    (RAIZ / "Recursos/Recursos_pocoes",
     RAIZ / "Assets/Icons/Potions",
     "res://Assets/Icons/Potions"),
]


def extrair_id(texto):
    m = re.search(r'^\s*id\s*=\s*"([^"]+)"', texto, re.MULTILINE)
    return m.group(1) if m else None


def tem_icone(texto):
    return re.search(r'^\s*icone\s*=\s*ExtResource', texto, re.MULTILINE) is not None


def inserir_icone(texto, caminho_res):
    """Devolve o texto do .tres com uma nova ext_resource + campo icone."""
    # Se este caminho ja esta referenciado, nao mexe.
    if caminho_res in texto:
        return texto

    # id de ext_resource unico (evita colisao com ids existentes).
    ids_existentes = re.findall(r'id="([^"]+)"', texto)
    n = 1
    while ("icone_%d" % n) in ids_existentes:
        n += 1
    id_ext = "icone_%d" % n
    bloco_ext = '[ext_resource type="Texture2D" path="%s" id="%s"]\n' % (
        caminho_res, id_ext)

    # 1) Inserir o bloco [ext_resource ...] logo a seguir ao header [gd_resource ...].
    linhas = texto.splitlines(keepends=True)
    idx_header = None
    for i, linha in enumerate(linhas):
        if linha.lstrip().startswith("[gd_resource"):
            idx_header = i
            break
    if idx_header is None:
        idx_header = 0
    linhas.insert(idx_header + 1, "\n" + bloco_ext)
    texto = "".join(linhas)

    # 2) Inserir "icone = ExtResource(...)" dentro de [resource],
    #    preferencialmente logo depois da linha "script = ExtResource(...)".
    m_script = re.search(
        r'^(\s*script\s*=\s*ExtResource\([^)]*\))', texto, re.MULTILINE)
    if m_script:
        texto = (texto[:m_script.end()]
                 + '\nicone = ExtResource("%s")' % id_ext
                 + texto[m_script.end():])
    else:
        texto = re.sub(
            r'^(\[resource\])',
            r'\1\nicone = ExtResource("%s")' % id_ext,
            texto, count=1, flags=re.MULTILINE)
    return texto


def main():
    dry = "--dry-run" in sys.argv
    total_ligados = 0
    total_sem_icone = 0

    for pasta_tres, pasta_png, prefixo_res in MAPAS:
        if not pasta_tres.exists():
            print("[!] Pasta nao encontrada: %s" % pasta_tres)
            continue

        for tres in sorted(pasta_tres.glob("*.tres")):
            texto = tres.read_text(encoding="utf-8")
            item_id = extrair_id(texto)
            if not item_id:
                continue

            png = pasta_png / (item_id + ".png")
            if not png.exists():
                total_sem_icone += 1
                continue
            if tem_icone(texto):
                continue

            novo_texto = inserir_icone(texto, "%s/%s.png" % (prefixo_res, item_id))
            if dry:
                print("[dry-run] ligaria %-28s -> %s" % (item_id, png.name))
            else:
                tres.write_text(novo_texto, encoding="utf-8")
                print("[ok] %-28s ligado a %s" % (item_id, png.name))
            total_ligados += 1

    print("-" * 52)
    print("Icones ligados agora: %d" % total_ligados)
    print("Recursos ainda sem PNG de icone: %d" % total_sem_icone)
    if total_ligados == 0 and total_sem_icone == 0:
        print("(nenhum recurso encontrado - confirma os caminhos)")


if __name__ == "__main__":
    main()
