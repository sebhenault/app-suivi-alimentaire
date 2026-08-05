#!/usr/bin/env python3
"""Génère un QR code d'installation pour une URL (PNG et/ou SVG).

Dépendance : pip install "qrcode[pil]"
Exemples :
  python make_qr.py https://user.github.io/app/ -o install-qr.png
  python make_qr.py https://user.github.io/app/ -o qr.svg --svg   # SVG inline-friendly
"""
import argparse

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("url")
    ap.add_argument("-o", "--out", default="install-qr.png")
    ap.add_argument("--svg", action="store_true", help="Sortie SVG (chemin vectoriel).")
    ap.add_argument("--box", type=int, default=12)
    ap.add_argument("--border", type=int, default=3)
    args = ap.parse_args()

    import qrcode
    if args.svg:
        import qrcode.image.svg
        img = qrcode.make(args.url, image_factory=qrcode.image.svg.SvgPathImage,
                          box_size=10, border=2)
    else:
        img = qrcode.make(args.url, box_size=args.box, border=args.border)
    img.save(args.out)
    print("QR ->", args.out, "(", args.url, ")")

if __name__ == "__main__":
    main()
