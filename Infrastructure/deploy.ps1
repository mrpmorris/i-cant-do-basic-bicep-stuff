param(
    [Parameter(Mandatory=$true)]
    [string]$location,

    [Parameter(Mandatory=$true)]
    [ValidatePattern('^[a-z]{4,5}|prd|tst|uat|$', ErrorMessage = "Must be 4 or 5 lowercase chars for an individual developer, or a well-known 3 letter environment name.")]
    [ValidateLength(3, 5)]
    [string]$environmentCode
)

az deployment sub create --verbose `
    --location $location `
    --template-file main.bicep `
    --parameters environmentCode=$environmentCode location=$location
