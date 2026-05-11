#!/bin/bash
set -euo pipefail

###############################################################################
# validate-deployment.sh
# Validates ARM/Bicep templates before deployment
# Usage: ./scripts/validate-deployment.sh [arm|bicep] [environment]
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

DEPLOY_TYPE="${1:-arm}"
ENVIRONMENT="${2:-dev}"
RESOURCE_GROUP="az-rapidgo-${ENVIRONMENT}-rg"
LOCATION="${3:-centralus}"

echo "=========================================="
echo "  RapidGo Infrastructure Validation"
echo "=========================================="
echo "Type: $DEPLOY_TYPE"
echo "Environment: $ENVIRONMENT"
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo "=========================================="

# Check Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "ERROR: Azure CLI is not installed"
    exit 1
fi

# Check logged in
az account show &> /dev/null || {
    echo "ERROR: Not logged into Azure. Run 'az login' first."
    exit 1
}

echo ""
echo "Step 1: Ensuring resource group exists..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --tags environment="$ENVIRONMENT" managedBy="validation" --only-show-errors 2>/dev/null || true

if [ "$DEPLOY_TYPE" = "bicep" ]; then
    echo ""
    echo "Step 2: Validating Bicep template..."
    BICEP_FILE="$PROJECT_ROOT/src/infra-bicep/main.bicep"
    
    if [ ! -f "$BICEP_FILE" ]; then
        echo "ERROR: Bicep file not found at $BICEP_FILE"
        exit 1
    fi
    
    echo "Running: az deployment sub validate..."
    az deployment sub validate \
        --name "validate-rapidgo-${ENVIRONMENT}-$(date +%Y%m%d%H%M%S)" \
        --location "$LOCATION" \
        --template-file "$BICEP_FILE" \
        --parameters \
            environmentName="$ENVIRONMENT" \
            location="$LOCATION" \
        --output jsonc

elif [ "$DEPLOY_TYPE" = "arm" ]; then
    echo ""
    echo "Step 2: Validating ARM template..."
    ARM_FILE="$PROJECT_ROOT/src/infra-arm/main.json"
    PARAMS_FILE="$PROJECT_ROOT/src/infra-arm/azuredeploy.parameters.json"
    
    if [ ! -f "$ARM_FILE" ]; then
        echo "ERROR: ARM file not found at $ARM_FILE"
        exit 1
    fi
    
    echo "Running: az deployment group validate..."
    az deployment group validate \
        --resource-group "$RESOURCE_GROUP" \
        --name "validate-rapidgo-${ENVIRONMENT}-$(date +%Y%m%d%H%M%S)" \
        --template-file "$ARM_FILE" \
        --parameters "@$PARAMS_FILE" \
        --output jsonc
fi

echo ""
echo "=========================================="
echo "  Validation completed successfully!"
echo "=========================================="
