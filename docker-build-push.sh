#!/bin/bash

# ============================================
# GCP VM Build & Push Script
# Installs Docker, builds images, pushes to Docker Hub
# ============================================

set -e

# ============================================
# Configuration
# ============================================
DOCKER_USERNAME="mohamedharoon0"
IMAGE_NAME="gcp-workbench-with-r"

# Directory to tag mapping
declare -A BUILD_CONFIG
BUILD_CONFIG["debian"]="debian"
BUILD_CONFIG["test-new-workbench-container-image"]="latest"
BUILD_CONFIG["workbench-container-image"]="workbench-container"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Log directory
LOG_DIR="./build-logs"
mkdir -p "$LOG_DIR"

# ============================================
# Functions
# ============================================

print_header() {
    echo -e "\n${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# ============================================
# Install Docker on GCP VM (Debian/Ubuntu)
# ============================================
install_docker() {
    print_header "Installing Docker"

    # Check if Docker is already installed
    if command -v docker &> /dev/null; then
        print_success "Docker is already installed: $(docker --version)"
        
        # Check if Docker daemon is running
        if docker info &> /dev/null; then
            print_success "Docker daemon is running"
            return 0
        else
            print_warning "Docker installed but daemon not running. Starting..."
            sudo systemctl start docker
            sudo systemctl enable docker
            return 0
        fi
    fi

    print_info "Installing Docker..."

    # Update package index
    sudo apt-get update

    # Install prerequisites
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Detect OS (Debian or Ubuntu)
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        OS="debian"
    fi

    # Set up the repository based on OS
    if [ "$OS" = "ubuntu" ]; then
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
            $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    else
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
            $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    fi

    # Update and install Docker
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker

    # Add current user to docker group (to run without sudo)
    sudo usermod -aG docker $USER

    print_success "Docker installed successfully: $(docker --version)"
    print_warning "You may need to log out and back in for group changes to take effect"
    print_info "For this session, commands will use sudo for docker"
}

# ============================================
# Docker command wrapper (handles sudo if needed)
# ============================================
docker_cmd() {
    if docker info &> /dev/null 2>&1; then
        docker "$@"
    else
        sudo docker "$@"
    fi
}

# ============================================
# Login to Docker Hub
# ============================================
docker_login() {
    print_header "Docker Hub Login"

    echo -e "${CYAN}Logging in to Docker Hub as: ${DOCKER_USERNAME}${NC}"
    echo ""

    # Check if already logged in
    if docker_cmd info 2>/dev/null | grep -q "Username: ${DOCKER_USERNAME}"; then
        print_success "Already logged in as ${DOCKER_USERNAME}"
        return 0
    fi

    # Interactive login
    echo -e "${YELLOW}Please enter your Docker Hub password or access token:${NC}"
    docker_cmd login -u "${DOCKER_USERNAME}"

    if [ $? -eq 0 ]; then
        print_success "Successfully logged in to Docker Hub"
    else
        print_error "Docker Hub login failed"
        exit 1
    fi
}

# ============================================
# Build single image
# ============================================
build_image() {
    local dir=$1
    local tag=$2
    local full_image="${DOCKER_USERNAME}/${IMAGE_NAME}:${tag}"
    local log_file="${LOG_DIR}/${tag}-build.log"

    print_info "Building ${full_image} from ./${dir}/"
    echo "Log file: ${log_file}"

    local start_time=$(date +%s)

    if docker_cmd build -t "${full_image}" "./${dir}/" 2>&1 | tee "${log_file}"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_success "${full_image} built successfully in ${duration}s"
        return 0
    else
        print_error "${full_image} build failed. Check ${log_file}"
        return 1
    fi
}

# ============================================
# Push single image
# ============================================
push_image() {
    local tag=$1
    local full_image="${DOCKER_USERNAME}/${IMAGE_NAME}:${tag}"

    print_info "Pushing ${full_image} to Docker Hub..."

    if docker_cmd push "${full_image}"; then
        print_success "${full_image} pushed successfully"
        return 0
    else
        print_error "Failed to push ${full_image}"
        return 1
    fi
}

# ============================================
# Build all images sequentially
# ============================================
build_all() {
    print_header "Building All Images"

    local failed=0
    local built_images=()

    for dir in "${!BUILD_CONFIG[@]}"; do
        local tag="${BUILD_CONFIG[$dir]}"
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}Building: ${dir} → ${DOCKER_USERNAME}/${IMAGE_NAME}:${tag}${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

        if [ -d "./${dir}" ]; then
            if build_image "${dir}" "${tag}"; then
                built_images+=("${tag}")
            else
                ((failed++))
            fi
        else
            print_error "Directory ./${dir} not found!"
            ((failed++))
        fi
    done

    echo ""
    print_header "Build Summary"

    echo "Successfully built:"
    for img in "${built_images[@]}"; do
        print_success "${DOCKER_USERNAME}/${IMAGE_NAME}:${img}"
    done

    if [ $failed -gt 0 ]; then
        print_error "${failed} build(s) failed"
        return 1
    fi

    print_success "All ${#built_images[@]} images built successfully!"
    return 0
}

# ============================================
# Push all images
# ============================================
push_all() {
    print_header "Pushing All Images to Docker Hub"

    local failed=0
    local pushed_images=()

    for dir in "${!BUILD_CONFIG[@]}"; do
        local tag="${BUILD_CONFIG[$dir]}"
        local full_image="${DOCKER_USERNAME}/${IMAGE_NAME}:${tag}"

        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}Pushing: ${full_image}${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

        # Check if image exists locally
        if docker_cmd image inspect "${full_image}" &> /dev/null; then
            if push_image "${tag}"; then
                pushed_images+=("${tag}")
            else
                ((failed++))
            fi
        else
            print_error "Image ${full_image} not found locally. Build first!"
            ((failed++))
        fi
    done

    echo ""
    print_header "Push Summary"

    echo "Successfully pushed:"
    for img in "${pushed_images[@]}"; do
        print_success "${DOCKER_USERNAME}/${IMAGE_NAME}:${img}"
    done

    if [ $failed -gt 0 ]; then
        print_error "${failed} push(es) failed"
        return 1
    fi

    print_success "All ${#pushed_images[@]} images pushed successfully!"
    return 0
}

# ============================================
# Show image sizes
# ============================================
show_images() {
    print_header "Built Images"

    echo -e "${CYAN}%-60s %s${NC}\n" "IMAGE" "SIZE"
    printf "%-60s %s\n" "-----" "----"

    for dir in "${!BUILD_CONFIG[@]}"; do
        local tag="${BUILD_CONFIG[$dir]}"
        local full_image="${DOCKER_USERNAME}/${IMAGE_NAME}:${tag}"

        if docker_cmd image inspect "${full_image}" &> /dev/null; then
            local size=$(docker_cmd images "${full_image}" --format "{{.Size}}")
            local created=$(docker_cmd images "${full_image}" --format "{{.CreatedSince}}")
            printf "%-60s %s (%s)\n" "${full_image}" "${size}" "${created}"
        else
            printf "%-60s %s\n" "${full_image}" "NOT BUILT"
        fi
    done
}

# ============================================
# Verify project structure
# ============================================
verify_structure() {
    print_header "Verifying Project Structure"

    local missing=0

    for dir in "${!BUILD_CONFIG[@]}"; do
        if [ -d "./${dir}" ]; then
            if [ -f "./${dir}/Dockerfile" ]; then
                print_success "./${dir}/Dockerfile exists"
            else
                print_error "./${dir}/Dockerfile not found!"
                ((missing++))
            fi
        else
            print_error "Directory ./${dir} not found!"
            ((missing++))
        fi
    done

    if [ $missing -gt 0 ]; then
        print_error "Missing ${missing} required file(s)"
        return 1
    fi

    print_success "All required files present"
    return 0
}

# ============================================
# Clean up local images
# ============================================
clean_images() {
    print_header "Cleaning Up Local Images"

    for dir in "${!BUILD_CONFIG[@]}"; do
        local tag="${BUILD_CONFIG[$dir]}"
        local full_image="${DOCKER_USERNAME}/${IMAGE_NAME}:${tag}"

        if docker_cmd image inspect "${full_image}" &> /dev/null; then
            docker_cmd rmi "${full_image}" > /dev/null 2>&1
            print_success "Removed ${full_image}"
        else
            print_info "${full_image} not found (already clean)"
        fi
    done

    # Prune dangling images
    print_info "Pruning dangling images..."
    docker_cmd image prune -f > /dev/null 2>&1
    print_success "Cleanup complete"
}

# ============================================
# Full pipeline: Install, Build, Push
# ============================================
full_pipeline() {
    local start_time=$(date +%s)

    print_header "Full Pipeline: Install → Build → Push"

    echo -e "${CYAN}Target Docker Hub: ${DOCKER_USERNAME}/${IMAGE_NAME}${NC}"
    echo ""
    echo "Images to build:"
    for dir in "${!BUILD_CONFIG[@]}"; do
        echo "  • ./${dir}/ → :${BUILD_CONFIG[$dir]}"
    done
    echo ""

    # Step 1: Install Docker
    install_docker

    # Step 2: Verify project structure
    verify_structure || exit 1

    # Step 3: Login to Docker Hub
    docker_login

    # Step 4: Build all images
    build_all || exit 1

    # Step 5: Show images
    show_images

    # Step 6: Push all images
    push_all || exit 1

    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))

    print_header "Pipeline Complete!"

    echo -e "${GREEN}Total time: ${total_duration} seconds${NC}"
    echo ""
    echo "Your images are now available at:"
    echo ""
    for dir in "${!BUILD_CONFIG[@]}"; do
        local tag="${BUILD_CONFIG[$dir]}"
        echo -e "  ${CYAN}docker pull ${DOCKER_USERNAME}/${IMAGE_NAME}:${tag}${NC}"
    done
    echo ""
    echo "Docker Hub URL:"
    echo -e "  ${CYAN}https://hub.docker.com/r/${DOCKER_USERNAME}/${IMAGE_NAME}${NC}"
}

# ============================================
# Show usage
# ============================================
show_usage() {
    echo ""
    echo -e "${BLUE}GCP Workbench Image Build & Push Script${NC}"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  install     Install Docker on GCP VM"
    echo "  login       Login to Docker Hub"
    echo "  build       Build all images"
    echo "  push        Push all images to Docker Hub"
    echo "  all         Full pipeline (install → build → push)"
    echo "  images      Show built images"
    echo "  clean       Remove local images"
    echo "  verify      Verify project structure"
    echo "  help        Show this help message"
    echo ""
    echo "Configuration:"
    echo "  Docker Hub User: ${DOCKER_USERNAME}"
    echo "  Image Name:      ${IMAGE_NAME}"
    echo ""
    echo "Images to build:"
    for dir in "${!BUILD_CONFIG[@]}"; do
        echo "  • ./${dir}/ → ${DOCKER_USERNAME}/${IMAGE_NAME}:${BUILD_CONFIG[$dir]}"
    done
    echo ""
    echo "Examples:"
    echo "  $0 all        # Full pipeline (recommended for first run)"
    echo "  $0 build      # Build only"
    echo "  $0 push       # Push only (after build)"
    echo ""
}

# ============================================
# Main script logic
# ============================================
main() {
    # Change to script directory
    cd "$(dirname "$0")"

    case "${1:-help}" in
        install)
            install_docker
            ;;
        login)
            docker_login
            ;;
        build)
            verify_structure || exit 1
            build_all
            show_images
            ;;
        push)
            docker_login
            push_all
            ;;
        all)
            full_pipeline
            ;;
        images)
            show_images
            ;;
        clean)
            clean_images
            ;;
        verify)
            verify_structure
            ;;
        help|*)
            show_usage
            ;;
    esac
}

# Run main function
main "$@"