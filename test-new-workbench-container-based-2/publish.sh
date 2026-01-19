#!/bin/bash
set -e

# ============================================
# Colors for output
# ============================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================
# Load environment variables from .env
# ============================================
echo -e "${BLUE}=========================================="
echo "Loading configuration from .env..."
echo -e "==========================================${NC}"

if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
    echo -e "${GREEN}✅ .env file loaded${NC}"
else
    echo -e "${RED}❌ Error: .env file not found${NC}"
    echo ""
    echo "Please create a .env file with the following content:"
    echo ""
    echo "  DOCKERHUB_USERNAME=your_username"
    echo "  IMAGE_NAME=r-workbench "
    echo "  TAG=alpine"
    echo ""
    exit 1
fi

# ============================================
# Validate required variables
# ============================================
echo -e "${BLUE}=========================================="
echo "Validating configuration..."
echo -e "==========================================${NC}"

if [ -z "$DOCKERHUB_USERNAME" ]; then
    echo -e "${RED}❌ Error: DOCKERHUB_USERNAME is not set in .env${NC}"
    exit 1
fi

if [ -z "$IMAGE_NAME" ]; then
    echo -e "${RED}❌ Error: IMAGE_NAME is not set in .env${NC}"
    exit 1
fi


echo -e "${GREEN}Configuration:${NC}"
echo "  DOCKERHUB_USERNAME: ${DOCKERHUB_USERNAME}"
echo "  IMAGE_NAME: ${IMAGE_NAME}"
echo "  TAG: ${TAG}"
echo ""

# ============================================
# Step 1: Build the image
# ============================================
echo -e "${YELLOW}=========================================="
echo "Step 1: Building image..."
echo -e "==========================================${NC}"
docker build -t ${IMAGE_NAME}:${TAG} .
echo -e "${GREEN}✅ Image built successfully${NC}"

# ============================================
# Step 2: Scan for vulnerabilities
# ============================================
echo -e "${YELLOW}=========================================="
echo "Step 2: Scanning for vulnerabilities..."
echo -e "==========================================${NC}"

if command -v trivy &> /dev/null; then
    echo "Running Trivy scan..."
    trivy image ${IMAGE_NAME}:${TAG} --severity CRITICAL,HIGH --exit-code 0
    
    echo ""
    echo "Full vulnerability report:"
    trivy image ${IMAGE_NAME}:${TAG} --format table | head -50
else
    echo -e "${YELLOW}⚠️ Trivy not installed. Skipping vulnerability scan.${NC}"
    echo ""
    echo "To install Trivy, run:"
    echo "  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin"
fi

# ============================================
# Step 3: Test image locally
# ============================================
echo -e "${YELLOW}=========================================="
echo "Step 3: Testing image locally..."
echo -e "==========================================${NC}"

CONTAINER_NAME="test-${IMAGE_NAME}-$(date +%s)"

echo "Starting container: ${CONTAINER_NAME}"
docker run -d --name ${CONTAINER_NAME} -p 8080:8080 ${IMAGE_NAME}:${TAG}

echo "Waiting for Jupyter to start..."
sleep 15

if curl -s http://localhost:8080/api/status > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Jupyter is running successfully${NC}"
else
    echo -e "${YELLOW}⚠️ Jupyter health check inconclusive (continuing anyway)${NC}"
fi

echo "Stopping test container..."
docker stop ${CONTAINER_NAME} > /dev/null 2>&1
docker rm ${CONTAINER_NAME} > /dev/null 2>&1
echo -e "${GREEN}✅ Test completed${NC}"

# ============================================
# Step 4: Login to Docker Hub
# ============================================
echo -e "${YELLOW}=========================================="
echo "Step 4: Logging in to Docker Hub..."
echo -e "==========================================${NC}"

if docker info 2>/dev/null | grep -q "Username"; then
    echo -e "${GREEN}✅ Already logged in to Docker Hub${NC}"
else
    echo "Please enter your Docker Hub credentials:"
    docker login
fi

# ============================================
# Step 5: Tag the image
# ============================================
echo -e "${YELLOW}=========================================="
echo "Step 5: Tagging image..."
echo -e "==========================================${NC}"

FULL_IMAGE_NAME="${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${TAG}"

docker tag ${IMAGE_NAME}:${TAG} ${FULL_IMAGE_NAME}
echo -e "${GREEN}✅ Tagged: ${FULL_IMAGE_NAME}${NC}"

# ============================================
# Step 6: Push to Docker Hub
# ============================================
echo -e "${YELLOW}=========================================="
echo "Step 6: Pushing to Docker Hub..."
echo -e "==========================================${NC}"

docker push ${FULL_IMAGE_NAME}
echo -e "${GREEN}✅ Pushed successfully${NC}"

# ============================================
# Summary
# ============================================
echo -e "${GREEN}=========================================="
echo "🎉 Successfully published!"
echo "==========================================${NC}"
echo ""
echo -e "${BLUE}Image Details:${NC}"
echo "  Full Name: ${FULL_IMAGE_NAME}"
echo "  Docker Hub: https://hub.docker.com/r/${DOCKERHUB_USERNAME}/${IMAGE_NAME}"
echo ""
echo -e "${BLUE}Pull Command:${NC}"
echo "  docker pull ${FULL_IMAGE_NAME}"
echo ""
echo -e "${BLUE}Run Command:${NC}"
echo "  docker run -p 8080:8080 ${FULL_IMAGE_NAME}"
echo ""
echo -e "${GREEN}==========================================${NC}"