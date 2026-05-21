#!/bin/bash

# Script para solucionar errores comunes de deployment
# - Purgar Key Vaults en soft-delete
# - Eliminar recursos huérfanos
# - Preparar para deployment limpio

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   RapidGo - Solucionar Errores de Deployment              ║${NC}"
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

# ============================================================================
# 1. PURGAR KEY VAULTS EN SOFT-DELETE
# ============================================================================

echo -e "${BLUE}🔐 Buscando Key Vaults en soft-delete...${NC}"
echo ""

DELETED_KVS=$(az keyvault list-deleted --query "[?starts_with(name, 'az-') && contains(name, '-kv-')].name" -o tsv 2>/dev/null || echo "")

if [ -z "$DELETED_KVS" ]; then
    echo "   ✅ No hay Key Vaults en soft-delete"
else
    echo "   ⚠️  Key Vaults encontrados en soft-delete:"
    echo "$DELETED_KVS" | while read KV_NAME; do
        echo "      • $KV_NAME"
    done
    echo ""

    read -p "¿Purgar todos los Key Vaults en soft-delete? (y/n): " CONFIRM_KV

    if [ "$CONFIRM_KV" = "y" ]; then
        echo ""
        echo "$DELETED_KVS" | while read KV_NAME; do
            echo -e "   ${YELLOW}Purgando ${KV_NAME}...${NC}"
            if az keyvault purge --name "$KV_NAME" 2>/dev/null; then
                echo -e "      ${GREEN}✅ Purgado${NC}"
            else
                echo -e "      ${RED}❌ Error al purgar${NC}"
            fi
        done
    else
        echo -e "   ${YELLOW}⚠️  Key Vaults NO purgados - esto causará errores de deployment${NC}"
    fi
fi

echo ""

# ============================================================================
# 2. ELIMINAR RECURSOS HUÉRFANOS
# ============================================================================

echo -e "${BLUE}🗑️  Buscando recursos huérfanos de RapidGo...${NC}"
echo ""

# Buscar Storage Accounts
echo "📦 Storage Accounts:"
STORAGE_LIST=$(az storage account list \
  --query "[?starts_with(name, 'az') && (contains(name, 'blob') || contains(name, 'rapidgo'))].{Name:name, RG:resourceGroup, Location:location}" \
  -o json 2>/dev/null || echo "[]")

STORAGE_COUNT=$(echo "$STORAGE_LIST" | jq 'length')

if [ "$STORAGE_COUNT" -gt 0 ]; then
    echo "$STORAGE_LIST" | jq -r '.[] | "   • \(.Name) (RG: \(.RG), Location: \(.Location))"'
else
    echo "   ✅ No hay Storage Accounts huérfanos"
fi
echo ""

# Buscar Cosmos DB
echo "🗄️  Cosmos DB:"
COSMOS_LIST=$(az cosmosdb list \
  --query "[?starts_with(name, 'azrapidgo')].{Name:name, RG:resourceGroup, Location:location}" \
  -o json 2>/dev/null || echo "[]")

COSMOS_COUNT=$(echo "$COSMOS_LIST" | jq 'length')

if [ "$COSMOS_COUNT" -gt 0 ]; then
    echo "$COSMOS_LIST" | jq -r '.[] | "   • \(.Name) (RG: \(.RG), Location: \(.Location))"'
else
    echo "   ✅ No hay Cosmos DB huérfanos"
fi
echo ""

# Buscar Function Apps
echo "⚡ Function Apps:"
FUNC_LIST=$(az functionapp list \
  --query "[?starts_with(name, 'az-rapidgo-')].{Name:name, RG:resourceGroup, Location:location}" \
  -o json 2>/dev/null || echo "[]")

FUNC_COUNT=$(echo "$FUNC_LIST" | jq 'length')

if [ "$FUNC_COUNT" -gt 0 ]; then
    echo "$FUNC_LIST" | jq -r '.[] | "   • \(.Name) (RG: \(.RG), Location: \(.Location))"'
else
    echo "   ✅ No hay Function Apps huérfanos"
fi
echo ""

# Buscar APIM
echo "🌐 API Management:"
APIM_LIST=$(az apim list \
  --query "[?starts_with(name, 'az-rapidgo-')].{Name:name, RG:resourceGroup, Location:location}" \
  -o json 2>/dev/null || echo "[]")

APIM_COUNT=$(echo "$APIM_LIST" | jq 'length')

if [ "$APIM_COUNT" -gt 0 ]; then
    echo "$APIM_LIST" | jq -r '.[] | "   • \(.Name) (RG: \(.RG), Location: \(.Location))"'
else
    echo "   ✅ No hay API Management huérfanos"
fi
echo ""

# ============================================================================
# 3. ELIMINAR RESOURCE GROUPS DE RAPIDGO
# ============================================================================

echo -e "${BLUE}📦 Buscando Resource Groups de RapidGo...${NC}"
echo ""

RG_LIST=$(az group list --query "[?starts_with(name, 'az-rapidgo-')].{Name:name, Location:location}" -o json)
RG_COUNT=$(echo "$RG_LIST" | jq 'length')

if [ "$RG_COUNT" -gt 0 ]; then
    echo "   Resource Groups encontrados:"
    echo "$RG_LIST" | jq -r '.[] | "      • \(.Name) (Location: \(.Location))"'
    echo ""

    read -p "¿Eliminar TODOS los Resource Groups de RapidGo? (escribe 'DELETE-ALL' para confirmar): " CONFIRM_RG

    if [ "$CONFIRM_RG" = "DELETE-ALL" ]; then
        echo ""
        echo "$RG_LIST" | jq -r '.[].Name' | while read RG_NAME; do
            echo -e "   ${YELLOW}Eliminando ${RG_NAME}...${NC}"
            az group delete --name "$RG_NAME" --yes --no-wait
            echo -e "      ${GREEN}✅ Eliminación iniciada${NC}"
        done

        echo ""
        echo -e "${YELLOW}⏳ Esperando 30 segundos a que inicie la eliminación...${NC}"
        sleep 30
    else
        echo -e "   ${YELLOW}⚠️  Resource Groups NO eliminados${NC}"
    fi
else
    echo "   ✅ No hay Resource Groups de RapidGo"
fi

echo ""

# ============================================================================
# 4. RESUMEN
# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}✅ Limpieza completada${NC}"
echo ""
echo "Próximos pasos:"
echo ""
echo "1. Espera 5-10 minutos a que Azure complete las eliminaciones"
echo ""
echo "2. Verifica que todo esté limpio:"
echo "   ./scripts/list-deployments.sh"
echo ""
echo "3. Re-desplegar:"
echo "   git push --force-with-lease"
echo ""
echo "   O si prefieres cambiar el environment name para evitar conflictos:"
echo "   ./scripts/change-region.sh centralus"
echo "   nano src/infra-arm/azuredeploy.parameters.json"
echo "   # Cambiar environmentName de 'dev' a 'dev2'"
echo "   git add ."
echo "   git commit -m 'fix: limpiar y re-desplegar con nuevo environment'"
echo "   git push"
echo ""
