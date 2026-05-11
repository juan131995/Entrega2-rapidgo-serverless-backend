targetScope = 'resourceGroup'

param apimName string
param location string
param environmentName string
param skuAPIM string
param functionAppHostName string
param jwtOpenIdConfigUrl string
param jwtAudience string
param jwtIssuer string
param rateLimitCalls int
param rateLimitRenewalPeriod int

var apiVersionSetName = 'rapidgo-api-version-set'
var apiName = 'rapidgo-api'

resource apim 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: apimName
  location: location
  sku: {
    name: skuAPIM
    capacity: 1
  }
  tags: {
    environment: environmentName
    managedBy: 'bicep'
    project: 'RapidGo'
  }
  properties: {
    publisherName: 'RapidGo Team'
    publisherEmail: 'team@rapidgo.app'
    notificationSenderEmail: 'noreply@rapidgo.app'
    virtualNetworkType: 'None'
    disableGateway: false
    apiVersionConstraint: {
      minApiVersion: '2019-01-01'
    }
  }
}

resource apiVersionSet 'Microsoft.ApiManagement/service/apiVersionSets@2023-05-01-preview' = {
  parent: apim
  name: apiVersionSetName
  properties: {
    displayName: 'RapidGo API Version Set'
    description: 'Version set for RapidGo API management'
    versioningScheme: 'Segment'
    versionQueryName: 'api-version'
    versionHeaderName: 'X-Api-Version'
  }
}

resource api 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  parent: apim
  name: apiName
  properties: {
    displayName: 'RapidGo API'
    description: 'API principal para la plataforma de domicilios RapidGo'
    serviceUrl: 'https://${functionAppHostName}'
    path: 'api/v1'
    protocols: [
      'https'
    ]
    apiVersion: 'v1'
    apiVersionSetId: apiVersionSet.id
    apiRevision: '1'
    subscriptionRequired: true
  }
}

resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-05-01-preview' = {
  parent: api
  name: 'policy'
  properties: {
    format: 'rawxml'
    value: loadTextContent('./apim-policy.xml')
  }
}

output gatewayUrl string = apim.properties.gatewayUrl
output apiVersionSetId string = apiVersionSet.id
output apiId string = api.id
