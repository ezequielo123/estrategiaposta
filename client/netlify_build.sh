#!/usr/bin/env bash
set -euo pipefail

# ↓ Descarga Flutter estable una sola vez (luego Netlify lo cachea en $HOME)
FLUTTER_DIR="$HOME/flutter"
if [ ! -d "$FLUTTER_DIR" ]; then
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"

flutter --version
flutter config --enable-web
flutter pub get

# Asegura rewrite SPA (si ya lo tenés en web/_redirects, omite estas 2 líneas)
mkdir -p web
echo "/*    /index.html   200" > web/_redirects

flutter build web --release
