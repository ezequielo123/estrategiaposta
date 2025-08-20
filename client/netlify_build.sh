#!/usr/bin/env bash
set -euxo pipefail   # ← agrega -x para log detallado

echo "PWD: $(pwd)"   # Debe ser .../repo/client

FLUTTER_SDK="$HOME/flutter"
FLUTTER_VERSION="${FLUTTER_VERSION:-}"

rm -rf "$FLUTTER_SDK"
git clone https://github.com/flutter/flutter.git "$FLUTTER_SDK"
if [[ -n "$FLUTTER_VERSION" ]]; then
  git -C "$FLUTTER_SDK" fetch --tags
  git -C "$FLUTTER_SDK" checkout "refs/tags/$FLUTTER_VERSION"
else
  git -C "$FLUTTER_SDK" checkout stable
  git -C "$FLUTTER_SDK" pull --ff-only
  git -C "$FLUTTER_SDK" fetch --tags
fi

export PATH="$FLUTTER_SDK/bin:$PATH"

flutter --version
flutter config --enable-web
flutter precache --web || true
flutter doctor -v || true

flutter clean
flutter pub get -v     # ← VERBOSE para detectar la dependencia faltante

if flutter build web -h 2>&1 | grep -q -- "--web-renderer"; then
  flutter build web --release --web-renderer canvaskit
else
  flutter build web --release
fi
