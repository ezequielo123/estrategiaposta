#!/bin/bash

echo "🚀 Iniciando configuración de Firebase..."

# 1. Login si no lo hiciste
firebase login

# 2. Inicializar Firebase en el proyecto actual
firebase init firestore --project estrategia --token "$(firebase login:ci)"

# 3. Subir reglas de seguridad
firebase deploy --only firestore:rules

# 4. Confirmación
echo "✅ Firebase configurado y reglas subidas exitosamente."
