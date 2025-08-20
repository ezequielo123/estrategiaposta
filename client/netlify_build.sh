#!/usr/bin/env bash
set -euo pipefail

echo "PWD: $(pwd)"   # en Netlify debe imprimir .../repo/client

# --- Instalar Flutter limpio SIEMPRE (evitamos el que traiga la imagen) ---
FLUTTER_SDK="$HOME/flutter"
FLUTTER_VERSION="${FLUTTER_VERSION:-}"  # opcional, ej: 3.22.2

rm -rf "$FLUTTER_SDK"
git clone --depth 1 https://github.com/flutter/flutter.git "$FLUTTER_SDK"

if [[ -n "$FLUTTER_VERSION" ]]; then
  git -C "$FLUTTER_SDK" fetch --tags --depth 1
  # Intentamos checkout de la versión pedida (si existe)
  git -C "$FLUTTER_SDK" checkout "refs/tags/$FLUTTER_VERSION" || true
fi

export PATH="$FLUTTER_SDK/bin:$PATH"

flutter --version || true
flutter config --enable-web
flutter doctor -v || true

# --- Build ---
flutter clean
flutter pub get

# Pasar --web-renderer canvaskit sólo si la bandera existe
if flutter build web -h 2>&1 | grep -q -- "--web-renderer"; then
  flutter build web --release --web-renderer canvaskit
else
  flutter build web --release
fi
