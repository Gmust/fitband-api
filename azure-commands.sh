#!/bin/bash
# Azure CLI Commands - Copy and paste these commands one by one
# Run these in Azure Cloud Shell or your local terminal with Azure CLI installed

# ============================================
# STEP 1: Login to Azure (if not already logged in)
# ============================================
az login

# ============================================
# STEP 2: Set Variables (EDIT THESE IF NEEDED)
# ============================================
RESOURCE_GROUP="mock-fitband-rg"
VM_NAME="mock-fitband-api-vm"
LOCATION="eastus"  # Options: eastus, westus, westeurope, southeastasia, etc.
VM_SIZE="Standard_B2ms"  # 2 vCPU, 8GB RAM (or Standard_B2s for 4GB RAM)
ADMIN_USERNAME="azureuser"

# ============================================
# STEP 3: Create Resource Group
# ============================================
az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION"

# ============================================
# STEP 4: Create Virtual Machine
# ============================================
az vm create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VM_NAME" \
    --image Ubuntu2204 \
    --size "$VM_SIZE" \
    --admin-username "$ADMIN_USERNAME" \
    --generate-ssh-keys \
    --public-ip-sku Standard

# ============================================
# STEP 5: Open Ports (80 for HTTP, 443 for HTTPS, 8080 for API)
# IMPORTANT: Each port must have a UNIQUE priority number
# ============================================
az vm open-port \
    --port 80 \
    --priority 1000 \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VM_NAME" \
    --output table

az vm open-port \
    --port 443 \
    --priority 1001 \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VM_NAME" \
    --output table

az vm open-port \
    --port 8080 \
    --priority 1002 \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VM_NAME" \
    --output table

# ============================================
# STEP 6: Get Public IP Address
# ============================================
az vm show \
    -d \
    -g "$RESOURCE_GROUP" \
    -n "$VM_NAME" \
    --query publicIps -o tsv

# ============================================
# DONE! Use the IP address from step 6 to SSH:
# ssh azureuser@<PUBLIC_IP>
# ============================================

