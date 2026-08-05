#!/usr/bin/env python3
"""Génère les icônes d'une app (natif + PWA) : dégradé + motif simple.

C'est un TEMPLATE (assiette + couverts sur dégradé vert, façon MonAssiette).
Adapter la fonction `draw` pour un autre motif/une autre couleur.

Dépendance : pip install Pillow

Exemples :
  # Icône marketing native 1024 (sans alpha, requise TestFlight/App Store)
  python make_icons.py --native -o Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png
  # Jeu d'icônes PWA dans un dossier
  python make_icons.py --pwa -d pwa/icons
"""
import argparse, os
from PIL import Image, ImageDraw

TOP = (94, 208, 128)   # dégradé haut
BOT = (38, 150, 88)    # dégradé bas
WHITE = (255, 255, 255)

def render(content_scale=1.0):
    """Rend l'icône à 1024, motif centré, éventuellement réduit (maskable)."""
    S = 1024
    img = Image.new("RGB", (S, S), BOT)
    d = ImageDraw.Draw(img)
    for y in range(S):
        t = y / (S - 1)
        d.line([(0, y), (S, y)], fill=tuple(int(TOP[i] + (BOT[i]-TOP[i])*t) for i in range(3)))
    cx = cy = S / 2
    cs = content_scale
    sx = lambda x: cx + (x - 512) * cs
    sy = lambda y: cy + (y - 512) * cs
    rr = lambda x0,y0,x1,y1,rad: d.rounded_rectangle([sx(x0),sy(y0),sx(x1),sy(y1)], radius=rad*cs, fill=WHITE)
    pr = 360 * cs
    d.ellipse([cx-pr, cy-pr, cx+pr, cy+pr], outline=WHITE, width=int(18*cs))
    fx = 512 - 150
    for i in (-1, 0, 1):
        rr(fx + i*44 - 15, 512-210, fx + i*44 + 15, 512-40, 15)
    rr(fx-59, 512-70, fx+59, 512-20, 24)
    rr(fx-26, 512-40, fx+26, 512+240, 26)
    kx = 512 + 150
    rr(kx-46, 512-210, kx+20, 512-10, 40)
    rr(kx-26, 512-30, kx+26, 512+240, 26)
    return img

def save(img, path, size):
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    img.resize((size, size), Image.LANCZOS).save(path, "PNG")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--native", action="store_true", help="Icône marketing 1024.")
    ap.add_argument("--pwa", action="store_true", help="Jeu d'icônes PWA.")
    ap.add_argument("-o", "--out", default="icon-1024.png")
    ap.add_argument("-d", "--dir", default="icons")
    args = ap.parse_args()

    full = render(1.0)
    if args.native or not (args.native or args.pwa):
        save(full, args.out, 1024)
        print("native ->", args.out)
    if args.pwa:
        mask = render(0.72)  # zone de sécurité pour maskable
        save(full, os.path.join(args.dir, "icon-192.png"), 192)
        save(full, os.path.join(args.dir, "icon-512.png"), 512)
        save(mask, os.path.join(args.dir, "icon-maskable-512.png"), 512)
        save(full, os.path.join(args.dir, "apple-touch-icon.png"), 180)
        print("pwa icons ->", args.dir)

if __name__ == "__main__":
    main()
