targetScope = 'resourceGroup'

param notificationHubNamespace string
param notificationHubName string
param location string
param environmentName string

resource nhNamespace 'Microsoft.NotificationHubs/namespaces@2023-01-01-preview' = {
  name: notificationHubNamespace
  location: location
  sku: {
    name: 'Free'
  }
  tags: {
    environment: environmentName
    managedBy: 'bicep'
  }
  properties: {
    zoneRedundancy: 'Disabled'
  }
}

resource notificationHub 'Microsoft.NotificationHubs/namespaces/notificationHubs@2023-01-01-preview' = {
  parent: nhNamespace
  name: notificationHubName
  location: location
  tags: {
    environment: environmentName
    managedBy: 'bicep'
  }
  properties: {
    apnsCredential: null
    wnsCredential: null
  }
}

resource authRule 'Microsoft.NotificationHubs/namespaces/notificationHubs/authorizationRules@2023-01-01-preview' = {
  parent: notificationHub
  name: 'DefaultFullSharedAccessSignature'
  properties: {
    rights: [
      'Listen'
      'Send'
      'Manage'
    ]
  }
}

output endpoint string = nhNamespace.properties.serviceBusEndpoint
output connectionString string = listKeys(authRule.id, '2023-01-01-preview').primaryConnectionString
output notificationHubName string = notificationHubName
