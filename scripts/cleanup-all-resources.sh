#!/bin/bash

###############################################################################
# Script: cleanup-all-resources.sh
# Description: Elimina TODOS los resource groups de RapidGo y purga recursos soft-deleted
# Usage: ./scripts/cleanup-all-resources.sh [dev|prod]
###############################################################################

set -e

ENV=${1:-"dev"}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧹 LIMPIEZA COMPLETA DE RECURSOS RAPIDGO - ENVIRONMENT: $ENV"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  ADVERTENCIA: Este script eliminará:"
echo "   - Todos los Resource Groups que empiecen con 'rg-rapidgo-$ENV' o 'az-rapidgo-$ENV'"
echo "   - Todos los recursos soft-deleted (Key Vaults, APIM, Cosmos DB)"
echo ""
read -p "¿Estás seguro? (escribe 'YES' para continuar): " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
  echo "❌ Operación cancelada"
  exit 0
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PASO 1: Eliminando Resource Groups"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Find all RGs
ALL_RGS=$(az group list --query "[?starts_with(name, 'rg-rapidgo-$ENV') || starts_with(name, 'az-rapidgo-$ENV')].name" -o tsv)

if [ -n "$ALL_RGS" ]; then
  echo "Encontrados los siguientes Resource Groups:"
  echo "$ALL_RGS"
  echo ""

  for RG in $ALL_RGS; do
    echo "🗑️  Eliminando: $RG"
    az group delete --name "$RG" --yes --no-wait
  done

  echo "✅ Eliminación iniciada para todos los Resource Groups"
  echo ""
  echo "⏱️  Esperando 2 minutos para que comience la eliminación..."
  sleep 120
else
  echo "✅ No se encontraron Resource Groups para eliminar"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PASO 2: Purgando Key Vaults soft-deleted"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

DELETED_KV=$(az keyvault list-deleted --query "[?starts_with(name, 'az-rapidgo-$ENV')].{name:name, location:properties.location}" -o json 2>/dev/null || echo "[]")

if [ "$DELETED_KV" != "[]" ]; then
  echo "Encontrados Key Vaults soft-deleted:"
  echo "$DELETED_KV" | jq -r '.[] | "  - \(.name) in \(.location)"'
  echo ""

  echo "$DELETED_KV" | jq -r '.[] | "\(.name)|\(.location)"' | while IFS='|' read -r NAME LOC; do
    echo "🗑️  Purgando Key Vault: $NAME"
    az keyvault purge --name "$NAME" --location "$LOC" 2>&1 || echo "⚠️  No se pudo purgar $NAME"
  done

  echo "✅ Purga de Key Vaults completada"
else
  echo "✅ No se encontraron Key Vaults soft-deleted"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PASO 3: Purgando APIM services soft-deleted"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

DELETED_APIM=$(az apim deletedservice list --query "[?starts_with(serviceName, 'az-rapidgo-$ENV')].{name:serviceName, location:location}" -o json 2>/dev/null || echo "[]")

if [ "$DELETED_APIM" != "[]" ]; then
  echo "Encontrados APIM services soft-deleted:"
  echo "$DELETED_APIM" | jq -r '.[] | "  - \(.name) in \(.location)"'
  echo ""

  echo "$DELETED_APIM" | jq -r '.[] | "\(.name)|\(.location)"' | while IFS='|' read -r NAME LOC; do
    echo "🗑️  Purgando APIM: $NAME"
    az apim deletedservice purge --service-name "$NAME" --location "$LOC" 2>&1 || echo "⚠️  No se pudo purgar $NAME"
  done

  echo "✅ Purga de APIM services completada"
else
  echo "✅ No se encontraron APIM services soft-deleted"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PASO 4: Verificando eliminación de Resource Groups"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "⏱️  Esperando hasta 15 minutos para que se completen las eliminaciones..."
echo ""

for i in {1..180}; do
  REMAINING=$(az group list --query "[?starts_with(name, 'rg-rapidgo-$ENV') || starts_with(name, 'az-rapidgo-$ENV')].name" -o tsv)

  if [ -z "$REMAINING" ]; then
    echo "✅ ¡Todos los Resource Groups han sido eliminados!"
    break
  fi

  if [ $((i % 12)) -eq 0 ]; then
    MINS=$((i / 12))
    echo "⏳ Todavía eliminando... $MINS minutos transcurridos"
    echo "   Resource Groups restantes:"
    echo "$REMAINING" | sed 's/^/     - /'
  fi

  sleep 5
done

# Final check
FINAL_RGS=$(az group list --query "[?starts_with(name, 'rg-rapidgo-$ENV') || starts_with(name, 'az-rapidgo-$ENV')].name" -o tsv)

if [ -n "$FINAL_RGS" ]; then
  echo ""
  echo "⚠️  ADVERTENCIA: Algunos Resource Groups aún existen después de 15 minutos:"
  echo "$FINAL_RGS"
  echo ""
  echo "Puedes esperar más tiempo o eliminarlos manualmente desde Azure Portal"
else
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ ¡LIMPIEZA COMPLETADA EXITOSAMENTE!"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Ahora puedes ejecutar un nuevo deployment sin conflictos."
fi
