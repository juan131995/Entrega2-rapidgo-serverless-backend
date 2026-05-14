#!/bin/bash

# Script para limpiar recursos huérfanos de RapidGo que quedaron fuera del Resource Group

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   RapidGo - Limpieza de Recursos Huérfanos                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
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

echo -e "${YELLOW}🔍 Buscando recursos huérfanos de RapidGo...${NC}"
echo ""

FOUND_ORPHANS=false

# Buscar Storage Accounts huérfanos
echo -e "${BLUE}📦 Storage Accounts:${NC}"
ORPHANED_STORAGE=$(az storage account list \
  --query "[?starts_with(name, 'az') && (contains(name, 'blob') || contains(name, 'rapidgo'))].{Name:name, RG:resourceGroup, Location:location}" \
  -o json)

STORAGE_COUNT=$(echo "$ORPHANED_STORAGE" | jq 'length')

if [ "$STORAGE_COUNT" -gt 0 ]; then
    FOUND_ORPHANS=true
    echo "$ORPHANED_STORAGE" | jq -r '.[] | "   • \(.Name) (RG: \(.RG), Location: \(.Location))"'
else
    echo "   (No se encontraron Storage Accounts huérfanos)"
fi
echo ""

# Buscar Cosmos DB huérfanos
echo -e "${BLUE}🗄️  Cosmos DB:${NC}"
ORPHANED_COSMOS=$(az cosmosdb list \
  --query "[?starts_with(name, 'azrapidgo')].{Name:name, RG:resourceGroup, Location:location}" \
  -o json)

COSMOS_COUNT=$(echo "$ORPHANED_COSMOS" | jq 'length')

if [ "$COSMOS_COUNT" -gt 0 ]; then
    FOUND_ORPHANS=true
    echo "$ORPHANED_COSMOS" | jq -r '.[] | "   • \(.Name) (RG: \(.RG), Location: \(.Location))"'
else
    echo "   (No se encontraron Cosmos DB huérfanos)"
fi
echo ""

# Buscar Key Vaults huérfanos
echo -e "${BLUE}🔐 Key Vaults:${NC}"
ORPHANED_KV=$(az keyvault list \
  --query "[?starts_with(name, 'az-') && contains(name, '-kv-')].{Name:name, RG:resourceGroup, Location:location}" \
  -o json)

KV_COUNT=$(echo "$ORPHANED_KV" | jq 'length')

if [ "$KV_COUNT" -gt 0 ]; then
    FOUND_ORPHANS=true
    echo "$ORPHANED_KV" | jq -r '.[] | "   • \(.Name) (RG: \(.RG), Location: \(.Location))"'
else
    echo "   (No se encontraron Key Vaults huérfanos)"
fi
echo ""

# Buscar API Management huérfanos
echo -e "${BLUE}🌐 API Management:${NC}"
ORPHANED_APIM=$(az apim list \
  --query "[?starts_with(name, 'az-rapidgo-')].{Name:name, RG:resourceGroup, Location:location}" \
  -o json 2>/dev/null || echo "[]")

APIM_COUNT=$(echo "$ORPHANED_APIM" | jq 'length')

if [ "$APIM_COUNT" -gt 0 ]; then
    FOUND_ORPHANS=true
    echo "$ORPHANED_APIM" | jq -r '.[] | "   • \(.Name) (RG: \(.RG), Location: \(.Location))"'
else
    echo "   (No se encontraron API Management huérfanos)"
fi
echo ""

# Si no hay huérfanos, salir
if [ "$FOUND_ORPHANS" = false ]; then
    echo -e "${GREEN}✅ No se encontraron recursos huérfanos${NC}"
    exit 0
fi

# Confirmación
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${RED}⚠️  ADVERTENCIA: Estos recursos pueden estar en uso en otros Resource Groups${NC}"
echo ""
read -p "¿Deseas eliminar TODOS los recursos huérfanos? (escribe 'DELETE-ALL' para confirmar): " CONFIRM

if [ "$CONFIRM" != "DELETE-ALL" ]; then
    echo -e "${YELLOW}❌ Limpieza cancelada${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}🗑️  Eliminando recursos huérfanos...${NC}"
echo ""

# Eliminar Storage Accounts
if [ "$STORAGE_COUNT" -gt 0 ]; then
    echo -e "${BLUE}Eliminando Storage Accounts...${NC}"
    echo "$ORPHANED_STORAGE" | jq -r '.[] | "\(.Name) \(.RG)"' | while read NAME RG; do
        echo "   Eliminando $NAME..."
        az storage account delete --name "$NAME" --resource-group "$RG" --yes 2>/dev/null || echo "   ⚠️  Error al eliminar $NAME"
    done
fi

# Eliminar Cosmos DB
if [ "$COSMOS_COUNT" -gt 0 ]; then
    echo -e "${BLUE}Eliminando Cosmos DB...${NC}"
    echo "$ORPHANED_COSMOS" | jq -r '.[] | "\(.Name) \(.RG)"' | while read NAME RG; do
        echo "   Eliminando $NAME..."
        az cosmosdb delete --name "$NAME" --resource-group "$RG" --yes 2>/dev/null || echo "   ⚠️  Error al eliminar $NAME"
    done
fi

# Eliminar Key Vaults
if [ "$KV_COUNT" -gt 0 ]; then
    echo -e "${BLUE}Eliminando Key Vaults...${NC}"
    echo "$ORPHANED_KV" | jq -r '.[] | "\(.Name) \(.RG)"' | while read NAME RG; do
        echo "   Eliminando $NAME..."
        az keyvault delete --name "$NAME" --resource-group "$RG" 2>/dev/null || echo "   ⚠️  Error al eliminar $NAME"
        # Purgar Key Vault eliminado (soft delete)
        az keyvault purge --name "$NAME" 2>/dev/null || echo "   ⚠️  No se pudo purgar $NAME (puede estar en soft delete)"
    done
fi

# Eliminar API Management
if [ "$APIM_COUNT" -gt 0 ]; then
    echo -e "${BLUE}Eliminando API Management (puede tardar varios minutos)...${NC}"
    echo "$ORPHANED_APIM" | jq -r '.[] | "\(.Name) \(.RG)"' | while read NAME RG; do
        echo "   Eliminando $NAME..."
        az apim delete --name "$NAME" --resource-group "$RG" --yes --no-wait 2>/dev/null || echo "   ⚠️  Error al eliminar $NAME"
    done
fi

echo ""
echo -e "${GREEN}✅ Limpieza completada${NC}"
echo ""
echo -e "${YELLOW}ℹ️  Nota: Algunos recursos (API Management) pueden tardar varios minutos en eliminarse completamente${NC}"
