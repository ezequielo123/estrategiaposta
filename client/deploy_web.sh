#!/bin/bash

echo "🚧 Compilando Flutter Web..."
flutter build web

if [ $? -ne 0 ]; then
  echo "❌ Error al compilar el proyecto"
  exit 1
fi

echo "🚀 Haciendo deploy a Firebase Hosting..."
firebase deploy

if [ $? -eq 0 ]; then
  echo "✅ Deploy exitoso"
else
  echo "❌ Error durante el deploy"
  exit 1
fi
