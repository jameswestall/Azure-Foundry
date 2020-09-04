#!/bin/bash

cd ./Foundry-Base
rm -rf ./.git

terraform destroy -auto-approve \
    -var="personal_access_token=$azureDevopsPAT" \
    -var="org_service_url=$azureDevopsURL" \
    -var="subscription_id=$subscriptionId" \
    -var="client_id=$(echo $azureFoundry_Service_Principal | jq .appId -r)" \
    -var="client_secret=$(echo $azureFoundry_Service_Principal | jq .password -r)" \
    -var="tenant_id=$tenantId" 

cd ..
cd ./Foundry-Mgmt-Groups
rm -rf ./.git
cd ..
git init

