#!/bin/bash

# Script para hacer rollback manual del despliegue de infraestructura

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   RapidGo - Rollback de Infraestructura Azure             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar autenticación
if ! az account show &> /dev/null; then
    echo -e "${RED}❌ No estás autenticado en Azure CLI${NC}"
    echo "Ejecuta: az login"
    exit 1
fi

# Obtener el environment
ENVIRONMENT="${1:-dev}"
RG_NAME="az-rapidgo-${ENVIRONMENT}-rg"

echo -e "${YELLOW}🔍 Verificando grupo de recursos: ${RG_NAME}${NC}"
echo ""

# Verificar si el grupo de recursos existe
if ! az group exists --name "$RG_NAME" | grep -q "true"; then
    echo -e "${GREEN}✅ El grupo de recursos no existe, no se requiere rollback${NC}"
    exit 0
fi

# Mostrar información del grupo de recursos
RG_LOCATION=$(az group show --name "$RG_NAME" --query location -o tsv)
RG_TAGS=$(az group show --name "$RG_NAME" --query tags -o json)

echo -e "${BLUE}📋 Información del Resource Group:${NC}"
echo "   • Nombre: $RG_NAME"
echo "   • Región: $RG_LOCATION"
echo "   • Tags: $RG_TAGS"
echo ""

# Listar recursos
echo -e "${BLUE}📦 Recursos que serán eliminados:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
az resource list --resource-group "$RG_NAME" --query "[].{Name:name, Type:type, Location:location}" -o table
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Contar recursos
RESOURCE_COUNT=$(az resource list --resource-group "$RG_NAME" --query "length([])" -o tsv)

if [ "$RESOURCE_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  El grupo de recursos está vacío${NC}"
else
    echo -e "${RED}⚠️  Se eliminarán ${RESOURCE_COUNT} recurso(s)${NC}"
fi

echo ""

# Confirmación interactiva
read -p "¿Deseas continuar con la eliminación? (escribe 'yes' para confirmar): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}❌ Rollback cancelado${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}🚀 Iniciando eliminación del grupo de recursos...${NC}"
echo ""

# Ejecutar eliminación
if az group delete --name "$RG_NAME" --yes --no-wait; then
    echo -e "${GREEN}✅ Rollback iniciado exitosamente${NC}"
    echo ""
    echo -e "${BLUE}ℹ️  La eliminación se ejecuta en background y puede tardar varios minutos${NC}"
    echo ""
    echo "Para verificar el estado:"
    echo "  az group exists --name $RG_NAME"
    echo ""
    echo "Para listar todos los deployments en tu suscripción:"
    echo "  az group list --query \"[].{Name:name, Location:location}\" -o table"
else
    echo -e "${RED}❌ Error al ejecutar el rollback${NC}"
    exit 1
fi
