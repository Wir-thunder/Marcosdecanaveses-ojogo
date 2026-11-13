#!/usr/bin/env python3
"""Cliente local para enviar prompts para a ponte Colab T4 e salvar imagens/.ogv no projeto."""

import argparse
import base64
import json
import os
import sys
import urllib.request


def post_json(url: str, payload: dict) -> bytes:
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=300) as resp:
        return resp.read()


def main() -> int:
    parser = argparse.ArgumentParser(description="Cliente Colab T4 Bridge")
    parser.add_argument("--url", required=True, help="URL trycloudflare do Colab (sem barra no final)")
    parser.add_argument("--mode", choices=["health", "image", "ogv"], required=True)
    parser.add_argument("--prompt", default="", help="Prompt de geração")
    parser.add_argument("--out", default="", help="Caminho de saída do arquivo")
    parser.add_argument("--width", type=int, default=640)
    parser.add_argument("--height", type=int, default=360)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--duration", type=float, default=4.0)
    args = parser.parse_args()

    base_url = args.url.rstrip("/")

    if args.mode == "health":
        with urllib.request.urlopen(f"{base_url}/health", timeout=30) as resp:
            print(resp.read().decode("utf-8"))
        return 0

    if not args.prompt or not args.out:
        print("Erro: --prompt e --out são obrigatórios para image/ogv.", file=sys.stderr)
        return 1

    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)

    if args.mode == "image":
        raw = post_json(
            f"{base_url}/generate_image",
            {
                "prompt": args.prompt,
                "out_width": args.width,
                "out_height": args.height,
                "seed": args.seed,
            },
        )
        res = json.loads(raw.decode("utf-8"))
        with open(args.out, "wb") as f:
            f.write(base64.b64decode(res["png_base64"]))
        print(f"Imagem salva em: {args.out}")
    elif args.mode == "ogv":
        raw = post_json(
            f"{base_url}/generate_kenburns_ogv",
            {
                "prompt": args.prompt,
                "out_width": args.width,
                "out_height": args.height,
                "duration_sec": args.duration,
                "seed": args.seed,
            },
        )
        with open(args.out, "wb") as f:
            f.write(raw)
        print(f"Vídeo .ogv salvo em: {args.out}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
