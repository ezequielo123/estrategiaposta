#!/usr/bin/env bash
set -euo pipefail

echo "=========================="
echo " Netlify: Flutter Web Build"
echo " CWD: $(pwd)"
echo " FLUTTER_VERSION=${FLUTTER_VERSION:-<none>}"
echo "=========================="

# Ruta del SDK dentro del repo (Netlify [build.base] apunta a client/)
ROOT="$(pwd)"
FLUTTER_SDK="$ROOT/.flutter"

echo "→ Clonando Flutter SDK en $FLUTTER_SDK"
rm -rf "$FLUTTER_SDK"
git clone https://github.com/flutter/flutter.git "$FLUTTER_SDK"

# Soportar canales (stable/beta/dev/master) y tags (3.x.x, etc.)
CHANNELS=("stable" "beta" "dev" "master")
if [[ -z "${FLUTTER_VERSION:-}" ]]; then
  echo "→ FLUTTER_VERSION no seteada, usando canal 'stable'"
  git -C "$FLUTTER_SDK" checkout stable
  git -C "$FLUTTER_SDK" pull --ff-only
else
  if [[ " ${CHANNELS[*]} " =~ " ${FLUTTER_VERSION} " ]]; then
    echo "→ Usando canal '${FLUTTER_VERSION}'"
    git -C "$FLUTTER_SDK" checkout "$FLUTTER_VERSION"
    git -C "$FLUTTER_SDK" pull --ff-only
  else
    echo "→ Usando tag '${FLUTTER_VERSION}'"
    git -C "$FLUTTER_SDK" fetch --tags
    git -C "$FLUTTER_SDK" checkout "refs/tags/$FLUTTER_VERSION" || \
    git -C "$FLUTTER_SDK" checkout "$FLUTTER_VERSION"
  fi
fi

export PATH="$FLUTTER_SDK/bin:$PATH"
export PUB_CACHE="$ROOT/.pub-cache"

echo "→ Versión de Flutter:"
flutter --version

echo "→ Habilitando web"
flutter config --enable-web

echo "→ Resolviendo dependencias"
flutter pub get

echo "→ Compilando Web (release)"
# No pasamos --web-renderer para evitar errores en hosts que no lo reconocen
flutter build web --release

# Copiar redirects de SPA si existen
if [[ -f "web/_redirects" ]]; then
  echo "→ Copiando web/_redirects → build/web/_redirects"
  cp -f web/_redirects build/web/_redirects
fi

echo "✅ Build terminado. Output: $ROOT/build/web"
