#!/bin/bash

# Script para verificar las regiones disponibles en tu suscripción de Azure

set -e

echo "🔍 Verificando regiones disponibles en tu suscripción de Azure..."
echo ""

# Verificar si el usuario está autenticado
if ! az account show &> /dev/null; then
    echo "❌ No estás autenticado en Azure CLI"
    echo "Ejecuta: az login"
    exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "📋 Suscripción activa: $SUBSCRIPTION_ID"
echo ""

# Listar todas las regiones disponibles
echo "📍 Regiones disponibles para tu suscripción:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

az account list-locations \
  --query "[?metadata.regionType=='Physical'].{Name:name, DisplayName:displayName, Available:metadata.physicalLocation}" \
  -o table

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Regiones más comunes y recomendadas:"
echo "   • eastus         - East US (Virginia)"
echo "   • eastus2        - East US 2 (Virginia)"
echo "   • westus2        - West US 2 (Washington)"
echo "   • westeurope     - West Europe (Países Bajos)"
echo "   • northeurope    - North Europe (Irlanda)"
echo "   • southcentralus - South Central US (Texas)"
echo ""
echo "💡 Para cambiar la región en tu deployment:"
echo "   1. Edita src/infra-arm/azuredeploy.parameters.json"
echo "   2. Cambia el valor de 'location'"
echo "   3. Haz commit y push"
echo ""
