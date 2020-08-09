#!/bin/bash

#Declare some colors.
RED="\033[1;31m"
GREEN="\033[1;32m"
NOCOLOR="\033[0m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"

#TODO: Add help to bash script

#unset choice
unset UserChoice

#Take Parameters.
while getopts t:s:o:d:u:a:p:d: flag
do
    case "${flag}" in
        t) tenantId=${OPTARG};;
        s) subscriptionId=${OPTARG};;
        o) orgName=${OPTARG};;
        d) deployRegion=${OPTARG};;
        u) azureDevopsUsername=${OPTARG};;
        a) azureDevopsURL=${OPTARG};;
        p) azureDevopsPAT=${OPTARG};;
        d) destroy=${OPTARG};;
    esac
done

echo -e "${BLUE}    ___                           ______                      __          ";
echo -e "${BLUE}   /   |____  __  __________     / ____/___  __  ______  ____/ /______  __";
echo -e "${BLUE}  / /| /_  / / / / / ___/ _ \   / /_  / __ \/ / / / __ \/ __  / ___/ / / /";
echo -e "${BLUE} / ___ |/ /_/ /_/ / /  /  __/  / __/ / /_/ / /_/ / / / / /_/ / /  / /_/ / ";
echo -e "${BLUE}/_/  |_/___/\__,_/_/   \___/  /_/    \____/\__,_/_/ /_/\__,_/_/   \__, /  ";
echo -e "${BLUE}                                                                 /____/   ";

echo 
echo -e "${GREEN}Welcome to the Azure Foundry initialiser script!${NOCOLOR}"
echo -e "This script is the singular manual task available required for this service, it should only need to be run ONCE."
echo 
echo

echo -e "${GREEN}Checking input arguments${NOCOLOR}"
while [[ "$UserChoice" != [yY] ]]
do
    if [ -z "$orgName" ]
    then
        read -p "Enter Organisation Shortname (3-7 chars): " orgName
    fi
    if [ -z "$deployRegion" ]
    then
        read -p "Please provide deployment region: " deployRegion
    fi
    if [ -z "$tenantId" ]
    then
        read -p "Please provide Tenant ID: " tenantId
    fi
    if [ -z "$subscriptionId" ]
    then
        read -p "Please provide Subscription ID: " subscriptionId
    fi
    if [ -z "$azureDevopsURL" ]
    then
        read -p "Please provide Azure Devops URL: " azureDevopsURL
    fi
    if [ -z "$azureDevopsUsername" ]
    then
        read -p "Please provide Azure Devops Username: " azureDevopsUsername
    fi
    if [ -z "$azureDevopsPAT" ]
    then
        read -s -p "Please provide Azure Devops PAT: " azureDevopsPAT
    fi
    #provide validation
    echo
    echo "The following details have been provided and will be used:"
    echo "TenantId: $tenantId"
    echo "Subscription Id: $subscriptionId"
    echo "Deploy Region: $deployRegion"
    echo "Org Shortname: $orgName"
    echo "Azure Devops Organisation: $azureDevopsURL"
    echo "Azure Devops Username: $azureDevopsUsername"
    echo "Azure Devops PAT not shown"
    echo

    read -p "Would you like to proceed with these details? " -n 1 -r UserChoice
    if [[ "$UserChoice" != [yY] ]]
    then 
        unset tenantId
        unset subscriptionId
        unset deployRegion
        unset orgName
        unset azureDevopsURL
        unset azureDevopsUsername
        unset azureDevopsPAT
    fi
    echo
done
#update string to match case
orgLower=$(echo "$orgName" | awk '{print tolower($0)}')
orgUpper=$(echo "$orgName" | awk '{print toupper($0)}')
echo "All variables provided"

echo
echo
echo -e "${GREEN}Removing parent repo for foundry operations${NOCOLOR}"
rm -rf ./.git

echo
echo
echo -e "${GREEN}Checking Dependencies${NOCOLOR}"
if ! command -v az --version &> /dev/null
then
    echo -e "${RED} Azure CLI could not be found, please install before execution ${NOCOLOR} "
    exit
else
    echo "Azure CLI has been installed"
fi

if ! command -v jq --version &> /dev/null
then
    echo -e "${RED} JQ could not be found, please install before execution ${NOCOLOR} "
    exit
else
    echo "JQ has been installed"
fi


echo
echo
echo -e "${GREEN}Authenticating to Azure CLI${NOCOLOR}"
az login --tenant $tenantId
az account set --subscription $subscriptionId

echo
echo
echo -e "${GREEN}Creating Storage Account for state storage${NOCOLOR}"
echo
echo "Resource Group deployment"
az group create --location $deployRegion --name "${orgUpper}-AF-STATE-RG" 
echo
echo "Storage Account deployment"
while ! az storage account create -n "${orgLower}afstate" -g "${orgUpper}-AF-STATE-RG" -l $deployRegion --sku Standard_GRS #GRS is a bit better for safety of state data
do
    echo "Waiting for resource group..." #sometimes az cli is too slow 
done
az storage container create --name "azurefoundrystate" --account-name "${orgLower}afstate" --auth-mode login
echo
echo "Applying resource locks to protect state"
az lock create --name "azure-foundry-rg-lock" --resource-group "${orgUpper}-AF-STATE-RG" --lock-type CanNotDelete
az lock create --name "azure-foundry-storage-lock" --resource-group "${orgUpper}-AF-STATE-RG" --lock-type CanNotDelete --resource-type Microsoft.Storage/storageAccounts --resource "${orgLower}afstate"

backend_storage_account_key=$(az storage account keys list -g "${orgUpper}-AF-STATE-RG" -n "${orgLower}afstate" | jq -r .[1].value;)
export ARM_ACCESS_KEY=$backend_storage_account_key


azureFoundry_Service_Principal=$(az ad sp create-for-rbac --name http://azure-foundry-parent-sp --skip-assignment)
while ! az role assignment create --assignee http://azure-foundry-parent-sp --role "Owner" --scope "/providers/Microsoft.Management/managementGroups/$tenantId" #GRS is a bit better for safety of state data
do
    echo "Waiting for service principal replication" #sometimes az cli is too slow 
done

az logout

cd ./Foundry-Base
echo $backend_storage_account_key
echo "Initialising Terraform."
terraform init \
-backend-config="storage_account_name=${orgLower}afstate" \
-backend-config="container_name=azurefoundrystate" \
-backend-config="key=azurefoundrybase.terraform.tfstate" 

echo "Completing Terraform Plan"
terraform plan -var="personal_access_token=$azureDevopsPAT" -var="org_service_url=$azureDevopsURL"

echo "Completing Terraform Apply"
terraform apply -auto-approve -var="personal_access_token=$azureDevopsPAT" -var="org_service_url=$azureDevopsURL"

#terraform destroy
#rm -rf ./.git

azureFoundry_Projects_Repo=$(terraform output ssh_url_projects)
azureFoundry_Mgmt_Repo=$(terraform output ssh_url_mgmt)

#Create a variable group
curl -u "$azureDevopsUsername:$azureDevopsPAT" --header "Content-Type: application/json" --request POST  "$azureDevopsURL/Azure%20Foundry/_apis/distributedtask/variablegroups?api-version=5.1-preview.1" --data "{
\"variables\": {
    \"backend_storage_account_name\": {
        \"value\": \"${orgLower}afstate\"
    },
    \"backend_container_name\": {
        \"value\": \"azurefoundrystate\"
    },
    \"foundry_project_backend_key\": {
        \"value\": \"azurefoundrybase.terraform.tfstate\"
    },
    \"foundry_mgmt_backend_key\": {
        \"value\": \"azurefoundrymgmt.terraform.tfstate\"
    },
    \"ARM_CLIENT_ID\": {
        \"value\": \"$(echo $azureFoundry_Service_Principal | jq .appId -r)\"
    },
    \"ARM_SUBSCRIPTION_ID\": {
        \"value\": \"$subscriptionId\"
    },
    \"ARM_TENANT_ID\": {
        \"value\": \"$(echo $azureFoundry_Service_Principal | jq .tenant -r)\"
    },
    \"ARM_CLIENT_SECRET\": {
        \"value\": \"$(echo $azureFoundry_Service_Principal | jq .password -r)\",
        \"isSecret\": true
    },
    \"ARM_ACCESS_KEY\": {
        \"value\": \"$ARM_ACCESS_KEY\",
        \"isSecret\": true
    },
    \"org_service_url\": {
        \"value\": \"$azureDevopsURL\"
    },
    \"personal_access_token\": {
        \"value\": \"$azureDevopsPAT\",
        \"isSecret\": true
    }
},
\"type\": \"Vsts\",
\"name\": \"Azure-Foundry-Variable-Group\",
\"description\": \"Holds configuration relevant to the deployment of Azure Resources & storage of terraform state\"
}"

git init 
git add . 
git commit -m "Azure Foundry - First Commit"
git remote add origin $azureFoundry_Projects_Repo
git push -u origin --all
cd ..

cd ./Foundry-Mgmt-Groups
git init 
git add . 
git commit -m "Azure Foundry - First Commit"
git remote add origin $azureFoundry_Mgmt_Repo
git push -u origin --all
cd ..

#TODO: Automate creation of pipeline using API - Maybe wait for the terraform module to include this functionality?

echo -e "${GREEN}The Azure Foundry installer script has successfully deployed into your environment!${NOCOLOR}"