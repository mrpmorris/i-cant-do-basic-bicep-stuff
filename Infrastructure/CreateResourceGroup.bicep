targetScope='subscription'

param location string
param resourceGroupName string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
}

output name string = resourceGroup.name
