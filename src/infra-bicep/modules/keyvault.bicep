targetScope = 'resourceGroup'

param keyVaultName string
param location string
param environmentName string
param cosmosConnectionString string
param blobConnectionString string
param notificationHubConnectionString string
param functionAppPrincipalId string

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: {
    environment: environmentName
    managedBy: 'bicep'
  }
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enabledForTemplateDeployment: true
    enableRbacAuthorization: false
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: functionAppPrincipalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
}

resource cosmosSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'cosmos-db-connection-string'
  properties: {
    value: cosmosConnectionString
  }
}

resource blobSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'blob-storage-connection-string'
  properties: {
    value: blobConnectionString
  }
}

resource notificationHubSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'notification-hub-connection-string'
  properties: {
    value: notificationHubConnectionString
  }
}

output vaultUri string = keyVault.properties.vaultUri
output keyVaultName string = keyVault.name
