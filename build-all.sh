#!/bin/bash

# ============================================
# Master Build, Test & Scan Script
# Builds all 3 images in parallel
# Tests on different ports
# Scans for vulnerabilities
# ============================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================
# Configuration - UPDATED FOR YOUR PROJECT
# ============================================
DOCKER_USERNAME="mohamedharoon0"
IMAGE_BASE="gcp-workbench-with-r"

# Directory → Tag mapping (3 images only)
# Format: DIRECTORY:TAG
declare -A BUILD_MAP
BUILD_MAP["debian"]="debian"
BUILD_MAP["test-new-workbench-container-image"]="latest"
BUILD_MAP["workbench-container-image"]="workbench-container"
BUILD_MAP["rocker"]="rocker-base"


# Full image names
DEBIAN_IMAGE="${DOCKER_USERNAME}/${IMAGE_BASE}:debian"
LATEST_IMAGE="${DOCKER_USERNAME}/${IMAGE_BASE}:latest"
WORKBENCH_IMAGE="${DOCKER_USERNAME}/${IMAGE_BASE}:workbench-container"
ROCKER_IMAGE="${DOCKER_USERNAME}/${IMAGE_BASE}:rocker-base"

# Test ports
DEBIAN_PORT=8080
LATEST_PORT=8081
WORKBENCH_PORT=8082
ROCKER_PORT=8083

# Log directory
LOG_DIR="./build-logs"
mkdir -p "$LOG_DIR"

# ============================================
# Function: Print colored messages
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
# Function: Check prerequisites
# ============================================
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check Docker
    if command -v docker &> /dev/null; then
        print_success "Docker is installed: $(docker --version)"
    else
        print_error "Docker is not installed"
        exit 1
    fi
    
    # Check if Docker daemon is running
    if docker info &> /dev/null; then
        print_success "Docker daemon is running"
    else
        print_error "Docker daemon is not running"
        exit 1
    fi
    
    # Check for Trivy (vulnerability scanner) - optional
    if command -v trivy &> /dev/null; then
        print_success "Trivy is installed: $(trivy --version | head -1)"
    else
        print_warning "Trivy not installed. Skipping vulnerability scanning."
        print_info "Install with: sudo apt-get install trivy"
    fi

    # Verify project structure
    print_info "Verifying project structure..."
    local missing=0
    for dir in "${!BUILD_MAP[@]}"; do
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
        print_error "Missing ${missing} required file(s). Aborting."
        exit 1
    fi
}

# ============================================
# Function: Build single image
# ============================================
build_image() {
    local dir=$1
    local tag=$2
    local full_image="${DOCKER_USERNAME}/${IMAGE_BASE}:${tag}"
    local log_file="${LOG_DIR}/${tag}-build.log"
    
    echo "Building ${full_image} from ./${dir}/..."
    
    if docker build -t "$full_image" "./${dir}/" > "$log_file" 2>&1; then
        print_success "${full_image} built successfully"
        return 0
    else
        print_error "${full_image} build failed. Check $log_file"
        return 1
    fi
}

# ============================================
# Function: Build all images in parallel
# ============================================
build_all_parallel() {
    print_header "Building All Images in Parallel"
    
    echo "Images to build:"
    for dir in "${!BUILD_MAP[@]}"; do
        echo "  • ./${dir}/ → ${DOCKER_USERNAME}/${IMAGE_BASE}:${BUILD_MAP[$dir]}"
    done
    echo ""
    
    local start_time=$(date +%s)
    
    # Start all builds in background
    local pids=()
    local dirs=()
    local tags=()
    
    for dir in "${!BUILD_MAP[@]}"; do
        local tag="${BUILD_MAP[$dir]}"
        build_image "$dir" "$tag" &
        pids+=($!)
        dirs+=("$dir")
        tags+=("$tag")
    done
    
    echo ""
    echo "Build PIDs: ${pids[*]}"
    echo "Waiting for builds to complete..."
    echo ""
    
    # Wait for all builds and capture results
    local failed=0
    local success_count=0
    
    for i in "${!pids[@]}"; do
        if wait ${pids[$i]}; then
            ((success_count++))
        else
            print_error "Build failed for ${dirs[$i]} (${tags[$i]})"
            ((failed++))
        fi
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Total build time: ${duration} seconds"
    echo "Successful: ${success_count}/${#BUILD_MAP[@]}"
    
    if [ $failed -gt 0 ]; then
        print_error "${failed} build(s) failed. Check logs in $LOG_DIR"
        return 1
    fi
    
    print_success "All ${#BUILD_MAP[@]} images built successfully!"
    return 0
}

# ============================================
# Function: Build all images sequentially (more stable)
# ============================================
build_all_sequential() {
    print_header "Building All Images Sequentially"
    
    echo "Images to build:"
    for dir in "${!BUILD_MAP[@]}"; do
        echo "  • ./${dir}/ → ${DOCKER_USERNAME}/${IMAGE_BASE}:${BUILD_MAP[$dir]}"
    done
    echo ""
    
    local start_time=$(date +%s)
    local failed=0
    local success_count=0
    
    for dir in "${!BUILD_MAP[@]}"; do
        local tag="${BUILD_MAP[$dir]}"
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}Building: ${dir} → :${tag}${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        if build_image "$dir" "$tag"; then
            ((success_count++))
        else
            ((failed++))
        fi
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Total build time: ${duration} seconds"
    echo "Successful: ${success_count}/${#BUILD_MAP[@]}"
    
    if [ $failed -gt 0 ]; then
        print_error "${failed} build(s) failed. Check logs in $LOG_DIR"
        return 1
    fi
    
    print_success "All ${#BUILD_MAP[@]} images built successfully!"
    return 0
}

# ============================================
# Function: Show image sizes
# ============================================
show_image_sizes() {
    print_header "Image Sizes"
    
    echo "Image sizes comparison:"
    echo ""
    printf "%-55s %s\n" "IMAGE" "SIZE"
    printf "%-55s %s\n" "-----" "----"
    
    for dir in "${!BUILD_MAP[@]}"; do
        local tag="${BUILD_MAP[$dir]}"
        local full_image="${DOCKER_USERNAME}/${IMAGE_BASE}:${tag}"
        
        if docker image inspect "$full_image" &> /dev/null; then
            local size=$(docker images "$full_image" --format "{{.Size}}")
            printf "%-55s %s\n" "$full_image" "$size"
        else
            printf "%-55s %s\n" "$full_image" "NOT FOUND"
        fi
    done
}

# ============================================
# Function: Scan single image for vulnerabilities
# ============================================
scan_image() {
    local image_name=$1
    local report_file=$2
    
    if ! command -v trivy &> /dev/null; then
        print_warning "Trivy not installed, skipping scan for $image_name"
        return 0
    fi
    
    echo "Scanning $image_name..."
    
    trivy image --severity HIGH,CRITICAL --format table "$image_name" > "$report_file" 2>&1
    
    # Count vulnerabilities
    local high_count=$(grep -c "HIGH" "$report_file" 2>/dev/null || echo "0")
    local critical_count=$(grep -c "CRITICAL" "$report_file" 2>/dev/null || echo "0")
    
    if [ "$critical_count" -gt 0 ]; then
        print_error "$image_name: $critical_count CRITICAL, $high_count HIGH vulnerabilities"
    elif [ "$high_count" -gt 0 ]; then
        print_warning "$image_name: $high_count HIGH vulnerabilities"
    else
        print_success "$image_name: No HIGH/CRITICAL vulnerabilities"
    fi
}

# ============================================
# Function: Scan all images
# ============================================
scan_all() {
    print_header "Scanning All Images for Vulnerabilities"
    
    if ! command -v trivy &> /dev/null; then
        print_warning "Trivy not installed. Skipping vulnerability scanning."
        print_info "Install Trivy: sudo apt-get install trivy"
        return 0
    fi
    
    mkdir -p "$LOG_DIR/security"
    
    for dir in "${!BUILD_MAP[@]}"; do
        local tag="${BUILD_MAP[$dir]}"
        local full_image="${DOCKER_USERNAME}/${IMAGE_BASE}:${tag}"
        scan_image "$full_image" "$LOG_DIR/security/${tag}-scan.txt"
    done
    
    echo ""
    echo "Detailed reports saved in $LOG_DIR/security/"
}

# ============================================
# Function: Stop all running test containers
# ============================================
stop_all_containers() {
    print_header "Stopping All Test Containers"
    
    for dir in "${!BUILD_MAP[@]}"; do
        local tag="${BUILD_MAP[$dir]}"
        local container_name="test-${tag}"
        
        if docker ps -q -f name="$container_name" | grep -q .; then
            docker stop "$container_name" > /dev/null 2>&1
            docker rm "$container_name" > /dev/null 2>&1
            print_success "Stopped $container_name"
        else
            print_info "$container_name not running"
        fi
    done
}

# ============================================
# Function: Run all containers for testing
# ============================================
run_all_containers() {
    print_header "Starting All Containers for Testing"
    
    # Stop any existing test containers
    stop_all_containers
    
    echo "Starting containers on different ports..."
    echo ""
    
    local port=$DEBIAN_PORT
    
    for dir in "${!BUILD_MAP[@]}"; do
        local tag="${BUILD_MAP[$dir]}"
        local full_image="${DOCKER_USERNAME}/${IMAGE_BASE}:${tag}"
        local container_name="test-${tag}"
        
        if docker image inspect "$full_image" &> /dev/null; then
            docker run -d --name "$container_name" -p ${port}:8080 "$full_image" > /dev/null 2>&1
            print_success "${tag} container: http://localhost:${port}"
        else
            print_warning "${full_image} not found, skipping..."
        fi
        
        ((port++))
    done
    
    echo ""
    echo "Waiting for containers to start (15 seconds)..."
    sleep 15
    
    # Check container health
    print_header "Container Status"
    docker ps --filter "name=test-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# ============================================
# Function: Test endpoints
# ============================================
test_endpoints() {
    print_header "Testing Endpoints"
    
    local port=$DEBIAN_PORT
    
    for dir in "${!BUILD_MAP[@]}"; do
        local tag="${BUILD_MAP[$dir]}"
        
        if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port" 2>/dev/null | grep -q "200"; then
            print_success "Port $port (${tag}): JupyterLab is responding"
        else
            print_warning "Port $port (${tag}): Not responding (may still be starting)"
        fi
        
        ((port++))
    done
}

# ============================================
# Function: Show logs
# ============================================
show_logs() {
    local container=$1
    
    if [ -z "$container" ]; then
        echo "Usage: $0 logs <container-name>"
        echo ""
        echo "Available containers:"
        for dir in "${!BUILD_MAP[@]}"; do
            echo "  • test-${BUILD_MAP[$dir]}"
        done
        return 1
    fi
    
    print_header "Logs for $container"
    docker logs "$container" 2>&1 | tail -50
}

# ============================================
# Function: Push all images to Docker Hub
# ============================================
push_all() {
    print_header "Pushing All Images to Docker Hub"
    
    echo "Logging in to Docker Hub..."
    docker login -u "${DOCKER_USERNAME}"
    
    local failed=0
    
    for dir in "${!BUILD_MAP[@]}"; do
        local tag="${BUILD_MAP[$dir]}"
        local full_image="${DOCKER_USERNAME}/${IMAGE_BASE}:${tag}"
        
        if docker image inspect "$full_image" &> /dev/null; then
            echo ""
            print_info "Pushing ${full_image}..."
            if docker push "$full_image"; then
                print_success "${full_image} pushed successfully"
            else
                print_error "Failed to push ${full_image}"
                ((failed++))
            fi
        else
            print_warning "${full_image} not found, skipping..."
            ((failed++))
        fi
    done
    
    echo ""
    if [ $failed -eq 0 ]; then
        print_success "All images pushed successfully!"
        echo ""
        echo "Pull commands:"
        for dir in "${!BUILD_MAP[@]}"; do
            local tag="${BUILD_MAP[$dir]}"
            echo "  docker pull ${DOCKER_USERNAME}/${IMAGE_BASE}:${tag}"
        done
    else
        print_error "${failed} push(es) failed"
        return 1
    fi
}

# ============================================
# Function: Generate summary report
# ============================================
generate_report() {
    print_header "Generating Summary Report"
    
    local report_file="$LOG_DIR/summary-report.txt"
    
    {
        echo "============================================"
        echo "Docker Build Summary Report"
        echo "Generated: $(date)"
        echo "============================================"
        echo ""
        echo "CONFIGURATION:"
        echo "--------------"
        echo "Docker Hub User: ${DOCKER_USERNAME}"
        echo "Image Base Name: ${IMAGE_BASE}"
        echo ""
        echo "BUILD MAPPING:"
        echo "--------------"
        for dir in "${!BUILD_MAP[@]}"; do
            echo "  ./${dir}/ → :${BUILD_MAP[$dir]}"
        done
        echo ""
        echo "IMAGE SIZES:"
        echo "------------"
        docker images --filter "reference=${DOCKER_USERNAME}/${IMAGE_BASE}" --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}"
        echo ""
        echo "RUNNING CONTAINERS:"
        echo "-------------------"
        docker ps --filter "name=test-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "No containers running"
        echo ""
        echo "PULL COMMANDS:"
        echo "--------------"
        for dir in "${!BUILD_MAP[@]}"; do
            echo "docker pull ${DOCKER_USERNAME}/${IMAGE_BASE}:${BUILD_MAP[$dir]}"
        done
        echo ""
        echo "DOCKER HUB URL:"
        echo "---------------"
        echo "https://hub.docker.com/r/${DOCKER_USERNAME}/${IMAGE_BASE}"
    } > "$report_file"
    
    cat "$report_file"
    
    print_success "Report saved to $report_file"
}

# ============================================
# Function: Show usage
# ============================================
show_usage() {
    echo ""
    echo -e "${BLUE}GCP Workbench Image Build Script${NC}"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  build       Build all images in parallel"
    echo "  build-seq   Build all images sequentially (more stable)"
    echo "  push        Push all images to Docker Hub"
    echo "  scan        Scan all images for vulnerabilities"
    echo "  run         Run all containers for testing"
    echo "  stop        Stop all test containers"
    echo "  test        Test all endpoints"
    echo "  logs        Show container logs"
    echo "  report      Generate summary report"
    echo "  all         Full pipeline (build → scan → run → test → report)"
    echo "  deploy      Build and push to Docker Hub"
    echo "  clean       Remove all test images and containers"
    echo "  help        Show this help message"
    echo ""
    echo "Configuration:"
    echo "  Docker Hub: ${DOCKER_USERNAME}/${IMAGE_BASE}"
    echo ""
    echo "Images to build:"
    for dir in "${!BUILD_MAP[@]}"; do
        echo "  • ./${dir}/ → ${DOCKER_USERNAME}/${IMAGE_BASE}:${BUILD_MAP[$dir]}"
    done
    echo ""
    echo "Examples:"
    echo "  $0 all          # Full pipeline"
    echo "  $0 build        # Build only"
    echo "  $0 deploy       # Build and push"
    echo "  $0 run          # Run containers for testing"
}

# ============================================
# Function: Clean up everything
# ============================================
clean_all() {
    print_header "Cleaning Up"
    
    stop_all_containers
    
    for dir in "${!BUILD_MAP[@]}"; do
        local tag="${BUILD_MAP[$dir]}"
        local full_image="${DOCKER_USERNAME}/${IMAGE_BASE}:${tag}"
        
        if docker image inspect "$full_image" &> /dev/null; then
            docker rmi "$full_image" > /dev/null 2>&1
            print_success "Removed $full_image"
        fi
    done
    
    # Prune dangling images
    print_info "Pruning dangling images..."
    docker image prune -f > /dev/null 2>&1
    
    print_success "Cleanup complete"
}

# ============================================
# Main script logic
# ============================================
main() {
    cd "$(dirname "$0")"
    
    case "${1:-help}" in
        build)
            check_prerequisites
            build_all_parallel
            show_image_sizes
            ;;
        build-seq)
            check_prerequisites
            build_all_sequential
            show_image_sizes
            ;;
        push)
            push_all
            ;;
        deploy)
            check_prerequisites
            build_all_parallel
            show_image_sizes
            push_all
            ;;
        scan)
            scan_all
            ;;
        run)
            run_all_containers
            ;;
        stop)
            stop_all_containers
            ;;
        test)
            test_endpoints
            ;;
        logs)
            show_logs "$2"
            ;;
        report)
            generate_report
            ;;
        all)
            check_prerequisites
            build_all_parallel
            show_image_sizes
            scan_all
            run_all_containers
            test_endpoints
            generate_report
            ;;
        clean)
            clean_all
            ;;
        help|*)
            show_usage
            ;;
    esac
}

# Run main function
main "$@"