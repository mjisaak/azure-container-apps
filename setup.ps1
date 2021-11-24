# Ensure you are logged in to the correct account before running this script (az login)
# Ensure you have the correct subscription ID (az account set)

$currentDate = Get-Date

$RESOURCE_GROUP = "rg-meetup-conapp-backup"
$LOCATION = "northeurope"
$LOG_ANALYTICS_WORKSPACE = "meetup-conapp-law"
$CONTAINERAPPS_ENVIRONMENT = "meetup-conapp-conenv"



# install the Azure Container Apps extension to the CLI.
az extension add `
    --source https://workerappscliextension.blob.core.windows.net/azure-cli-extension/containerapp-0.2.0-py2.py3-none-any.whl

# register the Microsoft.Web namespace.
az provider register `
    --namespace Microsoft.Web

# create a resource group.
az group create `
    --name $RESOURCE_GROUP `
    --location "$LOCATION"

# create a new Log Analytics workspace.
az monitor log-analytics workspace create `
    --resource-group $RESOURCE_GROUP `
    --workspace-name $LOG_ANALYTICS_WORKSPACE

# retrieve the workspace ID.
$LOG_ANALYTICS_WORKSPACE_CLIENT_ID = az monitor log-analytics workspace show `
    --query customerId `
    -g $RESOURCE_GROUP `
    -n $LOG_ANALYTICS_WORKSPACE `
    --out tsv

# retrieve the workspace key.
$LOG_ANALYTICS_WORKSPACE_CLIENT_SECRET = az monitor log-analytics workspace get-shared-keys `
    --query primarySharedKey `
    -g $RESOURCE_GROUP `
    -n $LOG_ANALYTICS_WORKSPACE `
    --out tsv`

# create a new container app environment.
az containerapp env create `
    --name $CONTAINERAPPS_ENVIRONMENT `
    --resource-group $RESOURCE_GROUP `
    --logs-workspace-id $LOG_ANALYTICS_WORKSPACE_CLIENT_ID `
    --logs-workspace-key $LOG_ANALYTICS_WORKSPACE_CLIENT_SECRET `
    --location $LOCATION

$apiFqdn = az containerapp create `
    --name wd-sample-api `
    --resource-group $RESOURCE_GROUP `
    --environment $CONTAINERAPPS_ENVIRONMENT `
    --image whiteduck/sample-api:latest `
    --target-port 8080 `
    --ingress 'internal' `
    --environment-variables 'Value=Hello Meetup 🙋‍♂️'`
    --query configuration.ingress.fqdn `
    --out tsv

az containerapp create `
    --name wd-sample-frontend `
    --resource-group $RESOURCE_GROUP `
    --environment $CONTAINERAPPS_ENVIRONMENT `
    --image whiteduck/sample-mvc:latest `
    --target-port 8080 `
    --ingress 'external' `
    --environment-variables ('TextUrl=https://{0}/api/fredtext' -f $apiFqdn)`
    --query configuration.ingress.fqdn `
    --out tsv


az containerapp update `
    --name wd-sample-api `
    --resource-group $RESOURCE_GROUP `
    --environment-variables 'Value=Hi Meetup 🙋‍♀️' `
    --tags 'version=woman'