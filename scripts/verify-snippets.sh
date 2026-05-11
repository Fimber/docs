#!/usr/bin/env bash
# Exercises command patterns used across this docs repo (ImageMagick 7).
# Usage (from repo root, i.e. the directory that contains docs.json):
#   bash scripts/verify-snippets.sh
#
# Uses `magick` on PATH if present; otherwise requires Docker and runs:
#   dpokidov/imagemagick:latest

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKDIR="$(mktemp -d)"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

cd "$WORKDIR"
mkdir -p photos web originals processed

RUNNER=""
if command -v magick >/dev/null 2>&1; then
  RUNNER=host
elif command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  RUNNER=docker
else
  echo "error: install ImageMagick 7 (command: magick) or start Docker so checks can run in a container." >&2
  echo "hint (WSL): enable Docker Desktop WSL integration, or: sudo apt install imagemagick && magick --version" >&2
  exit 1
fi

invoke_magick() {
  if [[ "$RUNNER" == host ]]; then
    magick "$@"
  else
    docker run --rm -v "$WORKDIR:/data" -w /data dpokidov/imagemagick:latest magick "$@"
  fi
}

pass() { echo "ok  $*"; }

# --- Quickstart-style: resize + aspect (fit inside box) ---
invoke_magick -size 1600x1200 xc:skyblue photo.jpg
invoke_magick photo.jpg -resize 800x600 photo-small.jpg
wh=$(invoke_magick identify -format "%wx%h" photo-small.jpg)
[[ "$wh" == "800x600" ]] || { echo "fail resize box: got ${wh}"; exit 1; }
pass "resize fit inside 800x600"

# --- Geometry: only-shrink > ---
invoke_magick -size 100x100 xc:red small.jpg
invoke_magick small.jpg -resize '800x600>' same.jpg
wh2=$(invoke_magick identify -format "%wx%h" same.jpg)
[[ "$wh2" == "100x100" ]] || { echo "fail > shrink-only on small image: ${wh2}"; exit 1; }
pass "resize 800x600> leaves small image unchanged"

# --- Strip + identify ---
invoke_magick photo.jpg -strip stripped.jpg
invoke_magick identify stripped.jpg >/dev/null
pass "strip + identify"

# --- Tutorial-style pipeline (composite stack) ---
invoke_magick -size 120x32 xc:none -fill white -pointsize 18 -gravity center -annotate 0 "WM" PNG32:watermark.png
invoke_magick -size 400x300 gradient:blue-red originals/product1.jpg
invoke_magick originals/product1.jpg \
  -resize '160x160>' \
  -strip \
  watermark.png \
  -gravity SouthEast -geometry +4+4 \
  -composite \
  -quality 85 \
  processed/product1.webp
invoke_magick identify processed/product1.webp >/dev/null
pass "resize + strip + watermark + webp composite"

# --- mogrify -path -format (how-to batch) ---
invoke_magick -size 200x200 xc:yellow photos/sample.jpg
invoke_magick mogrify -resize '120x>' -quality 85 -path web -format webp photos/*.jpg
test -f web/sample.webp || { echo "fail mogrify -path web -format webp (expected web/sample.webp)"; exit 1; }
pass "mogrify -path -format webp"

# --- auto-orient + resize (command parses; no EXIF in synthetic file) ---
invoke_magick photos/sample.jpg -auto-orient -resize '100x>' auto.webp
invoke_magick identify auto.webp >/dev/null
pass "auto-orient + resize"

# --- jpeg:extent produces a bounded file ---
invoke_magick -size 2400x1800 gradient: -quality 95 big.jpg
invoke_magick big.jpg -resize '1200x>' -define jpeg:extent=150KB capped.jpg
sz=$(wc -c < capped.jpg | tr -d ' ')
max=$((150 * 1024 + 10240))
if [[ "$sz" -gt "$max" ]]; then
  echo "fail jpeg:extent size ${sz} bytes (expected <= ~${max})" >&2
  exit 1
fi
pass "jpeg:extent caps output size (${sz} bytes)"

# --- extent + gravity (how-to square thumb) ---
invoke_magick -size 800x600 xc:green wide.jpg
invoke_magick wide.jpg -resize '200x200>' -gravity center -background white -extent 200x200 square.jpg
wh3=$(invoke_magick identify -format "%wx%h" square.jpg)
[[ "$wh3" == "200x200" ]] || { echo "fail extent square: ${wh3}"; exit 1; }
pass "resize + extent square canvas"

echo ""
echo "All snippet checks passed (repo: $REPO_ROOT)."
