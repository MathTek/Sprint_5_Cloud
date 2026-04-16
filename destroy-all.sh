    #!/bin/bash

# ========================================
# Destroy All Environments
# ========================================

set -e

echo " DESTROYING ALL environments (Dev, Staging, Prod)..."
echo ""

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Confirmation
read -p " Are you SURE? This will DELETE all resources! (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo ""

# Check if RDS password is provided
if [ -z "$RDS_PASSWORD" ]; then
    echo -e "${YELLOW}  RDS_PASSWORD environment variable not set${NC}"
    read -s -p "Enter RDS password for Prod (needed for destroy): " RDS_PASSWORD
    echo ""
fi

# PROD (destroy first, it's most critical)
echo -e "${RED}[1/3] Destroying PRODUCTION environment...${NC}"
cd environments/prod
terraform destroy -auto-approve -var="rds_password=$RDS_PASSWORD"
cd ../..
echo -e "${RED} PROD destroyed${NC}"
echo ""

# STAGING
echo -e "${RED}[2/3] Destroying STAGING environment...${NC}"
cd environments/staging
terraform destroy -auto-approve
cd ../..
echo -e "${RED} STAGING destroyed${NC}"
echo ""

# DEV
echo -e "${RED}[3/3] Destroying DEV environment...${NC}"
cd environments/dev
terraform destroy -auto-approve
cd ../..
echo -e "${RED} DEV destroyed${NC}"
echo ""

echo -e "${RED}========================================${NC}"
echo -e "${RED} ALL ENVIRONMENTS DESTROYED!${NC}"
echo -e "${RED}========================================${NC}"
