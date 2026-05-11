targetScope = 'resourceGroup'

param cosmosAccountName string
param cosmosDatabaseName string
param cosmosContainerName string
param location string
param environmentName string
param cosmosDBFreeTier bool

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' = {
  name: cosmosAccountName
  location: location
  kind: 'GlobalDocumentDB'
  tags: {
    environment: environmentName
    managedBy: 'bicep'
    defaultExperience: 'Core (SQL)'
  }
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
      maxIntervalInSeconds: 5
      maxStalenessPrefix: 100
    }
    enableMultipleWriteLocations: false
    enableFreeTier: cosmosDBFreeTier
    disableKeyBasedMetadataWriteAccess: false
    backupPolicy: {
      type: 'Periodic'
      periodicModeProperties: {
        backupIntervalInMinutes: 240
        backupRetentionIntervalInHours: 8
      }
    }
    publicNetworkAccess: 'Enabled'
    networkAclBypass: 'None'
  }
}

resource cosmosDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-11-15' = {
  parent: cosmosAccount
  name: cosmosDatabaseName
  properties: {
    resource: {
      id: cosmosDatabaseName
    }
  }
}

resource cosmosContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-11-15' = {
  parent: cosmosDatabase
  name: cosmosContainerName
  properties: {
    resource: {
      id: cosmosContainerName
      partitionKey: {
        paths: [
          '/tipo'
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
        compositeIndexes: [
          [
            {
              path: '/tipo'
              order: 'ascending'
            }
            {
              path: '/usuarioId'
              order: 'ascending'
            }
            {
              path: '/createdAt'
              order: 'descending'
            }
          ]
          [
            {
              path: '/tipo'
              order: 'ascending'
            }
            {
              path: '/estado'
              order: 'ascending'
            }
            {
              path: '/createdAt'
              order: 'descending'
            }
          ]
        ]
      }
      defaultTtl: 2592000
    }
  }
}

output endpoint string = cosmosAccount.properties.documentEndpoint
output connectionString string = listConnectionStrings(cosmosAccount.id, '2023-11-15').connectionStrings[0].connectionString
output databaseName string = cosmosDatabaseName
output containerName string = cosmosContainerName
