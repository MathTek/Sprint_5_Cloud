#!/bin/bash

# ========================================
# Apply All Environments
# ========================================

set -e

echo "🚀 Deploying ALL environments (Dev, Staging, Prod)..."
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if RDS password is provided
if [ -z "$RDS_PASSWORD" ]; then
    echo -e "${YELLOW} RDS_PASSWORD environment variable not set${NC}"
    read -s -p "Enter RDS password for Prod: " RDS_PASSWORD
    echo ""
fi

# DEV
echo -e "${GREEN}[1/3] Applying DEV environment...${NC}"
cd environments/dev
terraform init -upgrade
terraform apply -auto-approve
cd ../..
echo -e "${GREEN} DEV deployed${NC}"
echo ""

# STAGING
echo -e "${GREEN}[2/3] Applying STAGING environment...${NC}"
cd environments/staging
terraform init -upgrade
terraform apply -auto-approve
cd ../..
echo -e "${GREEN} STAGING deployed${NC}"
echo ""

# PROD
echo -e "${GREEN}[3/3] Applying PRODUCTION environment...${NC}"
cd environments/prod
terraform init -upgrade
terraform apply -auto-approve -var="rds_password=$RDS_PASSWORD"
cd ../..
echo -e "${GREEN} PROD deployed${NC}"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} ALL ENVIRONMENTS DEPLOYED SUCCESSFULLY!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "📊 Getting outputs..."
echo ""

for env in dev staging prod; do
    echo -e "${YELLOW}=== $env outputs ===${NC}"
    cd environments/$env
    terraform output 2>/dev/null | head -5
    cd ../..
    echo ""
done
