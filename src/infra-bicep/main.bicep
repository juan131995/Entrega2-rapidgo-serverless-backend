targetScope = 'subscription'

param environmentName string = 'dev'
param location string = 'centralus'
param functionAppRuntime string = 'node'
param cosmosDBFreeTier bool = true
param skuAPIM string = 'Developer'
param jwtOpenIdConfigUrl string = 'https://rapidgo.auth0.com/.well-known/openid-configuration'
param jwtAudience string = 'https://api.rapidgo.app'
param jwtIssuer string = 'https://rapidgo.auth0.com/'
param rateLimitCalls int = 500
param rateLimitRenewalPeriod int = 60
param randomSuffix string = substring(uniqueString(subscription().id, environmentName), 0, 6)

var rgName = 'az-rapidgo-${environmentName}-rg'
var deploymentName = 'arm-rapidgo-${environmentName}'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: rgName
  location: location
  tags: {
    environment: environmentName
    managedBy: 'bicep'
    project: 'RapidGo'
    randomSuffix: randomSuffix
  }
}

module infrastructure './modules/main.bicep' = {
  name: deploymentName
  scope: resourceGroup
  params: {
    environmentName: environmentName
    location: location
    functionAppRuntime: functionAppRuntime
    cosmosDBFreeTier: cosmosDBFreeTier
    skuAPIM: skuAPIM
    jwtOpenIdConfigUrl: jwtOpenIdConfigUrl
    jwtAudience: jwtAudience
    jwtIssuer: jwtIssuer
    rateLimitCalls: rateLimitCalls
    rateLimitRenewalPeriod: rateLimitRenewalPeriod
    randomSuffix: randomSuffix
  }
}

output functionAppDefaultHostName string = infrastructure.outputs.functionAppDefaultHostName
output apimGatewayUrl string = infrastructure.outputs.apimGatewayUrl
output cosmosDbEndpoint string = infrastructure.outputs.cosmosDbEndpoint
output blobStorageEndpoint string = infrastructure.outputs.blobStorageEndpoint
output notificationHubEndpoint string = infrastructure.outputs.notificationHubEndpoint
output resourceGroupName string = resourceGroup.name
output apiVersionSetId string = infrastructure.outputs.apiVersionSetId
