#!/bin/bash

# Script para limpiar recursos existentes y volver a desplegar con nombres únicos
# Uso: ./scripts/cleanup-and-redeploy.sh [dev|nonprod|prod]

set -e

ENV_NAME="${1:-dev}"
RG_NAME="az-rapidgo-${ENV_NAME}-rg"

echo "========================================="
echo "Limpieza y Re-despliegue - Entorno: $ENV_NAME"
echo "========================================="
echo ""

# Verificar login
if ! az account show &> /dev/null; then
    echo "Error: No estás autenticado en Azure"
    echo "Ejecuta: az login"
    exit 1
fi

# Verificar si el resource group existe
if az group exists --name "$RG_NAME" | grep -q "true"; then
    echo "✓ Resource group encontrado: $RG_NAME"
    echo ""

    # Listar recursos
    echo "Recursos actuales:"
    az resource list --resource-group "$RG_NAME" --query "[].{Name:name, Type:type}" -o table
    echo ""

    # Confirmación
    read -p "¿Deseas eliminar este Resource Group y todos sus recursos? (yes/no): " CONFIRM

    if [ "$CONFIRM" != "yes" ]; then
        echo "Operación cancelada"
        exit 0
    fi

    echo ""
    echo "Eliminando Resource Group: $RG_NAME"
    az group delete --name "$RG_NAME" --yes --no-wait

    echo "Esperando a que se complete la eliminación..."
    for i in {1..60}; do
        if ! az group exists --name "$RG_NAME" | grep -q "true"; then
            echo "✓ Resource Group eliminado exitosamente"
            break
        fi
        echo -n "."
        sleep 5
    done
    echo ""
else
    echo "Resource Group no existe: $RG_NAME"
fi

# Buscar y eliminar resource groups "managed" de Application Insights
echo ""
echo "Buscando resource groups 'managed' de Application Insights..."
MANAGED_RGS=$(az group list --query "[?contains(name, 'managed') && contains(name, 'insights')].name" -o tsv)

if [ -n "$MANAGED_RGS" ]; then
    echo "Resource groups 'managed' encontrados:"
    echo "$MANAGED_RGS"
    echo ""
    read -p "¿Deseas eliminar estos resource groups? (yes/no): " CONFIRM_MANAGED

    if [ "$CONFIRM_MANAGED" == "yes" ]; then
        while IFS= read -r MANAGED_RG; do
            echo "Eliminando: $MANAGED_RG"
            az group delete --name "$MANAGED_RG" --yes --no-wait
        done <<< "$MANAGED_RGS"
        echo "✓ Eliminación de resource groups 'managed' iniciada"
    fi
else
    echo "No se encontraron resource groups 'managed'"
fi

echo ""
echo "========================================="
echo "Ahora puedes ejecutar el workflow de GitHub Actions:"
echo "1. Ve a: https://github.com/TU_USUARIO/TU_REPO/actions"
echo "2. Selecciona 'Deploy Infrastructure - ARM Templates'"
echo "3. Click en 'Run workflow'"
echo "4. Selecciona el entorno: $ENV_NAME"
echo "5. Escribe 'yes' para confirmar"
echo "========================================="
