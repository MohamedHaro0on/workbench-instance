#!/bin/bash

# ============================================
# Master Build, Test, Scan & Push Script
# Builds all 6 images in parallel
# Scans with Trivy
# Pushes to Docker Hub
# ============================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# ============================================
# Configuration
# ============================================
DOCKER_USERNAME="mohamedharoon0"
IMAGE_BASE="gcp-workbench-with-r"

# Directory → Tag mapping (FIXED for your actual directories)
declare -A BUILD_MAP
BUILD_MAP["alpine"]="alpine"
BUILD_MAP["debian"]="debian"
BUILD_MAP["wolfi"]="wolfi"
BUILD_MAP["rocker"]="rocker"
BUILD_MAP["test-new-workbench-container-based-2"]="latest"
BUILD_MAP["workbench-container-based"]="stable"

# Log directory
LOG_DIR="./build-logs"
SCAN_DIR="./build-logs/security"
mkdir -p "$LOG_DIR" "$SCAN_DIR"

# Timestamp for this run
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# ============================================
# Utility Functions
# ============================================
print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} ${CYAN}$1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_subheader() {
    echo ""
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}  $1${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
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
# Check Prerequisites
# ============================================
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check Docker
    if command -v docker &> /dev/null; then
        print_success "Docker: $(docker --version | cut -d' ' -f3 | tr -d ',')"
    else
        print_error "Docker is not installed"
        exit 1
    fi
    
    # Check Docker daemon
    if docker info &> /dev/null; then
        print_success "Docker daemon is running"
    else
        print_error "Docker daemon is not running"
        exit 1
    fi
    
    # Check Trivy (local or docker)
    if command -v trivy &> /dev/null; then
        print_success "Trivy (local): $(trivy --version 2>/dev/null | head -1)"
        TRIVY_CMD="trivy"
    else
        print_info "Trivy not installed locally, will use Docker image"
        TRIVY_CMD="docker"
    fi
    
    # Verify directories exist
    print_info "Verifying project structure..."
    local missing=0
    
    for dir in "${!BUILD_MAP[@]}"; do
        if [ -d "./${dir}" ] && [ -f "./${dir}/Dockerfile" ]; then
            print_success "./${dir}/Dockerfile"
        else
            print_error "./${dir}/Dockerfile NOT FOUND"
            ((missing++))
        fi
    done
    
    if [ $missing -gt 0 ]; then
        print_error "Missing ${missing} Dockerfile(s). Aborting."
        exit 1
    fi
    
    echo ""
    print_success "All prerequisites satisfied"
}

# ============================================
# Build Single Image
# ============================================
build_image() {
    local dir=$1
    local tag=$2
    local full_image="${DOCKER_USERNAME}/${IMAGE_BASE}:${tag}"
    local log_file="${LOG_DIR}/${tag}-build.log"
    
    local start_time=$(date +%s)
    
    echo -e "${CYAN}[BUILD]${NC} Starting: ${full_image}"
    
    if docker build \
        --pull \
        --tag "$full_image" \
        --label "build.timestamp=${TIMESTAMP}" \
        --label "build.source=${dir}" \
        "./${dir}/" > "$log_file" 2>&1; then
        
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        local size=$(docker images "$full_image" --format "{{.Size}}" 2>/dev/null)
        
        echo -e "${GREEN}[BUILD]${NC} ✓ ${tag} completed (${duration}s, ${size})"
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        echo -e "${RED}[BUILD]${NC} ✗ ${tag} FAILED after ${duration}s (see ${log_file})"
        return 1
    fi
}

# ============================================
# Build All Images in Parallel
# ============================================
build_all_parallel() {
    print_header "Building All Images in Parallel"
    
    echo "Images to build:"
    for dir in "${!BUILD_MAP[@]}"; do
        echo "  • ./${dir}/ → ${DOCKER_USERNAME}/${IMAGE_BASE}:${BUILD_MAP[$dir]}"
    done
    echo ""
    
    local start_time=$(date +%s)
    local pids=()
    local dirs=()
    local tags=()
    
    # Start all builds in background
    for dir in "${!BUILD_MAP[@]}"; do
        local tag="${BUILD_MAP[$dir]}"
        build_image "$dir" "$tag" &
        pids+=($!)
        dirs+=("$dir")
        tags+=("$tag")
    done
    
    echo ""
    print_info "Waiting for ${#pids[@]} parallel builds to complete..."
    echo ""
    
    # Wait for all builds
    local failed=0
    local success_count=0
    local failed_tags=()
    
    for i in "${!pids[@]}"; do
        if wait ${pids[$i]}; then
            ((success_count++))
        else
            ((failed++))
            failed_tags+=("${tags[$i]}")
        fi
    done
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Build Summary:"
    echo "  Total time: ${total_duration} seconds"
    echo "  Successful: ${success_count}/${#BUILD_MAP[@]}"
    
    if [ $failed -gt 0 ]; then
        echo -e "  ${RED}Failed: ${failed_tags[*]}${NC}"
        return 1
    fi
    
    print_success "All images built successfully!"
    return 0
}

# ============================================
# Build All Images Sequentially
# ============================================
build_all_sequential() {
    print_header "Building All Images Sequentially"
    
    local start_time=$(date +%s)
    local failed=0
    local success_count=0
    
    for dir in "${!BUILD_MAP[@]}"; do
        local tag="${BUILD_MAP[$dir]}"
        print_subheader "Building: ${dir} → :${tag}"
        
        if build_image "$dir" "$tag"; then
            ((success_count++))
        else
            ((failed++))
        fi
    done
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Build Summary: ${success_count}/${#BUILD_MAP[@]} successful (${total_duration}s)"
    
    if [ $failed -gt 0 ]; then
        return 1
    fi
    return 0
}

# ============================================
# Scan Single Image with Trivy
# ============================================
scan_image() {
    local full_image=$1
    local tag=$2
    local report_file="${SCAN_DIR}/${tag}-scan.txt"
    local json_file="${SCAN_DIR}/${tag}-scan.json"
    
    echo -e "${CYAN}[SCAN]${NC} Scanning: ${full_image}"
    
    # Run Trivy scan
    if [ "$TRIVY_CMD" = "trivy" ]; then
        # Local Trivy installation
        trivy image \
            --severity HIGH,CRITICAL \
            --format table \
            --output "$report_file" \
            "$full_image" 2>/dev/null
        
        trivy image \
            --severity HIGH,CRITICAL \
            --format json \
            --output "$json_file" \
            "$full_image" 2>/dev/null
    else
        # Use Docker to run Trivy
        docker run --rm \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -v "${PWD}/${SCAN_DIR}:/output" \
            aquasec/trivy:latest image \
            --severity HIGH,CRITICAL \
            --format table \
            --output "/output/${tag}-scan.txt" \
            "$full_image" 2>/dev/null || true
        
        docker run --rm \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -v "${PWD}/${SCAN_DIR}:/output" \
            aquasec/trivy:latest image \
            --severity HIGH,CRITICAL \
            --format json \
            --output "/output/${tag}-scan.json" \
            "$full_image" 2>/dev/null || true
    fi
    
    # Parse results
    local critical=0
    local high=0
    
    if [ -f "$json_file" ]; then
        critical=$(cat "$json_file" | grep -o '"Severity":"CRITICAL"' 2>/dev/null | wc -l || echo "0")
        high=$(cat "$json_file" | grep -o '"Severity":"HIGH"' 2>/dev/null | wc -l || echo "0")
    elif [ -f "$report_file" ]; then
        critical=$(grep -c "CRITICAL" "$report_file" 2>/dev/null || echo "0")
        high=$(grep -c "HIGH" "$report_file" 2>/dev/null || echo "0")
    fi
    
    # Print results
    if [ "$critical" -gt 0 ]; then
        echo -e "${RED}[SCAN]${NC} ✗ ${tag}: ${critical} CRITICAL, ${high} HIGH"
        return 2
    elif [ "$high" -gt 0 ]; then
        echo -e "${YELLOW}[SCAN]${NC} ⚠ ${tag}: ${high} HIGH vulnerabilities"
        return 1
    else
        echo -e "${GREEN}[SCAN]${NC} ✓ ${tag}: No HIGH/CRITICAL vulnerabilities"
        return 0
    fi
}

# ============================================
# Scan All Images
# ============================================
scan_all() {
    print_header "Scanning All Images with Trivy"
    
    mkdir -p "$SCAN_DIR"
    
    local critical_images=()
    local high_images=()
    local clean_images=()
    
    for dir in "${!BUILD_MAP[@]}"; do
        local tag="${BUILD_MAP[$dir]}"
        local full_image="${DOCKER_USERNAME}/${IMAGE_BASE}:${tag}"
        
        if docker image inspect "$full_image" &> /dev/null; then
            scan_image "$full_image" "$tag"
            local result=$?
            
            case $result in
                0) clean_images+=("$tag") ;;
                1) high_images+=("$tag") ;;
                2) critical_images+=("$tag") ;;
            esac
        else
            print_warning "Image not found: ${full_image}"
        fi
    done
    
    # Summary
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Scan Summary:"
    
    if [ ${#clean_images[@]} -gt 0 ]; then
        echo -e "  ${GREEN}Clean:${NC} ${clean_images[*]}"
    fi
    
    if [ ${#high_images[@]} -gt 0 ]; then
        echo -e "  ${YELLOW}HIGH vulns:${NC} ${high_images[*]}"
    fi
    
    if [ ${#critical_images[@]} -gt 0 ]; then
        echo -e "  ${RED}CRITICAL:${NC} ${critical_images[*]}"
    fi
    
    echo ""
    echo "Detailed reports saved in: ${SCAN_DIR}/"
    
    # Return code based on findings
    if [ ${#critical_images[@]} -gt 0 ]; then
        return 2
    elif [ ${#high_images[@]} -gt 0 ]; then
        return 1
    fi
    return 0
}

# ============================================
# Show Image Sizes
# ============================================
show_image_sizes() {
    print_header "Image Sizes"
    
    printf "${CYAN}%-50s %-12s %-20s${NC}\n" "IMAGE" "SIZE" "CREATED"
    printf "%-50s %-12s %-20s\n" "─────" "────" "───────"
    
    for dir in "${!BUILD_MAP[@]}"; do
        local tag="${BUILD_MAP[$dir]}"
        local full_image="${DOCKER_USERNAME}/${IMAGE_BASE}:${tag}"
        
        if docker image inspect "$full_image" &> /dev/null; then
            local size=$(docker images "$full_image" --format "{{.Size}}")
            local created=$(docker images "$full_image" --format "{{.CreatedSince}}")
            printf "%-50s %-12s %-20s\n" "$full_image" "$size" "$created"
        else
            printf "%-50s %-12s %-20s\n" "$full_image" "NOT BUILT" "-"
        fi
    done
}

# ============================================
# Push Single Image
# ============================================
push_image() {
    local full_image=$1
    local tag=$2
    
    echo -e "${CYAN}[PUSH]${NC} Pushing: ${full_image}"
    
    if docker push "$full_image" 2>/dev/null; then
        echo -e "${GREEN}[PUSH]${NC} ✓ ${tag} pushed successfully"
        return 0
    else
        echo -e "${RED}[PUSH]${NC} ✗ ${tag} push FAILED"
        return 1
    fi
}

# ============================================
# Push All Images
# ============================================
push_all() {
    print_header "Pushing All Images to Docker Hub"
    
    # Check Docker Hub login
    echo "Checking Docker Hub authentication..."
    if ! docker info 2>/dev/null | grep -q "Username"; then
        print_info "Please login to Docker Hub:"
        docker login -u "${DOCKER_USERNAME}" || {
            print_error "Docker Hub login failed"
            exit 1
        }
    else
        print_success "Already logged in to Docker Hub"
    fi
    
    echo ""
    
    local failed=0
    local success=0
    
    for dir in "${!BUILD_MAP[@]}"; do
        local tag="${BUILD_MAP[$dir]}"
        local full_image="${DOCKER_USERNAME}/${IMAGE_BASE}:${tag}"
        
        if docker image inspect "$full_image" &> /dev/null; then
            if push_image "$full_image" "$tag"; then
                ((success++))
            else
                ((failed++))
            fi
        else
            print_warning "Image not found, skipping: ${full_image}"
            ((failed++))
        fi
    done
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Push Summary: ${success}/${#BUILD_MAP[@]} successful"
    
    if [ $failed -eq 0 ]; then
        print_success "All images pushed to Docker Hub!"
        echo ""
        echo "Docker Hub: https://hub.docker.com/r/${DOCKER_USERNAME}/${IMAGE_BASE}"
        echo ""
        echo "Pull commands:"
        for dir in "${!BUILD_MAP[@]}"; do
            echo "  docker pull ${DOCKER_USERNAME}/${IMAGE_BASE}:${BUILD_MAP[$dir]}"
        done
        return 0
    else
        print_error "${failed} push(es) failed"
        return 1
    fi
}

# ============================================
# Push All Images in Parallel
# ============================================
push_all_parallel() {
    print_header "Pushing All Images to Docker Hub (Parallel)"
    
    # Check Docker Hub login
    echo "Checking Docker Hub authentication..."
    if ! docker info 2>/dev/null | grep -q "Username"; then
        print_info "Please login to Docker Hub:"
        docker login -u "${DOCKER_USERNAME}" || {
            print_error "Docker Hub login failed"
            exit 1
        }
    fi
    
    echo ""
    
    local pids=()
    local tags=()
    
    for dir in "${!BUILD_MAP[@]}"; do
        local tag="${BUILD_MAP[$dir]}"
        local full_image="${DOCKER_USERNAME}/${IMAGE_BASE}:${tag}"
        
        if docker image inspect "$full_image" &> /dev/null; then
            push_image "$full_image" "$tag" &
            pids+=($!)
            tags+=("$tag")
        fi
    done
    
    # Wait for all pushes
    local failed=0
    for i in "${!pids[@]}"; do
        if ! wait ${pids[$i]}; then
            ((failed++))
        fi
    done
    
    echo ""
    if [ $failed -eq 0 ]; then
        print_success "All images pushed successfully!"
    else
        print_error "${failed} push(es) failed"
    fi
}

# ============================================
# Run Test Containers
# ============================================
run_test_containers() {
    print_header "Starting Test Containers"
    
    # Stop existing test containers
    stop_test_containers
    
    local port=8080
    
    for dir in "${!BUILD_MAP[@]}"; do
        local tag="${BUILD_MAP[$dir]}"
        local full_image="${DOCKER_USERNAME}/${IMAGE_BASE}:${tag}"
        local container_name="test-${tag}"
        
        if docker image inspect "$full_image" &> /dev/null; then
            docker run -d \
                --name "$container_name" \
                -p ${port}:8080 \
                "$full_image" > /dev/null 2>&1
            
            print_success "${tag}: http://localhost:${port}"
            ((port++))
        else
            print_warning "${full_image} not found"
        fi
    done
    
    echo ""
    print_info "Waiting 15 seconds for containers to start..."
    sleep 15
    
    echo ""
    docker ps --filter "name=test-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# ============================================
# Stop Test Containers
# ============================================
stop_test_containers() {
    print_info "Stopping test containers..."
    
    for dir in "${!BUILD_MAP[@]}"; do
        local tag="${BUILD_MAP[$dir]}"
        local container_name="test-${tag}"
        
        docker stop "$container_name" 2>/dev/null || true
        docker rm "$container_name" 2>/dev/null || true
    done
}

# ============================================
# Test Endpoints
# ============================================
test_endpoints() {
    print_header "Testing Endpoints"
    
    local port=8080
    
    for dir in "${!BUILD_MAP[@]}"; do
        local tag="${BUILD_MAP[$dir]}"
        
        local status=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${port}/api/status" 2>/dev/null || echo "000")
        
        if [ "$status" = "200" ]; then
            print_success "Port ${port} (${tag}): OK"
        elif [ "$status" = "000" ]; then
            print_error "Port ${port} (${tag}): No response"
        else
            print_warning "Port ${port} (${tag}): HTTP ${status}"
        fi
        
        ((port++))
    done
}

# ============================================
# Generate Report
# ============================================
generate_report() {
    print_header "Generating Report"
    
    local report_file="${LOG_DIR}/report-${TIMESTAMP}.txt"
    
    {
        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║           GCP Workbench Docker Build Report                ║"
        echo "╚════════════════════════════════════════════════════════════╝"
        echo ""
        echo "Generated: $(date)"
        echo "Timestamp: ${TIMESTAMP}"
        echo ""
        echo "═══════════════════════════════════════════════════════════════"
        echo "CONFIGURATION"
        echo "═══════════════════════════════════════════════════════════════"
        echo "Docker Hub User: ${DOCKER_USERNAME}"
        echo "Image Base Name: ${IMAGE_BASE}"
        echo ""
        echo "═══════════════════════════════════════════════════════════════"
        echo "BUILD MAPPING"
        echo "═══════════════════════════════════════════════════════════════"
        for dir in "${!BUILD_MAP[@]}"; do
            printf "  %-40s → :%s\n" "./${dir}/" "${BUILD_MAP[$dir]}"
        done
        echo ""
        echo "═══════════════════════════════════════════════════════════════"
        echo "IMAGE DETAILS"
        echo "═══════════════════════════════════════════════════════════════"
        docker images --filter "reference=${DOCKER_USERNAME}/${IMAGE_BASE}:*" \
            --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}"
        echo ""
        echo "═══════════════════════════════════════════════════════════════"
        echo "PULL COMMANDS"
        echo "═══════════════════════════════════════════════════════════════"
        for dir in "${!BUILD_MAP[@]}"; do
            echo "docker pull ${DOCKER_USERNAME}/${IMAGE_BASE}:${BUILD_MAP[$dir]}"
        done
        echo ""
        echo "═══════════════════════════════════════════════════════════════"
        echo "DOCKER HUB"
        echo "═══════════════════════════════════════════════════════════════"
        echo "https://hub.docker.com/r/${DOCKER_USERNAME}/${IMAGE_BASE}/tags"
        echo ""
    } | tee "$report_file"
    
    print_success "Report saved to: ${report_file}"
}

# ============================================
# Clean Up
# ============================================
clean_all() {
    print_header "Cleaning Up"
    
    stop_test_containers
    
    for dir in "${!BUILD_MAP[@]}"; do
        local tag="${BUILD_MAP[$dir]}"
        local full_image="${DOCKER_USERNAME}/${IMAGE_BASE}:${tag}"
        
        if docker image inspect "$full_image" &> /dev/null; then
            docker rmi "$full_image" 2>/dev/null || true
            print_success "Removed: ${full_image}"
        fi
    done
    
    print_info "Pruning dangling images..."
    docker image prune -f > /dev/null 2>&1
    
    print_success "Cleanup complete"
}

# ============================================
# Show Usage
# ============================================
show_usage() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}     ${CYAN}GCP Workbench Multi-Image Build Script${NC}                 ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC} $0 [command]"
    echo ""
    echo -e "${YELLOW}Build Commands:${NC}"
    echo "  build          Build all images in parallel"
    echo "  build-seq      Build all images sequentially"
    echo ""
    echo -e "${YELLOW}Security Commands:${NC}"
    echo "  scan           Scan all images with Trivy"
    echo ""
    echo -e "${YELLOW}Deploy Commands:${NC}"
    echo "  push           Push all images to Docker Hub"
    echo "  push-parallel  Push all images in parallel"
    echo "  deploy         Build + Scan + Push (full deployment)"
    echo ""
    echo -e "${YELLOW}Test Commands:${NC}"
    echo "  run            Start test containers"
    echo "  stop           Stop test containers"
    echo "  test           Test container endpoints"
    echo ""
    echo -e "${YELLOW}Utility Commands:${NC}"
    echo "  sizes          Show image sizes"
    echo "  report         Generate summary report"
    echo "  clean          Remove all images and containers"
    echo "  all            Full pipeline (build → scan → report)"
    echo "  help           Show this help"
    echo ""
    echo -e "${YELLOW}Configuration:${NC}"
    echo "  Registry: ${DOCKER_USERNAME}/${IMAGE_BASE}"
    echo ""
    echo -e "${YELLOW}Images:${NC}"
    for dir in "${!BUILD_MAP[@]}"; do
        printf "  ${CYAN}%-40s${NC} → :${GREEN}%s${NC}\n" "./${dir}/" "${BUILD_MAP[$dir]}"
    done
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 build          # Build all images"
    echo "  $0 scan           # Scan for vulnerabilities"
    echo "  $0 deploy         # Build, scan, and push"
    echo "  $0 all            # Full pipeline"
    echo ""
}

# ============================================
# Main
# ============================================
main() {
    # Change to script directory
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
        scan)
            scan_all
            ;;
        push)
            push_all
            ;;
        push-parallel)
            push_all_parallel
            ;;
        deploy)
            check_prerequisites
            build_all_parallel
            show_image_sizes
            scan_all
            push_all
            generate_report
            ;;
        run)
            run_test_containers
            ;;
        stop)
            stop_test_containers
            ;;
        test)
            test_endpoints
            ;;
        sizes)
            show_image_sizes
            ;;
        report)
            generate_report
            ;;
        all)
            check_prerequisites
            build_all_parallel
            show_image_sizes
            scan_all
            generate_report
            ;;
        clean)
            clean_all
            ;;
        help|--help|-h|*)
            show_usage
            ;;
    esac
}

main "$@"