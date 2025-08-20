#!/usr/bin/env bash
set -euxo pipefail

# Directorio del client (este script vive en client/, pero por seguridad)
cd "$(dirname "$0")"

# 1) Instalar Flutter (cache local en Netlify)
FLUTTER_VERSION="3.22.3"
if [ ! -d "$HOME/flutter" ]; then
  git clone --depth 1 -b "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$HOME/flutter"
fi
export PATH="$HOME/flutter/bin:$PATH"

flutter --version
flutter config --enable-web

# 2) Dependencias de Dart/Flutter
flutter pub get

# 3) Build web (canvasKit para mayor compatibilidad)
flutter build web --release --web-renderer canvaskit

# 4) Asegurar redirects SPA (opcional si ya lo tenés en web/_redirects)
mkdir -p build/web
if [ ! -f build/web/_redirects ]; then
  echo '/* /index.html 200' > build/web/_redirects
fi

# 5) Listar salida para debug
ls -lah build/web
