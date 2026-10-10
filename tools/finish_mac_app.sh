#!/bin/bash
# INGENIUM  |  Copyright (c) 2026 Yannie D. Forest. All rights reserved.
# NO LICENCE IS GRANTED. See LICENCE.txt.
#
# Puts the native engine and the built-in models inside a freshly built Mac
# app, then seals the app again (an ad hoc signature, as the build makes it):
#   bash tools/finish_mac_app.sh <the .app> <engine folder> [<models folder>]
# The engine goes to Contents/MacOS/engine/<platform>/ (programs belong
# there), its version and licence to Contents/Resources/engine/<platform>/,
# and the model to Contents/Resources/models/.
set -euo pipefail
APP="$1"
ENG="$2"
MOD="${3:-}"
[ -d "$APP/Contents/MacOS" ] || { echo "not an app: $APP"; exit 1; }
[ -f "$ENG/llama-server" ] || { echo "no engine in $ENG"; exit 1; }
case "$(uname -m)" in arm64) PLAT=macos-arm64 ;; *) PLAT=macos-x64 ;; esac

rm -rf "$APP/Contents/MacOS/engine" "$APP/Contents/Resources/engine" "$APP/Contents/Resources/models"
mkdir -p "$APP/Contents/MacOS/engine/$PLAT" "$APP/Contents/Resources/engine/$PLAT"
for f in llama-server llama-finetune; do   # R78: the trainer, when it was compiled
  if [ -f "$ENG/$f" ]; then
    cp "$ENG/$f" "$APP/Contents/MacOS/engine/$PLAT/$f"
    chmod 755 "$APP/Contents/MacOS/engine/$PLAT/$f"
    codesign --force --sign - --timestamp=none "$APP/Contents/MacOS/engine/$PLAT/$f"
  fi
done
for f in VERSION.txt LICENSE-llama.cpp.txt; do
  [ -f "$ENG/$f" ] && cp "$ENG/$f" "$APP/Contents/Resources/engine/$PLAT/$f"
done
if [ -n "$MOD" ] && [ -f "$MOD/builtin.json" ]; then
  mkdir -p "$APP/Contents/Resources/models"
  cp "$MOD"/* "$APP/Contents/Resources/models/"
  echo "Built-in models: $(python3 -c "import json,sys;d=json.load(open(sys.argv[1]));print(', '.join(m['name'] for m in d.get('models',[d])))" "$MOD/builtin.json")"
else
  echo "No built-in model."
fi
# the app's seal covers every file inside it, so it is made again last
codesign --force --sign - --timestamp=none "$APP"
codesign --verify --deep --strict "$APP" && echo "The app's seal is whole."
du -sh "$APP"
