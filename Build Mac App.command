#!/usr/bin/env bash
# INGENIUM  |  Copyright (c) 2026 Yannie D. Forest. All rights reserved.
# NO LICENCE IS GRANTED. No copying, adaptation, redistribution, reverse
# engineering or commercial use without the author's written permission.
# See LICENCE.txt. Every distributed copy carries a build marker.
#
# Ingenium — build the standalone macOS app.
# Double-click this file. It needs Python 3 on THIS Mac only; the finished app
# needs nothing at all on the Macs you give it to.
#
# R23: two cures for the two ways this used to fail.
#  1. Every step prints as it works, live — nothing sits silent any more.
#  2. All the heavy lifting happens on this Mac's OWN disk (a work folder at
#     ~/Library/Caches/IngeniumBuild), not on this folder. Running from a USB
#     stick is exactly as fast as running from the Desktop, and slow-stick or
#     FAT-format problems cannot stall the build. The finished app is placed
#     on your Desktop (and a copy back in this folder).

cd "$(dirname "$0")" || exit 1
FOLDER="$(pwd -P)"
set -o pipefail
LOG="build_log.txt"
: > "$LOG"
T0=$SECONDS
STEP_T=$SECONDS

say(){ printf '%s\n' "$*" | tee -a "$LOG"; }
step(){ STEP_T=$SECONDS; say ""; say "[$1/8] $2..."; }
endstep(){ say "       (took $((SECONDS-STEP_T))s)"; }
runlive(){ "$@" 2>&1 | tee -a "$LOG"; return ${PIPESTATUS[0]}; }

# Why the tools would not install, said plainly. A path to a log is not an
# answer, and the causes below account for nearly every failure.
tools_failed(){
  say ""
  say "The build tools could not be installed."
  say ""
  say "The last lines of the log say:"
  tail -n 18 "$LOG"
  say ""
  if grep -qiE "no matching distribution|could not find a version" "$LOG"; then
    say "READ THIS FIRST: no build tool exists yet for this version of Python."
    say "PyInstaller lags a few months behind each new Python release, so a very"
    say "new Python cannot build an app at all."
    say ""
    say "The way forward: install Python 3.12 or 3.13 alongside the one you"
    say "have (python.org installers keep both; nothing breaks), then run this"
    say "again."
  elif grep -qiE "temporary failure in name resolution|failed to establish a new connection|proxyerror|network is unreachable|timed out" "$LOG"; then
    say "This step needs the internet once, to download the build tools."
    say ""
    say "Two ways forward:"
    say "  1. Connect and run this again. That is all."
    say "  2. Build offline: on any connected Mac run"
    say "       python3 -m pip download pyinstaller pywebview cmake setuptools wheel -d wheels"
    say "     then copy the resulting wheels folder next to this file."
  elif grep -qi "certificate_verify_failed" "$LOG"; then
    say "The download was refused by a certificate check, which usually means a"
    say "workplace or school network inspecting traffic. On a home connection"
    say "this normally goes away."
  else
    say "Full log:  $(pwd)/$LOG"
    say "Send that file and the exact cause can be identified."
  fi
  say ""
  read -r -p "Press Return to close. "
  exit 1
}

build_failed(){
  say ""
  say "The build did NOT finish, so no app was produced."
  say "The last lines of the log say:"
  tail -n 15 "$LOG"
  say ""
  say "Full log:  $(pwd)/$LOG — send that file and the cause can be found exactly."
  say ""
  read -r -p "Press Return to close. "
  exit 1
}

say "Ingenium — building the standalone Mac app"
say "Started $(date)"
say ""
say "What this does, in plain terms:"
say "  - ingenium.html in this folder IS the whole app; it needs no build."
say "  - This step wraps that same app as Ingenium.app: its own window, its own"
say "    Dock icon, no browser. You only do this once."
say "  - The real work happens on this Mac's own disk (a work folder in"
say "    ~/Library/Caches/IngeniumBuild), so it is just as quick from a USB"
say "    stick, and every step prints what it is doing as it goes."
say "  - R65: the app now carries its own engine (llama.cpp, compiled on this"
say "    Mac for this Mac's processor) and a built-in model, so it runs models"
say "    many times faster than the engine inside the page. The first build"
say "    compiles the engine (about 5 to 15 minutes) and downloads the model"
say "    (about 1.3 GB); both are kept, so later builds skip them."
say "  - When it finishes, Ingenium.app is waiting on your Desktop."

# --- 1: Python -------------------------------------------------------------
step 1 "Checking Python and Apple's command line tools"
# R75: Apple's free command line tools are checked first: they bring Python 3
# on a Mac that has none, and the compiler the engine needs in step 5. Without
# them, "python3" on macOS only offers to install them and runs nothing.
if ! xcode-select -p >/dev/null 2>&1 || ! /usr/bin/xcrun --find clang >/dev/null 2>&1; then
  say "This Mac needs Apple's free command line tools first: they bring Python 3"
  say "and the compiler the engine needs. A window from Apple now offers to"
  say "install them: click Install, wait until it finishes (a few minutes),"
  say "then double-click this Build file again. Nothing done so far is lost."
  xcode-select --install >/dev/null 2>&1 || true
  read -r -p "Press Return to close. "; exit 1
fi
if ! command -v python3 >/dev/null 2>&1 || ! python3 -c "import sys" >/dev/null 2>&1; then
  say "Python 3 does not run on this Mac."
  say "Install it from https://www.python.org/downloads/ and run this again."
  read -r -p "Press Return to close. "; exit 1
fi
PYV="$(python3 --version 2>&1)"
say "Found: $PYV"
case "$PYV" in
  *" 3.15"*|*" 3.16"*)
    say "Note: this Python is newer than the build tools usually follow. If the"
    say "download step below reports 'no matching distribution', install Python"
    say "3.12 or 3.13 from python.org alongside this one and run this again.";;
esac
endstep

# --- 2: the work area on this Mac's own disk -------------------------------
step 2 "Preparing the work area on this Mac's own disk"
WORK="$HOME/Library/Caches/IngeniumBuild"
SRC="$WORK/sources"
mkdir -p "$SRC" 2>>"$LOG" || { say "Could not create $WORK"; read -r -p "Press Return to close. "; exit 1; }
MISSING=0
for f in ingenium.html ingenium_app.py ingenium.spec bake_engine.py make_ingenium_icon.py app.json desktop_model.json \
         tools/build_engine_mac.sh tools/finish_mac_app.sh tools/prepare_desktop_model.py tools/check_lineup.py tools/stamp_build.py; do
  if [ -f "$f" ]; then mkdir -p "$SRC/$(dirname "$f")"; cp -f "$f" "$SRC/$f"; else say "MISSING from this folder: $f"; MISSING=1; fi
done
for f in LICENCE.txt THIRD_PARTY_NOTICES.txt; do [ -f "$f" ] && cp -f "$f" "$SRC/$f"; done
mkdir -p "$SRC/licences" && cp -f licences/* "$SRC/licences/" 2>>"$LOG" || true
# who the app is (app.json): its name and file name
APP_FILE="$(python3 -c "import json,re;c=json.load(open('app.json'));print(re.sub(r'[^A-Za-z0-9._-]','',str(c.get('file_name') or '')) or 'Ingenium')" 2>/dev/null || echo Ingenium)"
[ "$MISSING" -eq 1 ] && { say "The folder is incomplete; re-unzip the download and run again."; read -r -p "Press Return to close. "; exit 1; }

# THE SEAL. Ingenium's icon is its own raised seal, rendered from the app's
# page. The finished ingenium.icns comes with the folder; only if it is
# missing does a small script lay out the images (from icons/) and iconutil
# (part of every macOS) assemble them. R75: an icon that cannot be made is
# never a reason to stop: the app is then built with the plain icon.
if [ -f "ingenium.icns" ]; then
  say "Seal ready: ingenium.icns (as it came)"
else
  say "Laying out the Ingenium seal for the app icon..."
  if python3 make_ingenium_icon.py >>"$LOG" 2>&1 && iconutil -c icns "ingenium.iconset" -o "ingenium.icns" >>"$LOG" 2>&1; then
    say "Seal laid out: ingenium.icns"
  else
    rm -f ingenium.icns
    say "The seal could not be made into an icon here (the log says why). The"
    say "app is built anyway; only its Dock icon will be the plain one."
  fi
fi
[ -f "ingenium.png" ] || cp -f icons/ingenium.png ingenium.png 2>>"$LOG" || true
rm -f "$SRC/ingenium.icns" "$SRC/ingenium.png"
for f in ingenium.icns ingenium.png; do [ -f "$f" ] && cp -f "$f" "$SRC/" 2>>"$LOG"; done
say "Work area ready: $SRC"
endstep

# --- 3: the build tools -----------------------------------------------------
step 3 "The build tools (PyInstaller and pywebview)"
VENV="$WORK/.buildenv"
VPY="$VENV/bin/python"
TOOLS_OK=0
if [ -x "$VPY" ] && "$VPY" -c "import webview, PyInstaller" >/dev/null 2>&1 && [ -x "$VENV/bin/cmake" ]; then
  TOOLS_OK=1
fi
if [ "$TOOLS_OK" -eq 1 ]; then
  say "Already in place from a previous run — nothing to download."
else
  if [ ! -x "$VPY" ] || ! "$VPY" -c "import sys" >/dev/null 2>&1; then
    say "Creating the private build environment (under a minute, one time)..."
    rm -rf "$VENV"
    if ! python3 -m venv "$VENV" >>"$LOG" 2>&1; then
      say ""; say "Could not create the build environment. See $LOG"
      read -r -p "Press Return to close. "; exit 1
    fi
  fi
  # R75: proxy_tools, a small part of pywebview, is published only as source
  # (it is plain Python and installs in seconds), so it goes in first; the
  # rest must come ready-made, which fails at once on a Python too new for them.
  if [ -d wheels ] && ls wheels/*.whl >/dev/null 2>&1; then
    say "Installing from the local wheels folder (no connection needed)..."
    runlive "$VPY" -m pip install --no-index --find-links wheels setuptools wheel || tools_failed
    runlive "$VPY" -m pip install --no-index --find-links wheels --no-build-isolation proxy_tools || tools_failed
    runlive "$VPY" -m pip install --no-index --find-links wheels --only-binary=:all: pyinstaller pywebview cmake || tools_failed
  else
    say "Downloading and installing them now (about 60 MB, one time; cached"
    say "on this Mac afterwards, so the next run skips this entirely):"
    runlive "$VPY" -m pip install --disable-pip-version-check --upgrade pip || tools_failed
    runlive "$VPY" -m pip install --disable-pip-version-check proxy_tools || tools_failed
    runlive "$VPY" -m pip install --disable-pip-version-check --only-binary=:all: pyinstaller pywebview cmake || tools_failed
  fi
fi
say "PyInstaller: $("$VPY" -m PyInstaller --version 2>&1)"
endstep

# --- 4: bake the local engine ----------------------------------------------
step 4 "Baking the local engine into the app"
say "The engine already comes inside ingenium.html; this step only checks it,"
say "and bakes it in again (one download, checked against its checksums) if missing."
if ( cd "$SRC" && "$VPY" bake_engine.py ingenium.html compat ) 2>&1 | tee -a "$LOG"; then
  # The folder's own copy gains the engine too, so the plain double-click
  # route is just as equipped as the app.
  cp -f "$SRC/ingenium.html" "$FOLDER/ingenium.html" 2>>"$LOG" || true
  say "Engine baked (this folder's ingenium.html now carries it too)."
else
  say "Engine bake was skipped (usually: no connection). The app can still"
  say "add the engine on its Models page, so the build carries on."
fi
endstep

# --- 5: the native engine ----------------------------------------------------
step 5 "The app's own engine (llama.cpp, compiled for this Mac)"
ENGINE="$WORK/engine-b11321-native"
if [ -x "$ENGINE/llama-server" ] && "$ENGINE/llama-server" --version >/dev/null 2>&1; then
  say "Already compiled on this Mac by an earlier build; kept as it is."
  # R78: llama.cpp's trainer (Train a small model from zero) came later, so a
  # Mac whose engine was compiled before compiles only the trainer now
  if [ ! -x "$ENGINE/llama-finetune" ] && /usr/bin/xcrun --find clang >/dev/null 2>&1; then
    say "Compiling llama.cpp's trainer, for Train a small model from zero (a few minutes, once)."
    PATH="$VENV/bin:$PATH" runlive bash "$SRC/tools/build_engine_mac.sh" "$ENGINE" trainer-native "$WORK/engine-build" \
      || say "The trainer did not compile; the app works without it (only training from zero is missing)."
  fi
else
  if ! xcode-select -p >/dev/null 2>&1 || ! /usr/bin/xcrun --find clang >/dev/null 2>&1; then
    say "Compiling the engine needs Apple's free command line tools, which this"
    say "Mac does not have yet. A window from Apple now offers to install them:"
    say "click Install, wait for it to finish (a few minutes), then double-click"
    say "this Build file again. Nothing done so far is lost."
    xcode-select --install >/dev/null 2>&1 || true
    read -r -p "Press Return to close. "; exit 1
  fi
  say "Compiling now: about 5 to 15 minutes, once. Kept for later builds."
  if ! PATH="$VENV/bin:$PATH" runlive bash "$SRC/tools/build_engine_mac.sh" "$ENGINE" native "$WORK/engine-build"; then
    say ""
    say "The engine did not compile, so the app will be built without it: it"
    say "still works, with the slower engine inside the page. The log above says why."
    rm -rf "$ENGINE"
  fi
fi
endstep

# --- 6: the built-in model -----------------------------------------------------
step 6 "The built-in model"
# R70: an Apple silicon Mac (a Mac mini, for example) takes its own list of built-in models
MODELS_FOR=desktop; [ "$(uname -m)" = "arm64" ] && MODELS_FOR=mac-arm
if ! INGENIUM_MODEL_CACHE="$HOME/.cache/ingenium-models" runlive "$VPY" "$SRC/tools/prepare_desktop_model.py" "$SRC/models" "$MODELS_FOR"; then
  say "The model could not be downloaded (usually: no connection). The app is"
  say "built without it; models can be added in the app at any time."
  rm -rf "$SRC/models"
fi
endstep

# --- 7: assemble the app ----------------------------------------------------
step 7 "Assembling $APP_FILE.app"
say "The longest step. Lines appear below as the bundler works; the app is"
say "put together on this Mac's disk, not on this folder."
rm -rf "$WORK/sources/build" "$WORK/sources/dist"
# R77: this build's own number (the version, the day and the time it was
# built), shown in About and in Finder's Get Info, as the cloud builds show theirs
BUILD_NO="3.2.$(date +%Y%m%d).$(date +%H%M)"
if "$VPY" "$SRC/tools/stamp_build.py" "$SRC/ingenium.html" "$BUILD_NO" >>"$LOG" 2>&1; then
  say "Build number: $BUILD_NO"
else
  say "(The build number could not be written into the page; About shows the page's date instead.)"
fi
if ! ( cd "$WORK/sources" && INGENIUM_VERSION="$BUILD_NO" "$VPY" -m PyInstaller --noconfirm --clean ingenium.spec ) 2>&1 | tee -a "$LOG"; then
  build_failed
fi
APP="$WORK/sources/dist/$APP_FILE.app"
[ -d "$APP" ] || build_failed
if [ -x "$ENGINE/llama-server" ]; then
  runlive bash "$SRC/tools/finish_mac_app.sh" "$APP" "$ENGINE" "$SRC/models" || build_failed
  say "Testing the app's engine with the built-in model..."
  if [ -f "$SRC/models/builtin.json" ]; then
    if "$APP/Contents/MacOS/$APP_FILE" --selftest-model builtin --selftest-out "$WORK/selftest.json" >>"$LOG" 2>&1; then
      say "Passed: $("$VPY" -c "import json;r=json.load(open('$WORK/selftest.json'));print('the model answered %r at %.1f words a second' % (r['reply'], (r.get('timings') or {}).get('predicted_per_second') or 0))")"
    else
      say "The test did not pass; the app is placed anyway. What it said:"
      tail -n 25 "$WORK/selftest.json" | tee -a "$LOG"
    fi
  fi
fi
endstep

# --- 8: place the app -------------------------------------------------------
step 8 "Placing $APP_FILE on your Desktop"
DEST="$HOME/Desktop/$APP_FILE.app"
if [ -d "$DEST" ]; then
  rm -rf "$HOME/Desktop/$APP_FILE (replaced).app" 2>/dev/null
  mv "$DEST" "$HOME/Desktop/$APP_FILE (replaced).app" 2>/dev/null || true
fi
if ditto "$APP" "$DEST" 2>>"$LOG" || cp -R "$APP" "$DEST" 2>>"$LOG"; then
  say "On your Desktop:  $DEST"
else
  say "Could not place a copy on the Desktop (is $HOME/Desktop reachable?)."
fi
rm -rf "$FOLDER/$APP_FILE.app"
if ditto "$APP" "$FOLDER/$APP_FILE.app" 2>>"$LOG" || cp -R "$APP" "$FOLDER/$APP_FILE.app" 2>>"$LOG"; then
  say "And beside this script:  $FOLDER/$APP_FILE.app"
else
  say "(Copying back beside this script failed — the Desktop copy is the one"
  say "to use. That can happen when this folder is on a read-only volume.)"
fi
# Clear the download quarantine on the copies just placed, so they open on
# THIS Mac with no Gatekeeper prompt. On ANOTHER Mac the first open still
# uses right-click then Open; MACOS_IF_BLOCKED.txt has the other routes.
xattr -dr com.apple.quarantine "$DEST" >/dev/null 2>&1 || true
xattr -dr com.apple.quarantine "$FOLDER/$APP_FILE.app" >/dev/null 2>&1 || true
endstep

say ""
say "SUCCESS. $APP_FILE.app is one self-contained bundle — the page, the"
say "engine, the built-in model and the seal all inside — so it opens from"
say "anywhere you move it, with nothing beside it, and it needs no connection."
say ""
say "Total time: $((SECONDS-T0))s. Opening the Desktop now."
open "$HOME/Desktop" >/dev/null 2>&1
say ""
read -r -p "Press Return to close. "
