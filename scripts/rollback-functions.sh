#!/bin/bash

# Script para hacer rollback manual de funciones
# Uso: ./scripts/rollback-functions.sh [dev|nonprod|prod]

set -e

ENV_NAME="${1:-dev}"
RG_NAME="az-rapidgo-${ENV_NAME}-rg"

echo "========================================="
echo "Function App Rollback - Entorno: $ENV_NAME"
echo "========================================="
echo ""

# Verificar login
if ! az account show &> /dev/null; then
    echo "Error: No estás autenticado en Azure"
    echo "Ejecuta: az login"
    exit 1
fi

# Obtener nombre de la Function App
APP_NAME=$(az functionapp list --resource-group "$RG_NAME" --query "[0].name" -o tsv)

if [ -z "$APP_NAME" ]; then
    echo "Error: No se encontró Function App en el resource group $RG_NAME"
    exit 1
fi

echo "Function App encontrada: $APP_NAME"
echo ""

# Mostrar deployments recientes
echo "Deployments recientes:"
echo "----------------------------------------"
az webapp deployment list --name "$APP_NAME" --resource-group "$RG_NAME" \
  --query "[0:10].{ID:id, Status:status, Author:author, Message:message, Time:start_time}" \
  -o table 2>/dev/null || echo "No se pudieron obtener deployments previos"
echo ""

# Verificar estado actual
CURRENT_STATE=$(az functionapp show --name "$APP_NAME" --resource-group "$RG_NAME" --query "state" -o tsv)
echo "Estado actual de la Function App: $CURRENT_STATE"
echo ""

# Menú de opciones de rollback
echo "Opciones de Rollback:"
echo "1. Reiniciar Function App (soft reset)"
echo "2. Re-desplegar código desde package actual"
echo "3. Ver logs de deployment"
echo "4. Ver logs en tiempo real"
echo "5. Verificar health endpoints"
echo "6. Cancelar"
echo ""

read -p "Selecciona una opción (1-6): " OPTION

case $OPTION in
  1)
    echo ""
    echo "Reiniciando Function App..."
    az functionapp restart --name "$APP_NAME" --resource-group "$RG_NAME"
    echo "✓ Function App reiniciada"
    echo ""
    echo "Esperando 30 segundos..."
    sleep 30
    NEW_STATE=$(az functionapp show --name "$APP_NAME" --resource-group "$RG_NAME" --query "state" -o tsv)
    echo "Nuevo estado: $NEW_STATE"
    ;;

  2)
    echo ""
    echo "Re-desplegando desde el package actual..."
    az functionapp deployment source sync --name "$APP_NAME" --resource-group "$RG_NAME"
    echo "✓ Re-deployment iniciado"
    ;;

  3)
    echo ""
    echo "Logs de deployment:"
    echo "========================================="
    az webapp log deployment show --name "$APP_NAME" --resource-group "$RG_NAME"
    ;;

  4)
    echo ""
    echo "Logs en tiempo real (Ctrl+C para salir):"
    echo "========================================="
    az webapp log tail --name "$APP_NAME" --resource-group "$RG_NAME"
    ;;

  5)
    echo ""
    echo "Verificando health endpoints..."
    HOSTNAME=$(az functionapp show --name "$APP_NAME" --resource-group "$RG_NAME" --query "defaultHostName" -o tsv)
    echo "Hostname: $HOSTNAME"
    echo ""

    # Verificar el endpoint de health (si existe)
    echo "Probando HTTPS connection..."
    curl -I "https://$HOSTNAME" 2>/dev/null | head -n 5 || echo "No se pudo conectar al endpoint"

    echo ""
    echo "Listando funciones disponibles:"
    az functionapp function list --name "$APP_NAME" --resource-group "$RG_NAME" \
      --query "[].{Name:name, InvokeURL:invoke_url_template}" -o table
    ;;

  6)
    echo "Operación cancelada"
    exit 0
    ;;

  *)
    echo "Opción inválida"
    exit 1
    ;;
esac

echo ""
echo "========================================="
echo "Operación completada"
echo "========================================="
