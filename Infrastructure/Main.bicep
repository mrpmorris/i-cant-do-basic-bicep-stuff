targetScope = 'subscription'

@allowed([
    'uksouth'
    'ukwest'
  ])
param location string = 'uksouth'


@minLength(3)
@maxLength(5)
param environmentCode string

var isKnownEnvironment = environmentCode == 'prd' || environmentCode == 'uat' || environmentCode == 'tst' || environmentCode == 'dev'
var isDeveloperEnvironment = !isKnownEnvironment
var knownEnvironmentNameOrShared = isDeveloperEnvironment ? 'shared' : environmentCode
var shortLocationCode = location == 'uksouth' ? 'uks' : 'ukw'
var resourceGroupName = 'myapp-${knownEnvironmentNameOrShared}-${shortLocationCode}'
var systemPrefix = 'myapp-${environmentCode}-${shortLocationCode}'

module resourceGroup 'CreateResourceGroup.bicep' = {
    name: 'resourceGroup'
    params: {
        location: location
        resourceGroupName: resourceGroupName
    }
}

module resourcesForKnownEnvironment 'CreateKnownEnvironmentResources.bicep' =
    if (isKnownEnvironment) {
        name: 'resourcesForKnownEnvironment'
        scope: az.resourceGroup(resourceGroupName)
        dependsOn: [ resourceGroup ]
        params: {
            resourceGroupName: resourceGroup.outputs.name
            systemPrefix: systemPrefix
            location: location
        }
    }


output consumptionAppServicePlanName string = resourcesForKnownEnvironment.outputs.consumptionAppServicePlanName

// Telegram app
output telegramFunctionsAppName string = resourcesForKnownEnvironment.outputs.telegramFunctionsAppName
output telegramStorageAccountName string = resourcesForKnownEnvironment.outputs.telegramStorageAccountName
output telegramFunctionsAppPrincipalId string = resourcesForKnownEnvironment.outputs.telegramFunctionsAppPrincipalId
