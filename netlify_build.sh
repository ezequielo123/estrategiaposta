#!/usr/bin/env bash
set -euo pipefail

echo "🏗  Netlify Flutter Web build"

ROOT="$(pwd)"
CLIENT_DIR="$ROOT/client"
FLUTTER_VERSION="${FLUTTER_VERSION:-3.24.0}"   # podés fijarlo o dejarlo por env
FLUTTER_SDK_DIR="$HOME/flutter"

echo "🔧 Instalando dependencias de sistema (unzip, xz-utils, libglu)…"
apt-get update -y
apt-get install -y git unzip xz-utils libglu1-mesa >/dev/null

if [ ! -d "$FLUTTER_SDK_DIR" ]; then
  echo "⬇️  Descargando Flutter $FLUTTER_VERSION…"
  git clone --depth 1 -b "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_SDK_DIR"
else
  echo "♻️  Reutilizando Flutter en $FLUTTER_SDK_DIR"
fi

export PATH="$FLUTTER_SDK_DIR/bin:$PATH"

echo "🧪 Flutter doctor (resumen)…"
flutter --version
flutter config --enable-web

echo "📦 Pub get…"
cd "$CLIENT_DIR"
flutter pub get

echo "🧱 Build web…"
# Elegí el renderer que mejor te funcione. canvaskit suele ser más estable visualmente.
flutter build web --release --web-renderer canvaskit --source-maps

echo "✅ Listo. Publicar desde: $CLIENT_DIR/build/web"
