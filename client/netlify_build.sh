#!/usr/bin/env bash
set -euo pipefail

echo "PWD: $(pwd)"   # Debe ser .../repo/client en Netlify

# --- Instalar Flutter estable con tags (evita 0.0.0-unknown) ---
FLUTTER_SDK="$HOME/flutter"
FLUTTER_VERSION="${FLUTTER_VERSION:-}"  # opcional, ej: 3.22.2

rm -rf "$FLUTTER_SDK"
git clone https://github.com/flutter/flutter.git "$FLUTTER_SDK"

if [[ -n "$FLUTTER_VERSION" ]]; then
  # Chequeo a un tag conocido (recomendado)
  git -C "$FLUTTER_SDK" fetch --tags
  git -C "$FLUTTER_SDK" checkout "refs/tags/$FLUTTER_VERSION"
else
  # O usar canal estable (con tags)
  git -C "$FLUTTER_SDK" checkout stable
  git -C "$FLUTTER_SDK" pull --ff-only
  git -C "$FLUTTER_SDK" fetch --tags
fi

export PATH="$FLUTTER_SDK/bin:$PATH"

flutter --version
flutter config --enable-web
flutter precache --web || true
flutter doctor -v || true

# --- Build ---
flutter clean
flutter pub get

# Usa canvaskit si la opción existe en esta versión
if flutter build web -h 2>&1 | grep -q -- "--web-renderer"; then
  flutter build web --release --web-renderer canvaskit
else
  flutter build web --release
fi
