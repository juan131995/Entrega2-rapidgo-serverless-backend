#!/bin/bash

# Script para verificar el estado detallado del deployment actual

set -e

echo "======================================================"
echo "🔍 Azure Deployment Status Checker"
echo "======================================================"
echo ""

# Get the latest deployment info
echo "📋 Buscando el deployment más reciente..."
echo ""

# Find the latest resource group
LATEST_RG=$(az group list \
  --query "[?starts_with(name, 'rg-rapidgo-dev')].{Name:name, Created:properties.provisioningState}" \
  -o json | jq -r 'sort_by(.Name) | reverse | .[0].Name' 2>/dev/null || echo "")

if [ -z "$LATEST_RG" ]; then
  echo "❌ No se encontró ningún resource group de RapidGo"
  echo "   ¿El deployment ya fue limpiado?"
  exit 1
fi

echo "✅ Resource Group encontrado: $LATEST_RG"
echo ""

# Get latest deployment name (filter for main deployment, not nested ones)
DEPLOYMENT_NAME=$(az deployment group list \
  --resource-group "$LATEST_RG" \
  --query "[?starts_with(name, 'rapidgo-')] | [0].name" \
  -o tsv 2>/dev/null || echo "")

if [ -z "$DEPLOYMENT_NAME" ]; then
  echo "❌ No se encontró deployment en el resource group"
  exit 1
fi

echo "✅ Deployment: $DEPLOYMENT_NAME"
echo ""

# Get overall deployment state
echo "======================================================"
echo "📊 ESTADO GENERAL DEL DEPLOYMENT"
echo "======================================================"
az deployment group show \
  --resource-group "$LATEST_RG" \
  --name "$DEPLOYMENT_NAME" \
  --query "{Estado:properties.provisioningState, Timestamp:properties.timestamp, Duration:properties.duration}" \
  -o table

echo ""
echo "======================================================"
echo "🔧 ESTADO DE CADA RECURSO (detallado)"
echo "======================================================"

# Get individual resource operations
az deployment operation group list \
  --resource-group "$LATEST_RG" \
  --name "$DEPLOYMENT_NAME" \
  --query "[].{Recurso:properties.targetResource.resourceName, Tipo:properties.targetResource.resourceType, Estado:properties.provisioningState, Duracion:properties.duration}" \
  -o table

echo ""
echo "======================================================"
echo "⚠️  RECURSOS QUE ESTÁN TARDANDO MUCHO"
echo "======================================================"

# Find long-running operations
az deployment operation group list \
  --resource-group "$LATEST_RG" \
  --name "$DEPLOYMENT_NAME" \
  --query "[?properties.provisioningState=='Running'].{Recurso:properties.targetResource.resourceName, Tipo:properties.targetResource.resourceType, Inicio:properties.timestamp}" \
  -o table

echo ""
echo "======================================================"
echo "❌ ERRORES (si hay)"
echo "======================================================"

# Check for failures
FAILURES=$(az deployment operation group list \
  --resource-group "$LATEST_RG" \
  --name "$DEPLOYMENT_NAME" \
  --query "[?properties.provisioningState=='Failed']" \
  -o json)

if [ "$FAILURES" = "[]" ]; then
  echo "✅ No hay errores hasta el momento"
else
  echo "❌ Se encontraron errores:"
  echo "$FAILURES" | jq -r '.[] | "- \(.properties.targetResource.resourceName): \(.properties.statusMessage.error.message)"'
fi

echo ""
echo "======================================================"
echo "💡 RECOMENDACIONES"
echo "======================================================"

# Get current state
CURRENT_STATE=$(az deployment group show \
  --resource-group "$LATEST_RG" \
  --name "$DEPLOYMENT_NAME" \
  --query "properties.provisioningState" \
  -o tsv)

if [ "$CURRENT_STATE" = "Running" ]; then
  echo "✅ El deployment está progresando normalmente"
  echo ""
  echo "   API Management tarda típicamente:"
  echo "   - Developer tier: 30-50 minutos"
  echo "   - Basic/Standard: 45-90 minutos"
  echo ""
  echo "   👉 Espera otros 15-20 minutos y vuelve a ejecutar este script"
  echo "   👉 Comando: ./scripts/check-deployment-status.sh"
elif [ "$CURRENT_STATE" = "Succeeded" ]; then
  echo "🎉 ¡DEPLOYMENT COMPLETADO EXITOSAMENTE!"
  echo ""
  echo "   Próximos pasos:"
  echo "   1. Verifica los recursos en Azure Portal"
  echo "   2. Deploya el código de las Functions"
  echo "   3. Prueba los endpoints"
elif [ "$CURRENT_STATE" = "Failed" ]; then
  echo "❌ DEPLOYMENT FALLÓ"
  echo ""
  echo "   Ver detalles completos del error:"
  echo "   az deployment group show \\"
  echo "     --resource-group $LATEST_RG \\"
  echo "     --name $DEPLOYMENT_NAME \\"
  echo "     --query properties.error -o json | jq ."
else
  echo "⚠️  Estado desconocido: $CURRENT_STATE"
fi

echo ""
echo "======================================================"
