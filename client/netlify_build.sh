#!/usr/bin/env bash
set -euo pipefail

echo "PWD: $(pwd)"   # debe ser .../repo/client

# --- Flutter SDK (instalar si no está disponible en el build) ---
FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"
FLUTTER_SDK="$HOME/flutter"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Instalando Flutter ($FLUTTER_CHANNEL) en $FLUTTER_SDK..."
  git clone --depth 1 -b "$FLUTTER_CHANNEL" https://github.com/flutter/flutter.git "$FLUTTER_SDK"
fi

export PATH="$FLUTTER_SDK/bin:$PATH"

flutter --version || true
flutter config --enable-web

# --- Build ---
flutter clean
flutter pub get
flutter build web --release --web-renderer=canvaskit --pwa-strategy=none
