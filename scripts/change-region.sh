#!/bin/bash

# Script para cambiar la región en todos los archivos de configuración

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   RapidGo - Cambiar Región en Configuración               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar parámetro
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: Debes especificar una región${NC}"
    echo ""
    echo "Uso: $0 <region>"
    echo ""
    echo "Regiones disponibles en tu suscripción:"
    echo "  • centralus       - Central US (Iowa)"
    echo "  • eastus          - East US (Virginia)"
    echo "  • westus2         - West US 2 (Washington)"
    echo "  • westeurope      - West Europe (Países Bajos)"
    echo "  • northeurope     - North Europe (Irlanda)"
    echo "  • southeastasia   - Southeast Asia"
    echo ""
    echo "Ejemplo:"
    echo "  $0 westus2"
    exit 1
fi

NEW_REGION="$1"

echo -e "${YELLOW}🔄 Cambiando región a: ${NEW_REGION}${NC}"
echo ""

# Detectar región actual
CURRENT_REGION=$(grep -A 2 '"location"' src/infra-arm/azuredeploy.parameters.json | grep '"value"' | sed 's/.*"value": "\(.*\)".*/\1/')

echo -e "${BLUE}Región actual: ${CURRENT_REGION}${NC}"
echo -e "${GREEN}Región nueva: ${NEW_REGION}${NC}"
echo ""

# Confirmar cambio
read -p "¿Continuar con el cambio? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ]; then
    echo -e "${YELLOW}❌ Cambio cancelado${NC}"
    exit 0
fi

echo ""

# Cambiar en azuredeploy.parameters.json
echo -e "${BLUE}📝 Actualizando azuredeploy.parameters.json...${NC}"
sed -i.bak "s/\"value\": \"$CURRENT_REGION\"/\"value\": \"$NEW_REGION\"/" src/infra-arm/azuredeploy.parameters.json
rm -f src/infra-arm/azuredeploy.parameters.json.bak
echo "   ✅ Actualizado"

# Cambiar en main.json
echo -e "${BLUE}📝 Actualizando main.json...${NC}"
sed -i.bak "s/\"defaultValue\": \"$CURRENT_REGION\"/\"defaultValue\": \"$NEW_REGION\"/" src/infra-arm/main.json
rm -f src/infra-arm/main.json.bak
echo "   ✅ Actualizado"

# Cambiar en deploy-infra.yml
echo -e "${BLUE}📝 Actualizando deploy-infra.yml...${NC}"
sed -i.bak "s/$CURRENT_REGION/$NEW_REGION/g" .github/workflows/deploy-infra.yml
rm -f .github/workflows/deploy-infra.yml.bak
echo "   ✅ Actualizado"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}✅ Región cambiada exitosamente a: ${NEW_REGION}${NC}"
echo ""
echo "Archivos actualizados:"
echo "  • src/infra-arm/azuredeploy.parameters.json"
echo "  • src/infra-arm/main.json"
echo "  • .github/workflows/deploy-infra.yml"
echo ""
echo "Próximos pasos:"
echo ""
echo "1. Verificar cambios:"
echo "   git diff"
echo ""
echo "2. Commit y push:"
echo "   git add ."
echo "   git commit -m \"fix: cambiar región a ${NEW_REGION}\""
echo "   git push"
echo ""
