#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Ksaers Website Deployment Script ===${NC}\n"

# Check if running as root for some operations
if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}⚠️  Some operations may require sudo${NC}"
fi

# Variables
APP_DIR="/opt/ksaers/app"
REPO_URL="https://github.com/ksaers/KsaersWebsite.git"
BRANCH="main"

# 1. Create directories
echo -e "${YELLOW}1. Creating directories...${NC}"
sudo mkdir -p /opt/ksaers
sudo mkdir -p /opt/ksaers/app
sudo mkdir -p /opt/ksaers/certs
sudo mkdir -p /opt/ksaers/npm-cache
sudo mkdir -p /opt/ksaers/backups
sudo chown -R $USER:$USER /opt/ksaers
sudo chmod -R 755 /opt/ksaers
echo -e "${GREEN}✓ Directories created${NC}\n"

# 2. Clone repository
echo -e "${YELLOW}2. Cloning repository...${NC}"
if [ -d "$APP_DIR/.git" ]; then
    echo -e "${YELLOW}   Repository already exists, pulling latest changes...${NC}"
    cd "$APP_DIR"
    git pull origin $BRANCH
else
    git clone --branch $BRANCH $REPO_URL $APP_DIR
    echo -e "${GREEN}✓ Repository cloned${NC}\n"
fi

# 3. Navigate to project directory
cd "$APP_DIR/v4"
echo -e "${YELLOW}3. Current directory: $(pwd)${NC}\n"

# 4. Setup environment file
echo -e "${YELLOW}4. Setting up environment variables...${NC}"
if [ ! -f .env ]; then
    cp .env.example .env
    echo -e "${YELLOW}   Created .env file${NC}"
    echo -e "${YELLOW}   Please edit .env with your settings:${NC}"
    echo -e "${YELLOW}   nano ${APP_DIR}/v4/.env${NC}\n"
else
    echo -e "${GREEN}✓ .env file already exists${NC}\n"
fi

# 5. Copy production compose file
echo -e "${YELLOW}5. Preparing docker-compose...${NC}"
cp docker-compose.prod.yml docker-compose.yml
echo -e "${GREEN}✓ docker-compose.yml configured${NC}\n"

# 6. Check Docker and Docker Compose
echo -e "${YELLOW}6. Checking Docker installation...${NC}"
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓ Docker is installed: $(docker --version)${NC}"
else
    echo -e "${RED}✗ Docker is not installed${NC}"
    echo -e "${YELLOW}   Install Docker: https://docs.docker.com/install/${NC}\n"
    exit 1
fi

if command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}✓ Docker Compose is installed: $(docker-compose --version)${NC}\n"
else
    echo -e "${RED}✗ Docker Compose is not installed${NC}"
    echo -e "${YELLOW}   Install Docker Compose: https://docs.docker.com/compose/install/${NC}\n"
    exit 1
fi

# 7. Start containers
echo -e "${YELLOW}7. Starting Docker containers...${NC}"
docker-compose up -d --build
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Containers started successfully${NC}\n"
else
    echo -e "${RED}✗ Failed to start containers${NC}\n"
    exit 1
fi

# 8. Wait for container to be healthy
echo -e "${YELLOW}8. Waiting for container to be healthy...${NC}"
sleep 10

# 9. Check status
echo -e "${YELLOW}9. Container status:${NC}"
docker-compose ps
echo ""

# 10. Show access information
echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo -e "${GREEN}Website is running at: http://localhost${NC}"
echo -e "${YELLOW}View logs: docker-compose logs -f web${NC}"
echo -e "${YELLOW}Stop container: docker-compose down${NC}"
echo -e "${YELLOW}For HTTPS setup, see DEPLOYMENT.md${NC}\n"

# Optional: Auto-start on system boot
read -p "Do you want to enable auto-start on boot? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Setting up auto-start...${NC}"
    
    # Create systemd service file
    sudo tee /etc/systemd/system/ksaers-website.service > /dev/null <<EOF
[Unit]
Description=Ksaers Website Docker Container
After=docker.service
Requires=docker.service

[Service]
Type=forking
User=$USER
WorkingDirectory=$APP_DIR/v4
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable ksaers-website.service
    echo -e "${GREEN}✓ Auto-start enabled${NC}"
    echo -e "${YELLOW}Start service: sudo systemctl start ksaers-website${NC}"
    echo -e "${YELLOW}Stop service: sudo systemctl stop ksaers-website${NC}\n"
fi
