#!/bin/bash
# INGENIUM  |  Copyright (c) 2026 Yannie D. Forest. All rights reserved.
# NO LICENCE IS GRANTED. See LICENCE.txt.
#
# Bakes the wllama engine into ingenium.html on its own, without building the
# whole app. Use this to get a working engine quickly and check it in Safari
# before you build. Once baked, the engine is permanent in that ingenium.html.

cd "$(dirname "$0")" || exit 1

echo "Ingenium: baking the local engine into ingenium.html"
echo "----------------------------------------------------"

if ! command -v python3 >/dev/null 2>&1; then
  echo "Python 3 was not found. Install it from https://www.python.org/downloads/"
  echo "then run this again."
  read -r -p "Press Return to close." _ || true
  exit 1
fi

if [ ! -f "ingenium.html" ]; then
  echo "ingenium.html is not in this folder. Keep this script beside it."
  read -r -p "Press Return to close." _ || true
  exit 1
fi

python3 bake_engine.py ingenium.html compat

echo
echo "----------------------------------------------------"
echo "Next: double-click ingenium.html to open it in your browser, go to the"
echo "Models page, and check that the engine shows as present. If it does, the"
echo "engine is baked in for good. Build the app whenever you like; it will"
echo "carry this same engine. From then on you only add your model files."
echo
read -r -p "Press Return to close." _ || true
