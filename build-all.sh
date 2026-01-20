#!/bin/bash

# ============================================
# Master Build (Sequential) & Push (Batch) Script
# Prevents Resource Exhaustion on Build
# Maximizes Speed on Push
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

# Directory → Tag mapping
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
    
    # We use --pull to ensure we have latest base images
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
        
        echo -e "${RED}[BUILD]${NC} ✗ ${tag} FAILED after ${duration}s"
        echo -e "${RED}       See Logs: ${log_file}${NC}"
        echo -e "${RED}       Last 5 lines of error:${NC}"
        tail -n 5 "$log_file"
        return 1
    fi
}

# ============================================
# Build All Images Sequentially (Safe Mode)
# ============================================
build_all_sequential() {
    print_header "Building Images Sequentially (Safe Mode)"
    print_info "Building one by one to prevent resource exhaustion..."
    
    local start_time=$(date +%s)
    local failed=0
    local success_count=0
    
    for dir in "${!BUILD_MAP[@]}"; do
        local tag="${BUILD_MAP[$dir]}"
        print_subheader "Building: ${dir} → :${tag}"
        
        if build_image "$dir" "$tag"; then
            ((success_count++))
            # Cleanup dangling layers immediately to save space
            docker image prune -f --filter "dangling=true" > /dev/null 2>&1
        else
            ((failed++))
            print_error "Stopping build process due to failure in ${tag}."
            return 1
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
    
    echo -e "${CYAN}[SCAN]${NC} Scanning: ${full_image}"
    
    # Check if Trivy is installed
    if command -v trivy &> /dev/null; then
        trivy image \
            --severity HIGH,CRITICAL \
            --format table \
            --output "$report_file" \
            "$full_image" > /dev/null 2>&1
    else
        # Use Docker version if local not found
        docker run --rm \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -v "${PWD}/${SCAN_DIR}:/output" \
            aquasec/trivy:latest image \
            --severity HIGH,CRITICAL \
            --format table \
            --output "/output/${tag}-scan.txt" \
            "$full_image" > /dev/null 2>&1 || true
    fi
    
    # Check results
    if [ -f "$report_file" ]; then
        local critical=$(grep -c "CRITICAL" "$report_file" 2>/dev/null || echo "0")
        local high=$(grep -c "HIGH" "$report_file" 2>/dev/null || echo "0")
        
        if [ "$critical" -gt 0 ]; then
            echo -e "${RED}[SCAN]${NC} ✗ ${tag}: ${critical} CRITICAL, ${high} HIGH"
        elif [ "$high" -gt 0 ]; then
            echo -e "${YELLOW}[SCAN]${NC} ⚠ ${tag}: ${high} HIGH"
        else
            echo -e "${GREEN}[SCAN]${NC} ✓ ${tag}: Clean"
        fi
    else
        echo -e "${YELLOW}[SCAN]${NC} ⚠ Scan failed or no results"
    fi
}

# ============================================
# Scan All Images
# ============================================
scan_all() {
    print_header "Scanning All Images"
    
    mkdir -p "$SCAN_DIR"
    
    for dir in "${!BUILD_MAP[@]}"; do
        local tag="${BUILD_MAP[$dir]}"
        local full_image="${DOCKER_USERNAME}/${IMAGE_BASE}:${tag}"
        
        if docker image inspect "$full_image" &> /dev/null; then
            scan_image "$full_image" "$tag"
        fi
    done
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
    
    if docker push "$full_image" > /dev/null 2>&1; then
        echo -e "${GREEN}[PUSH]${NC} ✓ ${tag} pushed"
        return 0
    else
        echo -e "${RED}[PUSH]${NC} ✗ ${tag} FAILED"
        return 1
    fi
}

# ============================================
# Push All Images in Parallel (Batch Push)
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
        echo ""
        echo "Docker Hub: https://hub.docker.com/r/${DOCKER_USERNAME}/${IMAGE_BASE}"
    else
        print_error "${failed} push(es) failed"
    fi
}

# ============================================
# Generate Report
# ============================================
generate_report() {
    local report_file="${LOG_DIR}/report-${TIMESTAMP}.txt"
    {
        echo "Build Report - ${TIMESTAMP}"
        echo "---------------------------"
        docker images --filter "reference=${DOCKER_USERNAME}/${IMAGE_BASE}:*" --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"
    } > "$report_file"
    print_success "Report saved to: ${report_file}"
}

# ============================================
# Main
# ============================================
show_usage() {
    echo "Usage: $0 [command]"
    echo "  build    : Build all images sequentially (Safe)"
    echo "  scan     : Scan images for vulnerabilities"
    echo "  push     : Push all images to Docker Hub"
    echo "  deploy   : Build (Seq) -> Scan -> Push (Parallel)"
    echo "  clean    : Remove local images"
}

main() {
    # Change to script directory
    cd "$(dirname "$0")"
    
    # Ensure logs directory exists
    mkdir -p "$LOG_DIR"
    
    case "${1:-help}" in
        build)
            check_prerequisites
            build_all_sequential
            show_image_sizes
            ;;
        scan)
            scan_all
            ;;
        push)
            push_all_parallel
            ;;
        deploy)
            check_prerequisites
            # 1. Build Sequentially (Prevents Crash)
            build_all_sequential || exit 1
            
            # 2. Show Sizes
            show_image_sizes
            
            # 3. Scan
            scan_all
            
            # 4. Push All at Once (Parallel)
            push_all_parallel
            
            generate_report
            ;;
        clean)
            docker image prune -a -f
            ;;
        help|--help|-h|*)
            show_usage
            ;;
    esac
}

main "$@"