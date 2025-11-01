#!/bin/bash
# Azure VM Creation Script for Mock Fitband API
# This script creates a resource group and VM on Azure

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration - EDIT THESE VALUES
RESOURCE_GROUP="mock-fitband-rg"
VM_NAME="mock-fitband-api-vm"
LOCATION="eastus"  # Change to your preferred region (eastus, westus, westeurope, etc.)
VM_SIZE="Standard_B2ms"  # 2 vCPU, 8GB RAM (or use Standard_B2s for 4GB RAM)
ADMIN_USERNAME="azureuser"
SSH_KEY_PATH="~/.ssh/id_rsa.pub"  # Path to your SSH public key

echo -e "${BLUE}Creating Azure VM for Mock Fitband API...${NC}"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${YELLOW}Azure CLI not found. Please install it first:${NC}"
    echo "  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
    exit 1
fi

# Check if logged in
echo -e "${BLUE}Checking Azure login status...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}Not logged in to Azure. Please login:${NC}"
    az login
fi

echo -e "${BLUE}Current subscription:${NC}"
az account show --query "name" -o tsv
echo ""

# Prompt to continue
read -p "Do you want to continue with VM creation? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Create resource group
echo -e "${BLUE}Creating resource group: ${RESOURCE_GROUP}...${NC}"
az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --output table

# Create VM
echo -e "${BLUE}Creating VM: ${VM_NAME}...${NC}"
echo -e "${YELLOW}This may take a few minutes...${NC}"

az vm create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VM_NAME" \
    --image Ubuntu2204 \
    --size "$VM_SIZE" \
    --admin-username "$ADMIN_USERNAME" \
    --generate-ssh-keys \
    --public-ip-sku Standard \
    --output table

# Open ports
echo -e "${BLUE}Opening ports 80 and 443...${NC}"
az vm open-port \
    --port 80 \
    --priority 1000 \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VM_NAME"

az vm open-port \
    --port 443 \
    --priority 1001 \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VM_NAME"

# Get public IP
echo -e "${BLUE}Getting VM public IP address...${NC}"
PUBLIC_IP=$(az vm show \
    -d \
    -g "$RESOURCE_GROUP" \
    -n "$VM_NAME" \
    --query publicIps -o tsv)

echo ""
echo -e "${GREEN}✓ VM created successfully!${NC}"
echo ""
echo -e "${BLUE}VM Details:${NC}"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  VM Name: $VM_NAME"
echo "  Location: $LOCATION"
echo "  Size: $VM_SIZE"
echo "  Public IP: $PUBLIC_IP"
echo "  Admin Username: $ADMIN_USERNAME"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. SSH into the VM:"
echo "     ssh $ADMIN_USERNAME@$PUBLIC_IP"
echo ""
echo "  2. On the VM, run:"
echo "     sudo mkdir -p /opt/mock-fitband-api"
echo "     sudo chown \$USER:\$USER /opt/mock-fitband-api"
echo "     cd /opt/mock-fitband-api"
echo ""
echo "  3. Copy your application files and follow AZURE_QUICK_START.md"
echo ""

