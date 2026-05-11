#!/bin/bash
set -euo pipefail

###############################################################################
# what-if-deployment.sh
# Runs Azure What-If to preview changes before deployment
# Usage: ./scripts/what-if-deployment.sh [arm|bicep] [environment]
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

DEPLOY_TYPE="${1:-arm}"
ENVIRONMENT="${2:-dev}"
RESOURCE_GROUP="az-rapidgo-${ENVIRONMENT}-rg"
LOCATION="${3:-centralus}"

echo "=========================================="
echo "  RapidGo What-If Analysis"
echo "=========================================="
echo "Type: $DEPLOY_TYPE"
echo "Environment: $ENVIRONMENT"
echo "Resource Group: $RESOURCE_GROUP"
echo "=========================================="

# Check Azure CLI
if ! command -v az &> /dev/null; then
    echo "ERROR: Azure CLI is not installed"
    exit 1
fi

az account show &> /dev/null || {
    echo "ERROR: Not logged into Azure. Run 'az login' first."
    exit 1
}

# Ensure resource group exists
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --only-show-errors 2>/dev/null || true

if [ "$DEPLOY_TYPE" = "bicep" ]; then
    BICEP_FILE="$PROJECT_ROOT/src/infra-bicep/main.bicep"
    
    echo "Running What-If for Bicep..."
    az deployment sub what-if \
        --name "whatif-rapidgo-${ENVIRONMENT}-$(date +%Y%m%d%H%M%S)" \
        --location "$LOCATION" \
        --template-file "$BICEP_FILE" \
        --parameters \
            environmentName="$ENVIRONMENT" \
            location="$LOCATION" \
        --result-format FullResourcePayloads \
        --output jsonc

elif [ "$DEPLOY_TYPE" = "arm" ]; then
    ARM_FILE="$PROJECT_ROOT/src/infra-arm/main.json"
    PARAMS_FILE="$PROJECT_ROOT/src/infra-arm/azuredeploy.parameters.json"
    
    echo "Running What-If for ARM..."
    az deployment group what-if \
        --resource-group "$RESOURCE_GROUP" \
        --name "whatif-rapidgo-${ENVIRONMENT}-$(date +%Y%m%d%H%M%S)" \
        --template-file "$ARM_FILE" \
        --parameters "@$PARAMS_FILE" \
        --result-format FullResourcePayloads \
        --output jsonc
fi

echo ""
echo "=========================================="
echo "  What-If analysis completed!"
echo "=========================================="
