#!/bin/bash

# Script para hacer rollback de infraestructura a un deployment anterior
# Uso: ./scripts/rollback-infrastructure.sh [dev|nonprod|prod]

set -e

ENV_NAME="${1:-dev}"
RG_NAME="az-rapidgo-${ENV_NAME}-rg"

echo "========================================="
echo "Infrastructure Rollback - Entorno: $ENV_NAME"
echo "========================================="
echo ""

# Verificar login
if ! az account show &> /dev/null; then
    echo "Error: No estás autenticado en Azure"
    echo "Ejecuta: az login"
    exit 1
fi

# Verificar que el resource group existe
if ! az group exists --name "$RG_NAME" | grep -q "true"; then
    echo "Error: Resource group $RG_NAME no existe"
    exit 1
fi

echo "Resource Group: $RG_NAME"
echo ""

# Listar deployments recientes
echo "Deployments recientes en este Resource Group:"
echo "----------------------------------------"
az deployment group list --resource-group "$RG_NAME" \
  --query "[0:10].{Name:name, State:properties.provisioningState, Timestamp:properties.timestamp, Mode:properties.mode}" \
  -o table

echo ""
echo "Opciones de Rollback:"
echo "1. Ver detalles de un deployment específico"
echo "2. Ver recursos creados/modificados en un deployment"
echo "3. Exportar template del estado actual"
echo "4. Eliminar recursos creados después de una fecha específica"
echo "5. Rollback completo - eliminar todo el Resource Group"
echo "6. Cancelar"
echo ""

read -p "Selecciona una opción (1-6): " OPTION

case $OPTION in
  1)
    echo ""
    read -p "Ingresa el nombre del deployment a inspeccionar: " DEPLOYMENT_NAME
    echo ""
    echo "Detalles del deployment:"
    echo "========================================="
    az deployment group show --resource-group "$RG_NAME" --name "$DEPLOYMENT_NAME" \
      --query "{Name:name, State:properties.provisioningState, Timestamp:properties.timestamp, Duration:properties.duration, Mode:properties.mode, CorrelationId:properties.correlationId}" \
      -o json | jq .

    echo ""
    echo "Operations realizadas:"
    az deployment operation group list --resource-group "$RG_NAME" --name "$DEPLOYMENT_NAME" \
      --query "[].{Target:properties.targetResource.resourceName, Type:properties.targetResource.resourceType, Status:properties.provisioningState}" \
      -o table
    ;;

  2)
    echo ""
    read -p "Ingresa el nombre del deployment: " DEPLOYMENT_NAME
    echo ""
    echo "Recursos afectados por este deployment:"
    echo "========================================="
    az deployment operation group list --resource-group "$RG_NAME" --name "$DEPLOYMENT_NAME" \
      --query "[].{Resource:properties.targetResource.id, Action:properties.provisioningOperation, Status:properties.provisioningState}" \
      -o table
    ;;

  3)
    echo ""
    echo "Exportando template del estado actual..."
    OUTPUT_FILE="infrastructure-snapshot-${ENV_NAME}-$(date +%Y%m%d-%H%M%S).json"

    az group export --resource-group "$RG_NAME" --output json > "$OUTPUT_FILE"
    echo "✓ Template exportado a: $OUTPUT_FILE"
    echo ""
    echo "Este template puede usarse para recrear el estado actual de la infraestructura"
    ;;

  4)
    echo ""
    read -p "Ingresa la fecha de corte (YYYY-MM-DD): " CUTOFF_DATE
    echo ""
    echo "⚠️  ADVERTENCIA: Esto eliminará recursos creados después de $CUTOFF_DATE"
    read -p "¿Estás seguro? (yes/no): " CONFIRM

    if [ "$CONFIRM" != "yes" ]; then
        echo "Operación cancelada"
        exit 0
    fi

    # Convertir fecha a timestamp
    CUTOFF_TIMESTAMP=$(date -j -f "%Y-%m-%d" "$CUTOFF_DATE" "+%s" 2>/dev/null || date -d "$CUTOFF_DATE" "+%s")

    echo ""
    echo "Buscando recursos creados después de $CUTOFF_DATE..."

    # Listar todos los recursos con sus timestamps
    RESOURCES=$(az resource list --resource-group "$RG_NAME" --query "[].{id:id, name:name, type:type}" -o json)

    echo "$RESOURCES" | jq -r '.[] | .id' | while read -r resource_id; do
      # Obtener detalles del recurso
      RESOURCE_INFO=$(az resource show --ids "$resource_id" 2>/dev/null || echo "{}")
      CREATED_TIME=$(echo "$RESOURCE_INFO" | jq -r '.systemData.createdAt // empty')

      if [ -n "$CREATED_TIME" ]; then
        RESOURCE_TIMESTAMP=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${CREATED_TIME%.*}" "+%s" 2>/dev/null || echo "0")

        if [ "$RESOURCE_TIMESTAMP" -gt "$CUTOFF_TIMESTAMP" ]; then
          RESOURCE_NAME=$(echo "$RESOURCE_INFO" | jq -r '.name')
          echo "  Eliminando (creado el $CREATED_TIME): $RESOURCE_NAME"
          az resource delete --ids "$resource_id" --verbose
        fi
      fi
    done

    echo "✓ Rollback completado"
    ;;

  5)
    echo ""
    echo "⚠️  ADVERTENCIA: Esto eliminará TODOS los recursos del Resource Group"
    echo "Resource Group: $RG_NAME"
    echo ""
    read -p "¿Estás ABSOLUTAMENTE seguro? Escribe 'DELETE' para confirmar: " CONFIRM

    if [ "$CONFIRM" != "DELETE" ]; then
        echo "Operación cancelada"
        exit 0
    fi

    echo ""
    echo "Eliminando Resource Group completo..."
    az group delete --name "$RG_NAME" --yes --no-wait

    echo "✓ Eliminación iniciada (operación asíncrona)"
    echo ""
    echo "Para verificar el progreso:"
    echo "  az group exists --name $RG_NAME"
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
