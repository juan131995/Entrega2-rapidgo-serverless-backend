#!/bin/bash

# Script para probar si una región específica funciona con el deployment

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   RapidGo - Probar Región de Azure                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar parámetro
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: Debes especificar una región${NC}"
    echo ""
    echo "Uso: $0 <region>"
    echo ""
    echo "Regiones comunes para Azure Student:"
    echo "  • centralus      - Central US (Iowa)"
    echo "  • westus         - West US (California)"
    echo "  • westus2        - West US 2 (Washington)"
    echo "  • southcentralus - South Central US (Texas)"
    echo "  • northeurope    - North Europe (Irlanda)"
    echo "  • westeurope     - West Europe (Países Bajos)"
    echo ""
    echo "Ejemplo:"
    echo "  $0 centralus"
    exit 1
fi

REGION="$1"
RG_NAME="az-rapidgo-test-rg"

echo -e "${YELLOW}🔍 Probando región: ${REGION}${NC}"
echo ""

# Verificar autenticación
if ! az account show &> /dev/null; then
    echo -e "${RED}❌ No estás autenticado en Azure CLI${NC}"
    echo "Ejecuta: az login"
    exit 1
fi

SUBSCRIPTION=$(az account show --query name -o tsv)
echo -e "${GREEN}✅ Suscripción: ${SUBSCRIPTION}${NC}"
echo ""

# Crear resource group de prueba
echo -e "${BLUE}📦 Creando Resource Group de prueba...${NC}"

if az group exists --name "$RG_NAME" | grep -q "true"; then
    echo "   Eliminando RG existente..."
    az group delete --name "$RG_NAME" --yes --no-wait
    sleep 5
fi

if az group create --name "$RG_NAME" --location "$REGION" &>/dev/null; then
    echo -e "   ${GREEN}✅ Resource Group creado en: ${REGION}${NC}"
else
    echo -e "   ${RED}❌ No se pudo crear Resource Group en: ${REGION}${NC}"
    echo ""
    echo -e "${YELLOW}Esta región probablemente NO está permitida en tu suscripción${NC}"
    exit 1
fi

echo ""

# Probar creación de Storage Account (recurso simple)
echo -e "${BLUE}💾 Probando creación de Storage Account...${NC}"

STORAGE_NAME="aztest$(date +%s | tail -c 8)"

if az storage account create \
    --name "$STORAGE_NAME" \
    --resource-group "$RG_NAME" \
    --location "$REGION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --query "provisioningState" -o tsv 2>/dev/null | grep -q "Succeeded"; then

    echo -e "   ${GREEN}✅ Storage Account creado exitosamente${NC}"
else
    echo -e "   ${RED}❌ Storage Account falló${NC}"
    echo ""
    echo -e "${YELLOW}Esta región NO está permitida para Storage en tu suscripción${NC}"

    # Limpiar
    az group delete --name "$RG_NAME" --yes --no-wait
    exit 1
fi

echo ""

# Probar creación de Cosmos DB (recurso más restrictivo)
echo -e "${BLUE}🗄️  Probando creación de Cosmos DB...${NC}"

COSMOS_NAME="aztest${STORAGE_NAME}"

if az cosmosdb create \
    --name "$COSMOS_NAME" \
    --resource-group "$RG_NAME" \
    --location "$REGION" \
    --kind GlobalDocumentDB \
    --enable-free-tier true \
    --query "provisioningState" -o tsv 2>/dev/null | grep -q "Succeeded"; then

    echo -e "   ${GREEN}✅ Cosmos DB creado exitosamente${NC}"
else
    echo -e "   ${YELLOW}⚠️  Cosmos DB falló (puede ser por free tier ya usado)${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}✅ LA REGIÓN '${REGION}' FUNCIONA CORRECTAMENTE${NC}"
echo ""
echo "Para usar esta región en tu deployment:"
echo ""
echo "1. Edita src/infra-arm/azuredeploy.parameters.json:"
echo "   \"location\": { \"value\": \"${REGION}\" }"
echo ""
echo "2. Commit y push:"
echo "   git add ."
echo "   git commit -m \"fix: cambiar región a ${REGION}\""
echo "   git push"
echo ""

# Limpiar recursos de prueba
echo -e "${BLUE}🧹 Limpiando recursos de prueba...${NC}"
az group delete --name "$RG_NAME" --yes --no-wait

echo ""
echo -e "${GREEN}✅ Prueba completada${NC}"
