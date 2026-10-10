#!/bin/bash
# INGENIUM  |  Copyright (c) 2026 Yannie D. Forest. All rights reserved.
# NO LICENCE IS GRANTED. See LICENCE.txt.
#
# Builds the Mac app's native engine: llama.cpp's own server (llama-server),
# release b11321, as one self-contained program with nothing beside it.
#
#   bash tools/build_engine_mac.sh <out folder> [native|portable] [work folder]
#
#   native    tuned for THIS Mac's processor and macOS (the Build Mac App step,
#             so it also suits a Mac older than macOS 13.3)
#   portable  for any Intel Mac with macOS 13.3 or newer (the cloud build).
#             Every Mac that runs macOS 13 has a processor with AVX2, which
#             this build uses.
#
#   R78: llama.cpp's trainer (llama-finetune), for "Train a small model from
#   zero". It runs on the processor only, so it is compiled without Metal.
#   native    compiles it too, after the server (if it fails, the app is
#             still built: only training from zero is missing)
#   trainer   compiles only the trainer, portable (the cloud build keeps it
#             in its own cache, so the server is not compiled again)
#   trainer-native   only the trainer, for this Mac (a Mac whose server was
#             compiled by an earlier build)
#
# Needs the Xcode command line tools (clang and git) and cmake.
set -euo pipefail
OUT="$1"
MODE="${2:-native}"
WORK="${3:-${TMPDIR:-/tmp}/ingenium-engine-build}"
TAG="b11321"
COMMIT="b0aca3c"
mkdir -p "$WORK" "$OUT"
OUT="$(cd "$OUT" && pwd)"
SRC="$WORK/llama.cpp-$TAG"

if [ ! -f "$SRC/CMakeLists.txt" ]; then
  rm -rf "$SRC"
  echo "Getting llama.cpp $TAG (the engine's source, about 30 MB)..."
  if command -v git >/dev/null 2>&1 && git --version >/dev/null 2>&1; then
    git -c advice.detachedHead=false clone --quiet --depth 1 --branch "$TAG" https://github.com/ggml-org/llama.cpp "$SRC"
    got="$(git -C "$SRC" rev-parse HEAD)"
    case "$got" in
      "$COMMIT"*) echo "Source checked: commit ${got:0:7}." ;;
      *) echo "The source is not the expected commit ($got); stopping."; rm -rf "$SRC"; exit 1 ;;
    esac
  else
    curl -fL --retry 4 -o "$WORK/src.tar.gz" "https://github.com/ggml-org/llama.cpp/archive/refs/tags/$TAG.tar.gz"
    mkdir -p "$SRC"
    tar -xzf "$WORK/src.tar.gz" -C "$SRC" --strip-components 1
    rm -f "$WORK/src.tar.gz"
  fi
fi

ARCH="$(uname -m)"
JOBS="$(sysctl -n hw.logicalcpu 2>/dev/null || echo 4)"
COMMON=(-DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DLLAMA_OPENSSL=OFF
        -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF -DLLAMA_BUILD_UI=OFF -DLLAMA_USE_PREBUILT_UI=OFF)
if [ "$ARCH" = "arm64" ]; then
  COMMON+=(-DGGML_METAL=ON -DGGML_METAL_EMBED_LIBRARY=ON)
else
  COMMON+=(-DGGML_METAL=OFF)
fi

build() {   # build <name> <file name> <cmake options...>
  local name="$1" file="$2"; shift 2
  echo "Compiling the engine ($name; a few minutes)..."
  cmake -S "$SRC" -B "$WORK/build-$name" "${COMMON[@]}" "$@" > "$WORK/cmake-$name.log" 2>&1 \
    || { tail -30 "$WORK/cmake-$name.log"; exit 1; }
  cmake --build "$WORK/build-$name" --config Release --target llama-server -j "$JOBS" > "$WORK/build-$name.log" 2>&1 \
    || { tail -40 "$WORK/build-$name.log"; exit 1; }
  cp "$WORK/build-$name/bin/llama-server" "$OUT/$file"
  chmod 755 "$OUT/$file"
  echo "  $file: $(du -h "$OUT/$file" | cut -f1)"
}

# R78: the trainer: the examples switched on (it is one of them), no Metal,
# no OpenMP (Apple's compiler has none), linked into one program
build_trainer() {   # build_trainer <name> <cmake options...>
  local name="$1"; shift
  echo "Compiling the trainer ($name; a few minutes)..."
  cmake -S "$SRC" -B "$WORK/build-trainer-$name" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DLLAMA_OPENSSL=OFF \
        -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=ON -DLLAMA_BUILD_UI=OFF -DLLAMA_USE_PREBUILT_UI=OFF \
        -DGGML_METAL=OFF -DGGML_OPENMP=OFF "$@" > "$WORK/cmake-trainer-$name.log" 2>&1 \
    || { tail -30 "$WORK/cmake-trainer-$name.log"; return 1; }
  cmake --build "$WORK/build-trainer-$name" --config Release --target llama-finetune -j "$JOBS" > "$WORK/build-trainer-$name.log" 2>&1 \
    || { tail -40 "$WORK/build-trainer-$name.log"; return 1; }
  cp "$WORK/build-trainer-$name/bin/llama-finetune" "$OUT/llama-finetune" || return 1
  chmod 755 "$OUT/llama-finetune"
  echo "  llama-finetune: $(du -h "$OUT/llama-finetune" | cut -f1)"
}

case "$MODE" in
  native)
    build native llama-server -DGGML_NATIVE=ON
    build_trainer native -DGGML_NATIVE=ON \
      || echo "The trainer did not compile; the app works without it (only training from zero is missing)." ;;
  trainer)
    build_trainer portable -DGGML_NATIVE=OFF -DCMAKE_OSX_DEPLOYMENT_TARGET=13.3 || exit 1
    "$OUT/llama-finetune" --version 2>&1 | tail -2
    echo "Trainer ready in $OUT"; exit 0 ;;
  trainer-native)
    build_trainer native -DGGML_NATIVE=ON || exit 1
    echo "Trainer ready in $OUT"; exit 0 ;;
  *)
    build portable llama-server -DGGML_NATIVE=OFF -DCMAKE_OSX_DEPLOYMENT_TARGET=13.3 ;;
esac
echo "llama.cpp $TAG" > "$OUT/VERSION.txt"
cp "$SRC/LICENSE" "$OUT/LICENSE-llama.cpp.txt"
"$OUT/llama-server" --version 2>&1 | tail -2
echo "Engine ready in $OUT"
