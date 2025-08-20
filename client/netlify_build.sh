#!/usr/bin/env bash
set -euo pipefail

echo "→ Working dir: $(pwd)"
ls -la || true

# Asegurá que estamos parados en el proyecto Flutter (donde vive pubspec.yaml)
if [[ ! -f "pubspec.yaml" ]]; then
  if [[ -f "client/pubspec.yaml" ]]; then
    echo "→ Encontré proyecto en client/, moviéndome allí"
    cd client
  else
    echo "✗ No encuentro pubspec.yaml en $(pwd)"
    exit 1
  fi
fi

# Instalar/rehusar Flutter (estable) en caché
FLUTTER_ROOT="$HOME/flutter-sdk"
if [[ ! -x "$FLUTTER_ROOT/bin/flutter" ]]; then
  echo "→ Instalando Flutter stable en $FLUTTER_ROOT"
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_ROOT"
else
  echo "→ Reusando Flutter en $FLUTTER_ROOT"
  (cd "$FLUTTER_ROOT" && git fetch --depth 1 origin stable && git checkout -f stable)
fi
export PATH="$FLUTTER_ROOT/bin:$PATH"

flutter --version
flutter config --enable-web

# Dependencias + build
flutter pub get
flutter build web --release

# Comprobación de salida
test -d build/web || (echo "✗ build/web no existe" && exit 2)
echo "✓ Build OK. Output: $(pwd)/build/web"
