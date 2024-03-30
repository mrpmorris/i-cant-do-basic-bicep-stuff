targetScope = 'resourceGroup'

param resourceGroupName string
param location string
param systemPrefix string

module functionsAppServicePlan 'CreateAppServicePlan.bicep' = {
    name: 'consumptionAppServicePlan'
    scope: az.resourceGroup(resourceGroupName)
    params: {
        location: location
        systemPrefix: systemPrefix
    }
}

module telegramFunctionsApp 'CreateTelegramFunctionsApp.bicep' = {
    name: 'telegramFunctionsApp'
    scope: az.resourceGroup(resourceGroupName)
    params: {
        location: location
        systemPrefix: systemPrefix
        appServicePlanId: functionsAppServicePlan.outputs.id
    }
}

output consumptionAppServicePlanName string = functionsAppServicePlan.outputs.name

// Telegram app
output telegramFunctionsAppName string = telegramFunctionsApp.outputs.functionsAppName
output telegramStorageAccountName string = telegramFunctionsApp.outputs.storageAccountName
output telegramFunctionsAppPrincipalId string = telegramFunctionsApp.outputs.functionsAppPrincipalId
