targetScope = 'resourceGroup'

param functionAppName string
param functionPlanName string
param storageAccountName string
param appInsightsName string
param location string
param environmentName string
param functionAppRuntime string
param cosmosDbName string
param cosmosDbContainer string
param cosmosDbConnectionString string
param notificationHubConnectionString string
param notificationHubName string
param blobConnectionString string
param keyVaultName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = existing {
  name: storageAccountName
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  tags: {
    environment: environmentName
    managedBy: 'bicep'
  }
  properties: {
    Application_Type: 'web'
  }
}

resource functionPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: functionPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  kind: 'functionapp'
  tags: {
    environment: environmentName
    managedBy: 'bicep'
  }
  properties: {
    reserved: true
  }
}

resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    environment: environmentName
    managedBy: 'bicep'
  }
  properties: {
    serverFarmId: functionPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, '2023-01-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionAppRuntime
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'COSMOS_DB_NAME'
          value: cosmosDbName
        }
        {
          name: 'COSMOS_DB_CONTAINER'
          value: cosmosDbContainer
        }
        {
          name: 'COSMOS_DB_CONNECTION_STRING'
          value: '@Microsoft.KeyVault(SecretUri=${reference(keyVaultName, '2023-07-01').vaultUri}secrets/cosmos-db-connection-string/)'
        }
        {
          name: 'NOTIFICATION_HUB_CONNECTION_STRING'
          value: '@Microsoft.KeyVault(SecretUri=${reference(keyVaultName, '2023-07-01').vaultUri}secrets/notification-hub-connection-string/)'
        }
        {
          name: 'NOTIFICATION_HUB_NAME'
          value: notificationHubName
        }
        {
          name: 'BLOB_STORAGE_CONNECTION_STRING'
          value: '@Microsoft.KeyVault(SecretUri=${reference(keyVaultName, '2023-07-01').vaultUri}secrets/blob-storage-connection-string/)'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~18'
        }
      ]
      linuxFxVersion: functionAppRuntime == 'node' ? 'Node|18' : 'Python|3.11'
    }
  }
}

output defaultHostName string = functionApp.properties.defaultHostName
output principalId string = functionApp.identity.principalId
output functionAppName string = functionApp.name
