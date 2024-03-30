targetScope = 'resourceGroup'

param location string
param systemPrefix string
param appServicePlanId string

var functionsAppName = '${systemPrefix}-telegram'
var storageAccountName = replace(toLower(functionsAppName), '-', '9')


resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  kind: 'Storage'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
    }
  }
}

var storageConnectionKey = storageAccount.listKeys().keys[0].value
var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageConnectionKey};EndpointSuffix=core.windows.net'

resource functionsApp 'Microsoft.Web/sites@2023-01-01' = {
  name: functionsAppName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
      serverFarmId: appServicePlanId
      httpsOnly: true
      reserved: true
      isXenon: false
      hyperV: false
      vnetRouteAllEnabled: false
      vnetImagePullEnabled: false
      vnetContentShareEnabled: false
      scmSiteAlsoStopped: false
      clientAffinityEnabled: false
      clientCertEnabled: false
      clientCertMode: 'Required'
      hostNamesDisabled: false
      containerSize: 0
      dailyMemoryTimeQuota: 0
      redundancyMode: 'None'
      storageAccountRequired: false
      keyVaultReferenceIdentity: 'SystemAssigned'
      siteConfig: {
        linuxFxVersion: 'DOTNET-ISOLATED|8.0'
        alwaysOn: false
        minTlsVersion: '1.2'
        numberOfWorkers: 1
        acrUseManagedIdentityCreds: false
        http20Enabled: false
        functionAppScaleLimit: 200
        minimumElasticInstanceCount: 0
      }
  }
}

resource functionsAppConfig 'Microsoft.Web/sites/config@2023-01-01' = {
  name: 'appsettings'
  kind: 'string'
  parent: functionsApp
  properties: {
    AzureWebJobsStorage : storageConnectionString
    FUNCTIONS_EXTENSION_VERSION : '~4'
    FUNCTIONS_WORKER_RUNTIME : 'dotnet-isolated'
  }
}

output functionsAppName string = functionsApp.name
output storageAccountName string = storageAccount.name
output functionsAppPrincipalId string = functionsApp.identity.principalId

