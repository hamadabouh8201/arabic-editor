#!/usr/bin/env bash
# يبني editor.exe لويندوز 64 بت باستخدام mingw-w64
set -euo pipefail

cd "$(dirname "$0")"

CC="${CC:-x86_64-w64-mingw32-gcc}"
OUT_DIR="${OUT_DIR:-build}"

mkdir -p "$OUT_DIR"

"$CC" -municode -mwindows -O2 -Wall -Wextra -std=c11 \
    -o "$OUT_DIR/editor.exe" src/main.c \
    -luser32 -lgdi32

echo "Built: $OUT_DIR/editor.exe"
