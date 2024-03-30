param location string
param systemPrefix string

var appServicePlanName = systemPrefix

// var isProduction = environmentCode == 'prd'
// var sku = isProduction
//     ? {
//         name: 'P0v3'
//         tier: 'Premium0V3'
//         capacity: 1
//       }
//     : {
//         name: 'B1'
//         tier: 'Basic'
//         capacity: 1
//       }
var sku = {
    name: 'B1'
    tier: 'Basic'
    capacity: 1
  }

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: true
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
  }
  sku: {
    name: sku.name
    tier: sku.tier
    capacity: sku.capacity
  }
}

output id string = appServicePlan.id
output name string = appServicePlan.name
