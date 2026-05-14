#!/bin/bash

# Script para listar deployments y resource groups de RapidGo

set -e

# Colores
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   RapidGo - Estado de Deployments Azure                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar autenticación
if ! az account show &> /dev/null; then
    echo "❌ No estás autenticado en Azure CLI"
    echo "Ejecuta: az login"
    exit 1
fi

SUBSCRIPTION=$(az account show --query name -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

echo -e "${GREEN}✅ Suscripción activa: ${SUBSCRIPTION}${NC}"
echo "   ID: ${SUBSCRIPTION_ID}"
echo ""

# Listar todos los resource groups de RapidGo
echo -e "${BLUE}📦 Resource Groups de RapidGo:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RG_LIST=$(az group list --query "[?starts_with(name, 'az-rapidgo-')].{Name:name, Location:location, Environment:tags.environment}" -o table)

if [ -z "$RG_LIST" ] || [ "$RG_LIST" == "[]" ]; then
    echo "   (No se encontraron resource groups de RapidGo)"
else
    echo "$RG_LIST"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Listar deployments por cada resource group
for RG in $(az group list --query "[?starts_with(name, 'az-rapidgo-')].name" -o tsv); do
    echo -e "${YELLOW}📋 Deployments en: ${RG}${NC}"

    # Contar recursos
    RESOURCE_COUNT=$(az resource list --resource-group "$RG" --query "length([])" -o tsv)
    echo "   Recursos: ${RESOURCE_COUNT}"

    # Listar últimos 5 deployments
    DEPLOYMENTS=$(az deployment group list --resource-group "$RG" --query "[0:5].{Name:name, State:properties.provisioningState, Timestamp:properties.timestamp}" -o table 2>/dev/null)

    if [ -n "$DEPLOYMENTS" ]; then
        echo ""
        echo "$DEPLOYMENTS"
    else
        echo "   (No hay deployments registrados)"
    fi

    echo ""
done

# Resumen
echo -e "${BLUE}📊 Resumen:${NC}"
RG_COUNT=$(az group list --query "[?starts_with(name, 'az-rapidgo-')].name" -o tsv | wc -l | tr -d ' ')
echo "   • Total Resource Groups: ${RG_COUNT}"

echo ""
echo -e "${GREEN}💡 Comandos útiles:${NC}"
echo "   • Ver recursos en un RG específico:"
echo "     az resource list --resource-group <nombre-rg> -o table"
echo ""
echo "   • Ver detalles de un deployment:"
echo "     az deployment group show --resource-group <rg> --name <deployment-name>"
echo ""
echo "   • Eliminar un resource group:"
echo "     ./scripts/rollback-deployment.sh <environment>"
echo ""
