targetScope = 'resourceGroup'

@description('Environment name prefix')
param environmentName string = 'dev'

@description('Azure region for all resources')
param location string = 'centralus'

@description('Function App runtime')
@allowed([
  'node'
  'python'
])
param functionAppRuntime string = 'node'

@description('Enable Cosmos DB free tier')
param cosmosDBFreeTier bool = true

@description('APIM SKU')
@allowed([
  'Developer'
  'Basic'
  'Standard'
])
param skuAPIM string = 'Developer'

@description('OpenID Connect configuration URL for JWT validation')
param jwtOpenIdConfigUrl string = 'https://rapidgo.auth0.com/.well-known/openid-configuration'

@description('Expected audience claim in JWT tokens')
param jwtAudience string = 'https://api.rapidgo.app'

@description('Expected issuer claim in JWT tokens')
param jwtIssuer string = 'https://rapidgo.auth0.com/'

@description('Number of calls allowed per renewal period')
param rateLimitCalls int = 500

@description('Renewal period in seconds for rate limiting')
param rateLimitRenewalPeriod int = 60

@description('Random 6-character suffix for resource names')
param randomSuffix string = substring(uniqueString(resourceGroup().id), 0, 6)

var uniqueSuffix = toLower(randomSuffix)
var envName = toLower(environmentName)

var storageAccountName = toLower('azrapidgo${envName}func${uniqueSuffix}')
var functionAppName = 'az-rapidgo-${envName}-functions'
var functionPlanName = 'az-rapidgo-${envName}-plan'
var apimName = 'az-rapidgo-${envName}-apim'
var cosmosAccountName = toLower('azrapidgo${envName}db${uniqueSuffix}')
var cosmosDatabaseName = 'az-rapidgo-${envName}-db'
var cosmosContainerName = 'pedidos'
var blobStorageAccountName = toLower('azrapidgo${envName}blob${uniqueSuffix}')
var blobContainerName = 'entregas'
var notificationHubNamespace = 'az-rapidgo-${envName}-notif-ns'
var notificationHubName = 'az-rapidgo-${envName}-notifications'
var keyVaultName = toLower(take('az-rapidgo-${envName}-kv-${uniqueSuffix}', 24))
var appInsightsName = '${functionAppName}-insights'
var apiVersionSetName = 'rapidgo-api-version-set'

module storage './storage.bicep' = {
  name: 'storageDeployment'
  params: {
    blobStorageAccountName: blobStorageAccountName
    blobContainerName: blobContainerName
    location: location
    environmentName: environmentName
  }
}

module cosmos './cosmosdb.bicep' = {
  name: 'cosmosDeployment'
  params: {
    cosmosAccountName: cosmosAccountName
    cosmosDatabaseName: cosmosDatabaseName
    cosmosContainerName: cosmosContainerName
    location: location
    environmentName: environmentName
    cosmosDBFreeTier: cosmosDBFreeTier
  }
}

module notificationHub './notificationhub.bicep' = {
  name: 'notificationHubDeployment'
  params: {
    notificationHubNamespace: notificationHubNamespace
    notificationHubName: notificationHubName
    location: location
    environmentName: environmentName
  }
}

module keyVault './keyvault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    keyVaultName: keyVaultName
    location: location
    environmentName: environmentName
    cosmosConnectionString: cosmos.outputs.connectionString
    blobConnectionString: storage.outputs.connectionString
    notificationHubConnectionString: notificationHub.outputs.connectionString
    functionAppPrincipalId: functionApp.outputs.principalId
  }
  dependsOn: [
    cosmos
    storage
    notificationHub
  ]
}

module functionApp './functionapp.bicep' = {
  name: 'functionAppDeployment'
  params: {
    functionAppName: functionAppName
    functionPlanName: functionPlanName
    storageAccountName: storageAccountName
    appInsightsName: appInsightsName
    location: location
    environmentName: environmentName
    functionAppRuntime: functionAppRuntime
    cosmosDbName: cosmosDatabaseName
    cosmosDbContainer: cosmosContainerName
    cosmosDbConnectionString: cosmos.outputs.connectionString
    notificationHubConnectionString: notificationHub.outputs.connectionString
    notificationHubName: notificationHubName
    blobConnectionString: storage.outputs.connectionString
    keyVaultName: keyVaultName
  }
  dependsOn: [
    keyVault
  ]
}

module apim './apim.bicep' = {
  name: 'apimDeployment'
  params: {
    apimName: apimName
    location: location
    environmentName: environmentName
    skuAPIM: skuAPIM
    functionAppHostName: functionApp.outputs.defaultHostName
    jwtOpenIdConfigUrl: jwtOpenIdConfigUrl
    jwtAudience: jwtAudience
    jwtIssuer: jwtIssuer
    rateLimitCalls: rateLimitCalls
    rateLimitRenewalPeriod: rateLimitRenewalPeriod
  }
  dependsOn: [
    functionApp
  ]
}

output functionAppDefaultHostName string = functionApp.outputs.defaultHostName
output apimGatewayUrl string = apim.outputs.gatewayUrl
output cosmosDbEndpoint string = cosmos.outputs.endpoint
output blobStorageEndpoint string = storage.outputs.endpoint
output notificationHubEndpoint string = notificationHub.outputs.endpoint
output resourceGroupName string = resourceGroup().name
output apiVersionSetId string = apim.outputs.apiVersionSetId
