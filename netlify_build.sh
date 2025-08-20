#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
CLIENT_DIR="$ROOT/client"
FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"

echo "▶️ Instalando Flutter ($FLUTTER_VERSION)…"
git clone --depth 1 -b "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$ROOT/flutter"
export PATH="$ROOT/flutter/bin:$PATH"

flutter --version
flutter doctor -v || true

echo "▶️ Resolviendo dependencias…"
cd "$CLIENT_DIR"
flutter pub get

echo "▶️ Compilando Flutter Web (release)…"
# Si querés CanvasKit: agregá --web-renderer canvaskit
flutter build web --release --no-tree-shake-icons

echo "✅ Listo. Publicando: $CLIENT_DIR/build/web"
