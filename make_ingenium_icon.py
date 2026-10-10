#!/usr/bin/env python3
# INGENIUM  |  Copyright (c) 2026 Yannie D. Forest. All rights reserved.
# NO LICENCE IS GRANTED. See LICENCE.txt.
#
# Lays out the Ingenium seal for the Mac app's icon (standard library only).
# R71: the seal is the raised seal the app shows on its door and in its top
# bar, approved on 7 October 2026: the face and its bevelled rim, the star cut
# into lit and shaded halves, the heart stone, and their short shadows, all
# lit from the upper left. Its images were rendered once from the page's own
# drawing and are kept in icons/; this script copies them where the build
# expects them:
#   ingenium.iconset/   the ten sizes iconutil turns into ingenium.icns
#   ingenium.png        512 px, beside the app
#   android_icons/      the Fire app's launcher sizes, for reference
# The ready-made ingenium.icns is committed too, so iconutil is only needed
# when this script is run again. R75: when icons/ingenium.iconset is not
# there, the ten sizes are drawn from icons/ingenium.png with sips.
import os, shutil, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ICONS = os.path.join(HERE, "icons")

# the ten sizes iconutil wants: (file name, pixels)
SIZES = [("icon_%dx%d%s.png" % (p, p, s), p * (2 if s else 1))
         for p in (16, 32, 128, 256, 512) for s in ("", "@2x")]


def main():
    src = os.path.join(ICONS, "ingenium.iconset")
    out = os.path.join(HERE, "ingenium.iconset")
    os.makedirs(out, exist_ok=True)
    names = sorted(n for n in os.listdir(src) if n.endswith(".png")) if os.path.isdir(src) else []
    if len(names) == 10:
        for n in names:
            shutil.copyfile(os.path.join(src, n), os.path.join(out, n))
            print("laid out", n)
    else:
        # R75: without the ten ready images, each size is drawn from the
        # 512 px seal with sips, part of every macOS
        import subprocess
        seal = os.path.join(ICONS, "ingenium.png")
        for n, px in SIZES:
            subprocess.run(["sips", "-z", str(px), str(px), seal, "--out", os.path.join(out, n)],
                           check=True, stdout=subprocess.DEVNULL)
            print("drew", n, "from the 512 px seal")
    shutil.copyfile(os.path.join(ICONS, "ingenium.png"), os.path.join(HERE, "ingenium.png"))
    print("laid out ingenium.png 512")
    android = os.path.join(HERE, "android_icons")
    os.makedirs(android, exist_ok=True)
    for n in sorted(os.listdir(os.path.join(ICONS, "android"))):
        shutil.copyfile(os.path.join(ICONS, "android", n), os.path.join(android, n))
    print("laid out the android launcher set 48-192")

if __name__ == "__main__":
    try:
        main()
    except Exception:
        import traceback
        traceback.print_exc()
        sys.exit(1)
