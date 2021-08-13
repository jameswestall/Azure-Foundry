set -Eeo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

TF_LOG_PATH=./tftrace.log
TF_LOG=Trace

usage() {
    cat <<EOF

The Azure Foundry script is responsible for completing initial provisioning actions within an Azure tenant and Azure DevOps organisation.
Execution of this script should be required only once per environment, with followon actions completed via Azure DevOps.

USAGE
$(basename "${BASH_SOURCE[0]}") -o "Contoso" -t "00000000-0000-0000-0000-000000000000" -s "00000000-0000-0000-0000-000000000000"   -d "australiasoutheast" -a "https://dev.azure.com/foundryorg"  -u "johnsmith@contoso.com" -p "supersecretrandompersonalaccesstoken"

OPTIONS
-o,  --organisation              Organization name to be used throughout the deployment   
-t,  --tenantId                  Azure AD tenant ID  
-s,  --subscriptionId            Subscription ID for initial deployment  
-d,  --deployRegion              Initial deployment region   
-a,  --azureDevOpsOrgUrl         Azure DevOps URL for your organisation    
-u,  --azureDevOpsUserAccount    Azure DevOps user account for PAT (Ideally a service account)    
-p,  --azureDevOpsPAT            Azure DevOps Personal Access Token
-V,  --version                   Print script version info
-v,  --verbose                   Print script debug info during execution
-h,  --help                      Print this help and exit
-nc, --no-color                  Print script without color

EOF
    exit
}

version() {
cat <<EOF

Azure Foundry: Version 1.0
Release Date: 10-02-2021

EOF
    exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_dependencies() {
    msg "${GREEN}Checking Dependencies${NOFORMAT}"
    if ! command -v az --version &> /dev/null
    then
        die "${RED} Azure CLI could not be found, please install before execution ${NOFORMAT} "
        exit
    else
        msg "Azure CLI is installed"
    fi

    if ! command -v jq --version &> /dev/null
    then
        die "${RED} JQ could not be found, please install before execution ${NOFORMAT} "
        exit
    else
        msg "JQ is installed"
    fi

    msg ""
}

parse_params() {
  # default values of variables set from params
  # -f | --flag) flag=1 ;; # example flag
  
  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -V | --version) version ;;
    -v | --verbose) set -x ;;
    -nc | --no-color) NO_COLOR=1 ;;
    -o | --organisation)
      organisation="${2-}"
      shift
      ;;
    -t | --tenantId)
      tenantId="${2-}"
      shift
      ;;
    -s | --subscriptionId)
      subscriptionId="${2-}"
      shift
      ;;
    -d | --deployRegion)
      deployRegion="${2-}"
      shift
      ;;
    -a | --azureDevOpsOrgUrl)
      azureDevOpsOrgUrl="${2-}"
      shift
      ;;
    -u | --azureDevOpsUserAccount)
      azureDevOpsUserAccount="${2-}"
      shift
      ;;
    -p | --azureDevOpsPAT)
      azureDevOpsPAT="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done
  args=("$@")

    return 0
}

parse_params "$@"
setup_colors

msg "${BLUE}    ___                           ______                      __          ";
msg "${BLUE}   /   |____  __  __________     / ____/___  __  ______  ____/ /______  __";
msg "${BLUE}  / /| /_  / / / / / ___/ _ \   / /_  / __ \/ / / / __ \/ __  / ___/ / / /";
msg "${BLUE} / ___ |/ /_/ /_/ / /  /  __/  / __/ / /_/ / /_/ / / / / /_/ / /  / /_/ / ";
msg "${BLUE}/_/  |_/___/\__,_/_/   \___/  /_/    \____/\__,_/_/ /_/\__,_/_/   \__, /  ";
msg "${BLUE}                                                                 /____/   ";

msg ""



msg 
msg "${GREEN}Welcome to the Azure Foundry initialiser script!${NOFORMAT}"
msg "This script is the only manual task required to initialise the Azure Foundry, it should only need to be run ONCE."
msg "For more info, check the project readme."
msg 

parse_dependencies

# check required params and arguments
msg "${GREEN}Checking input arguments${NOFORMAT}"
[[ -z "${organisation-}" ]] && die "${RED}Missing required parameter:${NOFORMAT} -o | --organisation"
[[ -z "${tenantId-}" ]] && die "${RED}Missing required parameter:${NOFORMAT} -t | --tenantId"
[[ -z "${subscriptionId-}" ]] && die "${RED}Missing required parameter:${NOFORMAT} -s | subscriptionId"
[[ -z "${deployRegion-}" ]] && die "${RED}Missing required parameter:${NOFORMAT} -d | deployRegion"
[[ -z "${azureDevOpsOrgUrl-}" ]] && die "${RED}Missing required parameter:${NOFORMAT} -a | azureDevOpsOrgUrl"
[[ -z "${azureDevOpsUserAccount-}" ]] && die "${RED}Missing required parameter:${NOFORMAT} -u | azureDevOpsUserAccount"
[[ -z "${azureDevOpsPAT-}" ]] && die "${RED}Missing required parameter:${NOFORMAT} -p | azureDevOpsPAT"
#[[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"
msg "Complete"

#display user confirmation prompt & override
while [[ "$UserChoice" != [yY] ]]
do
    msg ""
    msg "${GREEN}The following details have been provided and will be used: ${NOFORMAT}"
    msg "TenantId: $tenantId"
    msg "Subscription Id: $subscriptionId"
    msg "Deploy Region: $deployRegion"
    msg "Org Shortname: $organisation"
    msg "Azure Devops URL: $azureDevOpsOrgUrl"
    msg "Azure Devops Username: $azureDevOpsUserAccount"
    msg "Azure Devops PAT not shown"
    msg ""

    msg "${YELLOW}WARNING: ${NOFORMAT}This script will create a highly privileged service principal with access to both Azure and Azure AD!"
    msg "${YELLOW}WARNING: ${NOFORMAT}This service can manage, Users, Groups and Azure AD Service principals in ADDITION to having full administrative access to ALL Azure resources within your tenant."
    msg "${YELLOW}WARNING: ${NOFORMAT}You should ensure that the credentials for this account are securely stored and you understand the impact if this account were to be compromised."
    msg "${YELLOW}WARNING: ${NOFORMAT}A detailed credential rotation plan/process is highly reccommended."
    msg ""
    read -p "Would you like to proceed with provisioning, understanding the risk associated with this Service Principal? (y/n): " -n 1 -r UserChoice
    msg ""
    if [[ "$UserChoice" != [yY] ]]
    then 
        msg ""
        msg "${GREEN}The Azure Foundry script has been terminated, no provisioning has occured.${NOFORMAT}"
        exit
    fi

    read -p "Would you like to proceed with the above input arguments? (y/n): " -n 1 -r UserChoice
    msg " "
    msg " "
    if [[ "$UserChoice" != [yY] ]]
    then 
        unset tenantId
        unset subscriptionId
        unset deployRegion
        unset organisation
        unset azureDevopsURL
        unset azureDevopsUsername
        unset azureDevopsPAT

        if [ -z "$organisation" ]
        then
            read -p "Please provide an Organisation name (3-7 chars): " organisation
        fi
        if [ -z "$deployRegion" ]
        then
            read -p "Please provide a deployment region: " deployRegion
        fi
        if [ -z "$tenantId" ]
        then
            read -p "Please provide a Tenant ID: " tenantId
        fi
        if [ -z "$subscriptionId" ]
        then
            read -p "Please provide a Subscription ID: " subscriptionId
        fi
        if [ -z "$azureDevOpsOrgUrl" ]
        then
            read -p "Please provide a Azure Devops URL: " azureDevopsURL
        fi
        if [ -z "$azureDevOpsUserAccount" ]
        then
            read -p "Please provide a Azure Devops Username: " azureDevopsUsername
        fi
        if [ -z "$azureDevOpsPAT" ]
        then
            read -s -p "Please provide a Azure Devops PAT: " azureDevopsPAT
        fi
        #provide validation
        msg " "
        msg "Complete."
        msg " "
    fi
    msg ""
done


# update organisation string to match case
orgLower=$(echo "$organisation" | awk '{print tolower($0)}')
orgUpper=$(echo "$organisation" | awk '{print toupper($0)}')

msg
msg
msg "${GREEN}Removing source Azure Foundry repo.${NOCOLOR}"
# rm -rf ./.git

msg ""
msg "${GREEN}Authenticating to Azure CLI${NOFORMAT}"
az login --tenant $tenantId
az account set --subscription $subscriptionId

msg
msg
msg "${GREEN}Creating Storage Account for state storage${NOFORMAT}"
msg ""
msg "Resource Group deployment"
az group create --location $deployRegion --name "${orgUpper}-AF-STATE-RG"  --tags BillingCode='' CreationTicket='' Service='Terraform State Storage' Owner="${organisation}" createdBy='Azure Foundry' Environment='Platform' ExpiryDate='Never'
msg ""

msg "Storage Account deployment"
while ! az storage account create -n "${orgLower}afstate" -g "${orgUpper}-AF-STATE-RG" -l $deployRegion --tags BillingCode="" CreationTicket="" Service="Terraform State Storage" Owner="${organisation}" createdBy="Azure Foundry" Environment="Platform" ExpiryDate="Never" --sku Standard_GRS #GRS is better for redundancy of state data than LRS
do
    msg "Waiting for resource group..." #sometimes az cli is too slow 
done
az storage container create --name "azurefoundrystate" --account-name "${orgLower}afstate" --auth-mode login
msg
msg "Applying resource locks to protect state"
az lock create --name "azure-foundry-rg-lock" --resource-group "${orgUpper}-AF-STATE-RG" --lock-type CanNotDelete
az lock create --name "azure-foundry-storage-lock" --resource-group "${orgUpper}-AF-STATE-RG" --lock-type CanNotDelete --resource-type Microsoft.Storage/storageAccounts --resource "${orgLower}afstate"

export ARM_ACCESS_KEY=$(az storage account keys list -g "${orgUpper}-AF-STATE-RG" -n "${orgLower}afstate" | jq -r .[1].value;)

azureFoundry_Service_Principal=$(az ad sp create-for-rbac --name http://azure-foundry-parent-sp --skip-assignment)
azureFoundry_Service_PrincipalAppId=$(echo $azureFoundry_Service_Principal | jq -r .appId)
azureFoundry_Service_PrincipalSecret=$(echo $azureFoundry_Service_Principal | jq .password -r)
while ! az role assignment create --assignee http://azure-foundry-parent-sp --role "Owner" --scope "/providers/Microsoft.Management/managementGroups/$tenantId" 
do
    msg "Waiting for service principal replication" #sometimes az cli is too slow 
done

# Created SP uses Azure AD Graph API over the Microsoft Graph API, as this is currently required for Terraform support. 
# AZ CLI still uses Azure AD Graph for 'az ad app/sp' requests with 'az rest' available for for MS Graph. 
# https://github.com/Azure/azure-cli/issues/12946
# https://www.terraform.io/docs/providers/azuread/guides/service_principal_configuration.html#method-2-api-access-with-admin-consent

#get Azure AD Graph API permissions
azure_ad_graph_application=$(az ad sp list --display-name 'Windows Azure Active Directory')

#get Azure AD Role Definition id for application admin (Owned By)
azure_ad_application_admin_role_id=$(echo $azure_ad_graph_application | jq -r -c '.[0].appRoles[] | select(.value | contains("Application.ReadWrite.OwnedBy")) | .id')

#Assign Application Management permissions to Service Principal
graphurl="https://graph.microsoft.com/beta/servicePrincipals/$(echo $azure_ad_graph_application | jq -r -c '.[0].objectId')/appRoleAssignments" 
graphrequest="{\"principalId\": $(az ad sp show --id $azureFoundry_Service_PrincipalAppId --query objectId),\"resourceId\": \"$(echo $azure_ad_graph_application | jq -r -c '.[0].objectId')\",\"appRoleId\": \"$azure_ad_application_admin_role_id\"}"

curl --location --request POST  $graphurl \
--header "Authorization: Bearer $(az account get-access-token --resource https://graph.microsoft.com | jq -r .\accessToken)" \
--header 'Content-Type: application/json' \
--data-raw "$graphrequest"

#TODO: Pending Microsoft Graph update for azuread terraform, develop fine grained permissions.
#Assign Directory ReadWrite All permissions to Service Principal (Create Groups)
azure_ad_group_admin_role_id=$(echo $azure_ad_graph_application | jq -r -c '.[0].appRoles[] | select(.value | contains("Directory.ReadWrite.All")) | .id')
graphrequest="{\"principalId\": $(az ad sp show --id $azureFoundry_Service_PrincipalAppId --query objectId),\"resourceId\": \"$(echo $azure_ad_graph_application | jq -r -c '.[0].objectId')\",\"appRoleId\": \"$azure_ad_group_admin_role_id\"}"

curl --location --request POST  $graphurl \
--header "Authorization: Bearer $(az account get-access-token --resource https://graph.microsoft.com | jq -r .\accessToken)" \
--header 'Content-Type: application/json' \
--data-raw "$graphrequest"

#Assign User Account Administrator (Delete Groups in Terraform)
#fe930be7-5e62-47db-91af-98c3a49a38b1 = User Account Administrator
graphrequest="{\"principalId\": $(az ad sp show --id $azureFoundry_Service_PrincipalAppId --query objectId),\"roleDefinitionId\":\"fe930be7-5e62-47db-91af-98c3a49a38b1\",\"directoryScopeId\":\"/\"}"

curl --location --request POST "https://graph.microsoft.com/beta/roleManagement/directory/roleAssignments" \
--header "Authorization: Bearer $(az account get-access-token --resource https://graph.microsoft.com | jq -r .\accessToken)" \
--header 'Content-Type: application/json' \
--data-raw "$graphrequest"

az logout

msg ""
msg "${GREEN} Initialising Terraform. ${NOFORMAT}"

cd ./Foundry-Base

terraform init \
    -backend-config="storage_account_name=${orgLower}afstate" \
    -backend-config="container_name=azurefoundrystate" \
    -backend-config="key=azurefoundrybase.terraform.tfstate" \

msg "Completing Terraform Plan"

#Required as a workaround to this issue: https://github.com/microsoft/terraform-provider-azuredevops/issues/296
export AZDO_PERSONAL_ACCESS_TOKEN=$azureDevOpsPAT
export AZDO_ORG_SERVICE_URL=$azureDevOpsOrgUrl

msg "terraform plan \
    -var=\"personal_access_token=$azureDevOpsPAT\" \
    -var=\"org_service_url=$azureDevOpsOrgUrl\" \
    -var=\"subscription_id=$subscriptionId\" \
    -var=\"client_id=$azureFoundry_Service_PrincipalAppId\" \
    -var=\"client_secret=$azureFoundry_Service_PrincipalSecret\" \
    -var=\"tenant_id=$tenantId\" \
    -var=\"backend_storage_account_key=$ARM_ACCESS_KEY\" \
    -var=\"backend_storage_account_name=${orgLower}afstate\" \
"

terraform plan \
    -var="personal_access_token=$azureDevOpsPAT" \
    -var="org_service_url=$azureDevOpsOrgUrl" \
    -var="subscription_id=$subscriptionId" \
    -var="client_id=$azureFoundry_Service_PrincipalAppId" \
    -var="client_secret=$azureFoundry_Service_PrincipalSecret" \
    -var="tenant_id=$tenantId" \
    -var="backend_storage_account_key=$ARM_ACCESS_KEY" \
    -var="backend_storage_account_name=${orgLower}afstate" \

    
msg "Completing Terraform Apply"

msg "terraform apply -auto-approve \
    -var=\"personal_access_token=$azureDevOpsPAT\" \
    -var=\"org_service_url=$azureDevOpsOrgUrl\" \
    -var=\"subscription_id=$subscriptionId\" \
    -var=\"client_id=$azureFoundry_Service_PrincipalAppId\" \
    -var=\"client_secret=$(msg $azureFoundry_Service_Principal | jq .password -r)\" \
    -var=\"tenant_id=$tenantId\" \
    -var=\"backend_storage_account_key=$ARM_ACCESS_KEY\" \
    -var=\"backend_storage_account_name=${orgLower}afstate\" \
"

terraform apply -auto-approve \
    -var="personal_access_token=$azureDevOpsPAT" \
    -var="org_service_url=$azureDevOpsOrgUrl" \
    -var="subscription_id=$subscriptionId" \
    -var="client_id=$azureFoundry_Service_PrincipalAppId" \
    -var="client_secret=$azureFoundry_Service_PrincipalSecret" \
    -var="tenant_id=$tenantId" \
    -var="backend_storage_account_key=$ARM_ACCESS_KEY" \
    -var="backend_storage_account_name=${orgLower}afstate" \

#Ensure no Git Repo initialised in current directory
rm -rf ./.git

#azureFoundry_Projects_Repo=$(terraform output ssh_url_projects)
#azureFoundry_Mgmt_Repo=$(terraform output ssh_url_mgmt)

# #Create a variable group
# curl -u "$azureDevopsUsername:$azureDevopsPAT" --header "Content-Type: application/json" --request POST  "$azureDevopsURL/Azure%20Foundry/_apis/distributedtask/variablegroups?api-version=5.1-preview.1" --data "{
# \"variables\": {
#     \"backend_storage_account_name\": {
#         \"value\": \"${orgLower}afstate\"
#     },
#     \"backend_container_name\": {
#         \"value\": \"azurefoundrystate\"
#     },
#     \"foundry_project_backend_key\": {
#         \"value\": \"azurefoundrybase.terraform.tfstate\"
#     },
#     \"foundry_mgmt_backend_key\": {
#         \"value\": \"azurefoundrymgmt.terraform.tfstate\"
#     },
#     \"ARM_CLIENT_ID\": {
#         \"value\": \"$(msg $azureFoundry_Service_Principal | jq .appId -r)\"
#     },
#     \"ARM_SUBSCRIPTION_ID\": {
#         \"value\": \"$subscriptionId\"
#     },
#     \"ARM_TENANT_ID\": {
#         \"value\": \"$(msg $azureFoundry_Service_Principal | jq .tenant -r)\"
#     },
#     \"ARM_CLIENT_SECRET\": {
#         \"value\": \"$(msg $azureFoundry_Service_Principal | jq .password -r)\",
#         \"isSecret\": true
#     },
#     \"ARM_ACCESS_KEY\": {
#         \"value\": \"$ARM_ACCESS_KEY\",
#         \"isSecret\": true
#     },
#     \"org_service_url\": {
#         \"value\": \"$azureDevopsURL\"
#     },
#     \"personal_access_token\": {
#         \"value\": \"$azureDevopsPAT\",
#         \"isSecret\": true
#     }
# },
# \"type\": \"Vsts\",
# \"name\": \"Azure-Foundry-Variable-Group\",
# \"description\": \"Holds configuration relevant to the deployment of Azure Resources & storage of terraform state\"
# }"

# git init 
# git add . 
# git commit -m "Azure Foundry - First Commit"
# git remote add origin $azureFoundry_Projects_Repo
# git push -u origin --all
# cd ..

# cd ./Foundry-Mgmt-Groups
# git init 
# git add . 
# git commit -m "Azure Foundry - First Commit"
# git remote add origin $azureFoundry_Mgmt_Repo
# git push -u origin --all
# cd ..

msg "${GREEN}The Azure Foundry installer script has successfully deployed into your environment!${NOFORMAT}"