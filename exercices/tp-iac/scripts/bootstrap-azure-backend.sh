#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

: "${AZ_RESOURCE_GROUP:?Définissez AZ_RESOURCE_GROUP.}"
: "${AZ_STORAGE_ACCOUNT:?Définissez AZ_STORAGE_ACCOUNT avec un nom globalement unique.}"
AZ_CONTAINER="${AZ_CONTAINER:-tfstate}"
AZ_LOCATION="${AZ_LOCATION:-francecentral}"

az group create \
    --name "$AZ_RESOURCE_GROUP" \
    --location "$AZ_LOCATION"

az storage account create \
    --name "$AZ_STORAGE_ACCOUNT" \
    --resource-group "$AZ_RESOURCE_GROUP" \
    --location "$AZ_LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false

az storage account blob-service-properties update \
    --account-name "$AZ_STORAGE_ACCOUNT" \
    --resource-group "$AZ_RESOURCE_GROUP" \
    --enable-versioning true

az storage container create \
    --name "$AZ_CONTAINER" \
    --account-name "$AZ_STORAGE_ACCOUNT" \
    --auth-mode login

printf 'Backend Azure prêt : groupe=%s compte=%s conteneur=%s\n' \
    "$AZ_RESOURCE_GROUP" "$AZ_STORAGE_ACCOUNT" "$AZ_CONTAINER"
