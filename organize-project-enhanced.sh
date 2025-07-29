#!/bin/bash

# Enhanced Speculod Project Organization Script
# This script organizes all deployment files, scripts, and documentation into a structured format

set -e

echo "🚀 Starting Enhanced Speculod Project Organization..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Base directory
BASE_DIR="$(pwd)"

echo -e "${BLUE}📁 Organizing Docker Compose files...${NC}"
# Move Docker Compose files
mv docker-compose*.yml deployments/docker-compose/ 2>/dev/null || echo "Some docker-compose files may already be moved"

echo -e "${BLUE}📁 Organizing Dockerfile files...${NC}"
# Move Dockerfile files
mv Dockerfile* deployments/docker/ 2>/dev/null || echo "Some Dockerfile files may already be moved"

echo -e "${BLUE}📁 Organizing GCP Cloud Run files...${NC}"
# Move GCP Cloud Run files
mv gcp-cloudrun*.yaml deployments/gcp/cloud-run/ 2>/dev/null || echo "Some GCP files may already be moved"

echo -e "${BLUE}📁 Organizing GCP Cloud Build files...${NC}"
# Move Cloud Build files
mv cloudbuild*.yaml deployments/gcp/cloud-build/ 2>/dev/null || echo "Some Cloud Build files may already be moved"

echo -e "${BLUE}📁 Organizing Kubernetes files...${NC}"
# Move Kubernetes files
mv k8s*.yaml deployments/kubernetes/ 2>/dev/null || echo "Some k8s files may already be moved"

echo -e "${BLUE}📁 Organizing Supervisor configuration files...${NC}"
# Move Supervisor files
mv supervisord*.conf deployments/supervisor/ 2>/dev/null || echo "Some supervisor files may already be moved"

echo -e "${BLUE}🌐 Organizing Nginx configuration files...${NC}"
# Create nginx directory and move nginx configs
mkdir -p deployments/nginx/
mv nginx*.conf deployments/nginx/ 2>/dev/null || echo "Some nginx configs may already be moved"

echo -e "${BLUE}⚙️ Organizing Configuration files...${NC}"
# Create config directory and move configuration files
mkdir -p config/
mv package.json config/ 2>/dev/null || echo "Package.json may already be moved"
mv requirements*.txt config/ 2>/dev/null || echo "Requirements files may already be moved"
mv config.yml config/ 2>/dev/null || echo "Config.yml may already be moved"
mv buf.yaml config/ 2>/dev/null || echo "Buf.yaml may already be moved"
mv buf.lock config/ 2>/dev/null || echo "Buf.lock may already be moved"
mv build.log config/ 2>/dev/null || echo "Build.log may already be moved"
# Keep local-mainnet-genesis.json in root as it's actively used
echo -e "${YELLOW}  📋 Keeping local-mainnet-genesis.json in root (actively used)...${NC}"

echo -e "${BLUE}🔧 Organizing Shell Scripts...${NC}"

# Create deployment scripts directory
mkdir -p deployments/scripts/

# Deployment scripts (move to deployments/scripts/)
echo -e "${YELLOW}  📋 Moving deployment scripts to deployments/scripts/...${NC}"
mv deploy-*.sh deployments/scripts/ 2>/dev/null || echo "Some deploy scripts may already be moved"
mv setup-*.sh deployments/scripts/ 2>/dev/null || echo "Some setup scripts may already be moved"
mv create-*.sh deployments/scripts/ 2>/dev/null || echo "Some create scripts may already be moved"
mv connect-*.sh deployments/scripts/ 2>/dev/null || echo "Some connect scripts may already be moved"
mv domain-mapping.sh deployments/scripts/ 2>/dev/null || echo "Domain mapping may already be moved"

# Utility and testing scripts (move to scripts/)
echo -e "${YELLOW}  🛠️ Moving utility scripts to scripts/...${NC}"
mv start-*.sh scripts/ 2>/dev/null || echo "Some start scripts may already be moved"
mv test-*.sh scripts/ 2>/dev/null || echo "Some test scripts may already be moved"
mv verify-*.sh scripts/ 2>/dev/null || echo "Some verify scripts may already be moved"
mv network-status.sh scripts/ 2>/dev/null || echo "Network status may already be moved"
mv local-*.sh scripts/ 2>/dev/null || echo "Some local scripts may already be moved"
mv websocket-bridge.sh scripts/ 2>/dev/null || echo "WebSocket bridge may already be moved"
mv startup-script.sh scripts/ 2>/dev/null || echo "Startup script may already be moved"

# Keep organize-project.sh in root
echo -e "${YELLOW}  📋 Keeping organize-project scripts in root for easy access...${NC}"

echo -e "${BLUE}🐍 Organizing Python Scripts...${NC}"

# Utility Python scripts (move to scripts/)
echo -e "${YELLOW}  🛠️ Moving Python utility scripts to scripts/...${NC}"
mv start-combined.py scripts/ 2>/dev/null || echo "Start combined Python may already be moved"
mv websocket-bridge*.py scripts/ 2>/dev/null || echo "WebSocket bridge Python scripts may already be moved"

echo -e "${BLUE}📚 Organizing Documentation files...${NC}"

# Root-level documentation (keep important docs in root)
echo -e "${YELLOW}  📋 Organizing root documentation...${NC}"
mv README_TESTING.md docs/guides/ 2>/dev/null || echo "README_TESTING may already be moved"
mv WEBSOCKET_P2P_BRIDGE.md docs/architecture/ 2>/dev/null || echo "WebSocket P2P bridge doc may already be moved"
echo -e "${YELLOW}  📋 Keeping main README.md and organization docs in root...${NC}"

# Deployment documentation
echo -e "${YELLOW}  📋 Moving deployment guides...${NC}"
mv *DEPLOYMENT*.md docs/deployment/ 2>/dev/null || echo "Some deployment docs may already be moved"
mv *SETUP*.md docs/deployment/ 2>/dev/null || echo "Some setup docs may already be moved"
mv CLOUD_RUN*.md docs/deployment/ 2>/dev/null || echo "Some cloud run docs may already be moved"
mv GCP*.md docs/deployment/ 2>/dev/null || echo "Some GCP docs may already be moved"
mv DOCKER*.md docs/deployment/ 2>/dev/null || echo "Some Docker docs may already be moved"

# User guides
echo -e "${YELLOW}  📖 Moving user guides...${NC}"
mv *GUIDE*.md docs/guides/ 2>/dev/null || echo "Some guide docs may already be moved"
mv QUICK_START.md docs/guides/ 2>/dev/null || echo "Quick start may already be moved"
mv STARTUP_GUIDE.md docs/guides/ 2>/dev/null || echo "Startup guide may already be moved"

# Status and implementation tracking
echo -e "${YELLOW}  📊 Moving status documentation...${NC}"
mv *STATUS*.md docs/status/ 2>/dev/null || echo "Some status docs may already be moved"
mv *IMPLEMENTATION*.md docs/status/ 2>/dev/null || echo "Some implementation docs may already be moved"
mv SUCCESS_STATUS.md docs/status/ 2>/dev/null || echo "Success status may already be moved"
mv BUG_FIX_STATUS.md docs/status/ 2>/dev/null || echo "Bug fix status may already be moved"

# Architecture documentation
echo -e "${YELLOW}  🏗️ Moving architecture documentation...${NC}"
mv *ARCHITECTURE*.md docs/architecture/ 2>/dev/null || echo "Some architecture docs may already be moved"
mv HYBRID_ARCHITECTURE*.md docs/architecture/ 2>/dev/null || echo "Some hybrid architecture docs may already be moved"
mv NETWORK*.md docs/architecture/ 2>/dev/null || echo "Some network docs may already be moved"

echo -e "${GREEN}✅ Enhanced project organization completed!${NC}"
echo -e "${BLUE}📋 Summary of organized structure:${NC}"
echo "  📁 deployments/"
echo "    📁 docker-compose/     - All Docker Compose configurations"
echo "    📁 docker/             - All Dockerfile configurations"
echo "    📁 nginx/              - Nginx configuration files"  
echo "    📁 gcp/"
echo "      📁 cloud-run/        - Google Cloud Run configurations"
echo "      📁 cloud-build/      - Google Cloud Build configurations"
echo "    📁 kubernetes/         - Kubernetes deployment files"
echo "    📁 supervisor/         - Supervisor configuration files"
echo "    📁 scripts/            - Deployment and setup scripts"
echo ""
echo "  📁 config/               - Project configuration files"
echo "    📄 package.json        - Node.js dependencies"
echo "    📄 requirements.txt    - Python dependencies"
echo "    📄 config.yml          - Project configuration"
echo "    📄 buf.yaml           - Protobuf build configuration"
echo "    📄 buf.lock           - Protobuf lock file"
echo "    📄 build.log          - Build output log"
echo ""
echo "  📁 scripts/              - Utility scripts (shell and Python)"
echo "    🔧 Shell scripts        - Service management and testing"
echo "    🐍 Python scripts      - WebSocket bridges and combined services"
echo ""
echo "  📁 docs/"
echo "    📁 deployment/         - Deployment and setup documentation"
echo "    📁 guides/             - User guides and tutorials"
echo "    📁 status/             - Status and implementation tracking"
echo "    📁 architecture/       - Architecture and design documentation"
echo ""
echo "  📄 Root Files:"
echo "    📄 README.md           - Main project documentation"
echo "    📄 local-mainnet-genesis.json - Active genesis file"
echo "    📄 DOCUMENTATION_INDEX.md - Documentation navigation"
echo "    📄 PROJECT_ORGANIZATION_COMPLETE.md - Organization overview"
echo "    📄 SCRIPTS_ORGANIZATION.md - Scripts inventory"
echo ""
echo -e "${YELLOW}🔗 Check the updated documentation index for complete navigation!${NC}"
