#!/bin/bash
set -e

echo "🧹 FORCE CLEAN DEPLOY - RapidGo"
echo "================================"
echo ""

# 1. Eliminar TODOS los resource groups de rapidgo
echo "1️⃣ Limpiando resource groups existentes..."
RGS=$(az group list --query "[?contains(name, 'rapidgo')].name" -o tsv)

if [ -z "$RGS" ]; then
  echo "✅ No hay resource groups existentes"
else
  for RG in $RGS; do
    echo "   🗑️  Eliminando: $RG"
    az group delete --name "$RG" --yes --no-wait
  done
  
  echo ""
  echo "⏳ Esperando 30 segundos para que Azure procese las eliminaciones..."
  sleep 30
fi

echo ""
echo "2️⃣ Purgar recursos soft-deleted..."

# Purgar API Management
echo "   - API Management..."
DELETED_APIMS=$(az rest \
  --method get \
  --url "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/providers/Microsoft.ApiManagement/deletedservices?api-version=2023-05-01-preview" \
  --query "value[].{name:name, location:location}" \
  -o json 2>/dev/null || echo "[]")

APIM_COUNT=$(echo "$DELETED_APIMS" | jq '. | length')
if [ "$APIM_COUNT" -gt 0 ]; then
  echo "$DELETED_APIMS" | jq -c '.[]' | while read -r apim; do
    APIM_NAME=$(echo "$apim" | jq -r '.name')
    APIM_LOCATION=$(echo "$apim" | jq -r '.location')
    
    if [ "$APIM_NAME" != "null" ] && [ "$APIM_LOCATION" != "null" ]; then
      echo "     Purgando: $APIM_NAME"
      az rest \
        --method delete \
        --url "https://management.azure.com/subscriptions/$(az account show --query id -o tsv)/providers/Microsoft.ApiManagement/locations/${APIM_LOCATION}/deletedservices/${APIM_NAME}?api-version=2023-05-01-preview" \
        || echo "     ⚠️  Error purgando $APIM_NAME"
    fi
  done
fi

# Purgar Key Vaults
echo "   - Key Vaults..."
DELETED_KVS=$(az keyvault list-deleted --query "[].name" -o tsv 2>/dev/null || echo "")
if [ ! -z "$DELETED_KVS" ]; then
  for KV_NAME in $DELETED_KVS; do
    KV_LOCATION=$(az keyvault list-deleted --query "[?name=='$KV_NAME'].properties.location" -o tsv)
    echo "     Purgando: $KV_NAME"
    az keyvault purge --name "$KV_NAME" --location "$KV_LOCATION" || echo "     ⚠️  Error purgando $KV_NAME"
  done
fi

echo ""
echo "3️⃣ Crear nuevo resource group..."
RANDOM_SUFFIX=$(openssl rand -hex 3 | tr '[:upper:]' '[:lower:]')
TIMESTAMP=$(date +%y%m%d%H%M)
NEW_SUFFIX="${TIMESTAMP}${RANDOM_SUFFIX}"
RG_NAME="rg-rapidgo-dev-${NEW_SUFFIX}"
LOCATION="centralus"

az group create \
  --name "$RG_NAME" \
  --location "$LOCATION" \
  --tags environment=dev managedBy=manual

echo ""
echo "✅ Resource group creado: $RG_NAME"
echo ""
echo "4️⃣ Desplegando infraestructura..."
echo ""

DEPLOYMENT_NAME="rapidgo-dev-$(date +%Y%m%d-%H%M%S)"

cd "$(dirname "$0")/../src/infra-arm"

az deployment group create \
  --resource-group "$RG_NAME" \
  --name "$DEPLOYMENT_NAME" \
  --template-file main.json \
  --parameters @azuredeploy.parameters.json \
  --parameters environmentName=dev \
  --parameters randomSuffix="$NEW_SUFFIX" \
  --mode Incremental \
  --no-wait

echo ""
echo "🚀 Deployment iniciado: $DEPLOYMENT_NAME"
echo "📊 Monitorear progreso:"
echo ""
echo "   az deployment group show \\"
echo "     --resource-group $RG_NAME \\"
echo "     --name $DEPLOYMENT_NAME \\"
echo "     --query properties.provisioningState"
echo ""
echo "💾 Guardar para referencia:"
echo "   export RG_NAME=$RG_NAME"
echo "   export DEPLOYMENT_NAME=$DEPLOYMENT_NAME"
echo ""
