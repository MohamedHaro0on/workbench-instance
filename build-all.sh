#!/bin/bash

# ============================================
# Master Build & Push Script
# Sequential: Build -> Push -> Next
# Continue on failure, log errors
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# ============================================
# Configuration
# ============================================
DOCKER_USERNAME="mohamedharoon0"
IMAGE_BASE="gcp-workbench-with-r"

declare -A BUILD_MAP
BUILD_MAP["alpine"]="alpine"
BUILD_MAP["debian"]="debian"
BUILD_MAP["debian-2"]="debian-2"
BUILD_MAP["debian-3"]="debian-3"
BUILD_MAP["wolfi"]="wolfi"
BUILD_MAP["rocker"]="rocker"
BUILD_MAP["workbench-container"]="latest"

LOG_DIR="./build-logs"
SCAN_DIR="./build-logs/security"
mkdir -p "$LOG_DIR" "$SCAN_DIR"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)

FAILED_BUILDS=()
SUCCESSFUL_BUILDS=()
FAILED_PUSHES=()
SUCCESSFUL_PUSHES=()
SKIPPED=()

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
    
    if command -v docker &> /dev/null; then
        print_success "Docker: $(docker --version | cut -d' ' -f3 | tr -d ',')"
    else
        print_error "Docker is not installed"
        exit 1
    fi
    
    if docker info &> /dev/null; then
        print_success "Docker daemon is running"
    else
        print_error "Docker daemon is not running"
        exit 1
    fi
    
    print_info "Verifying project structure..."
    
    for dir in "${!BUILD_MAP[@]}"; do
        if [ -d "./${dir}" ] && [ -f "./${dir}/Dockerfile" ]; then
            print_success "./${dir}/Dockerfile"
        else
            print_warning "./${dir}/Dockerfile NOT FOUND - will skip"
        fi
    done
    
    echo ""
    print_success "Prerequisites check complete"
}

# ============================================
# Check Docker Hub Login
# ============================================
check_docker_login() {
    print_header "Checking Docker Hub Authentication"
    
    if docker info 2>/dev/null | grep -q "Username"; then
        print_success "Already logged in to Docker Hub"
    else
        print_info "Please login to Docker Hub:"
        if docker login -u "${DOCKER_USERNAME}"; then
            print_success "Docker Hub login successful"
        else
            print_error "Docker Hub login failed"
            exit 1
        fi
    fi
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
    
    echo -e "${CYAN}[BUILD]${NC} Building: ${full_image}"
    echo -e "${CYAN}[BUILD]${NC} Source: ./${dir}/Dockerfile"
    echo -e "${CYAN}[BUILD]${NC} Log: ${log_file}"
    
    {
        echo "========================================"
        echo "Build Log: ${full_image}"
        echo "Timestamp: $(date)"
        echo "Directory: ${dir}"
        echo "========================================"
        echo ""
    } > "$log_file"
    
    if docker build --pull --tag "$full_image" "./${dir}/" >> "$log_file" 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        local size=$(docker images "$full_image" --format "{{.Size}}" 2>/dev/null)
        
        echo -e "${GREEN}[BUILD]${NC} ✓ ${tag} completed (${duration}s, ${size})"
        
        {
            echo ""
            echo "========================================"
            echo "BUILD SUCCESSFUL"
            echo "Duration: ${duration}s"
            echo "Size: ${size}"
            echo "========================================"
        } >> "$log_file"
        
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        echo -e "${RED}[BUILD]${NC} ✗ ${tag} FAILED after ${duration}s"
        echo -e "${RED}[BUILD]${NC}   Log: ${log_file}"
        
        {
            echo ""
            echo "========================================"
            echo "BUILD FAILED"
            echo "Duration: ${duration}s"
            echo "========================================"
        } >> "$log_file"
        
        echo -e "${RED}[BUILD]${NC}   Last 15 lines of error:"
        tail -n 15 "$log_file" | sed 's/^/         /'
        
        return 1
    fi
}

# ============================================
# Push Single Image
# ============================================
push_image() {
    local tag=$1
    local full_image="${DOCKER_USERNAME}/${IMAGE_BASE}:${tag}"
    local log_file="${LOG_DIR}/${tag}-push.log"
    
    local start_time=$(date +%s)
    
    echo -e "${CYAN}[PUSH]${NC} Pushing: ${full_image}"
    
    {
        echo "========================================"
        echo "Push Log: ${full_image}"
        echo "Timestamp: $(date)"
        echo "========================================"
        echo ""
    } > "$log_file"
    
    if docker push "$full_image" >> "$log_file" 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        echo -e "${GREEN}[PUSH]${NC} ✓ ${tag} pushed (${duration}s)"
        
        {
            echo ""
            echo "========================================"
            echo "PUSH SUCCESSFUL"
            echo "Duration: ${duration}s"
            echo "========================================"
        } >> "$log_file"
        
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        echo -e "${RED}[PUSH]${NC} ✗ ${tag} push FAILED after ${duration}s"
        echo -e "${RED}[PUSH]${NC}   Log: ${log_file}"
        
        {
            echo ""
            echo "========================================"
            echo "PUSH FAILED"
            echo "Duration: ${duration}s"
            echo "========================================"
        } >> "$log_file"
        
        return 1
    fi
}

# ============================================
# Build and Push Single Image
# ============================================
build_and_push() {
    local dir=$1
    local tag=$2
    
    print_subheader "Processing: ${dir} -> :${tag}"
    
    if [ ! -d "./${dir}" ]; then
        print_warning "Directory ./${dir} not found, skipping"
        SKIPPED+=("${tag}:DIR_NOT_FOUND")
        return 1
    fi
    
    if [ ! -f "./${dir}/Dockerfile" ]; then
        print_warning "Dockerfile not found in ./${dir}, skipping"
        SKIPPED+=("${tag}:DOCKERFILE_NOT_FOUND")
        return 1
    fi
    
    if build_image "$dir" "$tag"; then
        SUCCESSFUL_BUILDS+=("$tag")
    else
        FAILED_BUILDS+=("$tag")
        print_warning "Build failed for ${tag}, logging and continuing to next..."
        echo ""
        return 1
    fi
    
    if push_image "$tag"; then
        SUCCESSFUL_PUSHES+=("$tag")
    else
        FAILED_PUSHES+=("$tag")
        print_warning "Push failed for ${tag}, logging and continuing to next..."
        echo ""
        return 1
    fi
    
    docker image prune -f --filter "dangling=true" > /dev/null 2>&1 || true
    
    print_success "Completed: ${tag}"
    echo ""
    return 0
}

# ============================================
# Build All Sequential with Push
# ============================================
build_all_sequential_with_push() {
    print_header "Sequential Build & Push Pipeline"
    print_info "Each image will be built and pushed before moving to the next"
    print_info "Failed builds will be logged and skipped"
    echo ""
    
    local total_start_time=$(date +%s)
    local total=${#BUILD_MAP[@]}
    local current=0
    
    for dir in "${!BUILD_MAP[@]}"; do
        local tag="${BUILD_MAP[$dir]}"
        ((current++))
        
        echo -e "${BLUE}[${current}/${total}]${NC} Processing ${tag}..."
        
        build_and_push "$dir" "$tag"
    done
    
    local total_end_time=$(date +%s)
    local total_duration=$((total_end_time - total_start_time))
    
    print_info "Total time: ${total_duration}s"
}

# ============================================
# Build Only
# ============================================
build_only() {
    print_header "Building All Images (No Push)"
    
    local total=${#BUILD_MAP[@]}
    local current=0
    
    for dir in "${!BUILD_MAP[@]}"; do
        local tag="${BUILD_MAP[$dir]}"
        ((current++))
        
        print_subheader "[${current}/${total}] Building: ${dir} -> :${tag}"
        
        if [ ! -d "./${dir}" ] || [ ! -f "./${dir}/Dockerfile" ]; then
            print_warning "Directory ./${dir} or Dockerfile not found, skipping"
            SKIPPED+=("${tag}:NOT_FOUND")
            continue
        fi
        
        if build_image "$dir" "$tag"; then
            SUCCESSFUL_BUILDS+=("$tag")
        else
            FAILED_BUILDS+=("$tag")
            print_warning "Build failed for ${tag}, logging and continuing..."
        fi
        
        docker image prune -f --filter "dangling=true" > /dev/null 2>&1 || true
    done
}

# ============================================
# Push Only
# ============================================
push_only() {
    print_header "Pushing All Existing Images"
    
    check_docker_login
    
    for dir in "${!BUILD_MAP[@]}"; do
        local tag="${BUILD_MAP[$dir]}"
        local full_image="${DOCKER_USERNAME}/${IMAGE_BASE}:${tag}"
        
        if docker image inspect "$full_image" &> /dev/null; then
            print_subheader "Pushing: ${tag}"
            if push_image "$tag"; then
                SUCCESSFUL_PUSHES+=("$tag")
            else
                FAILED_PUSHES+=("$tag")
            fi
        else
            print_warning "Image ${tag} not found locally, skipping"
            SKIPPED+=("${tag}:NOT_BUILT")
        fi
    done
}

# ============================================
# Show Image Sizes
# ============================================
show_image_sizes() {
    print_header "Image Sizes"
    
    printf "${CYAN}%-50s %-12s %-20s${NC}\n" "IMAGE" "SIZE" "CREATED"
    printf "%-50s %-12s %-20s\n" "-----" "----" "-------"
    
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
# Print Final Summary
# ============================================
print_summary() {
    print_header "Final Summary"
    
    echo -e "${GREEN}Successful Builds (${#SUCCESSFUL_BUILDS[@]}):${NC}"
    if [ ${#SUCCESSFUL_BUILDS[@]} -eq 0 ]; then
        echo "  None"
    else
        for tag in "${SUCCESSFUL_BUILDS[@]}"; do
            echo "  ✓ $tag"
        done
    fi
    
    echo ""
    echo -e "${RED}Failed Builds (${#FAILED_BUILDS[@]}):${NC}"
    if [ ${#FAILED_BUILDS[@]} -eq 0 ]; then
        echo "  None"
    else
        for tag in "${FAILED_BUILDS[@]}"; do
            echo "  ✗ $tag (see ${LOG_DIR}/${tag}-build.log)"
        done
    fi
    
    echo ""
    echo -e "${GREEN}Successful Pushes (${#SUCCESSFUL_PUSHES[@]}):${NC}"
    if [ ${#SUCCESSFUL_PUSHES[@]} -eq 0 ]; then
        echo "  None"
    else
        for tag in "${SUCCESSFUL_PUSHES[@]}"; do
            echo "  ✓ $tag"
        done
    fi
    
    echo ""
    echo -e "${RED}Failed Pushes (${#FAILED_PUSHES[@]}):${NC}"
    if [ ${#FAILED_PUSHES[@]} -eq 0 ]; then
        echo "  None"
    else
        for tag in "${FAILED_PUSHES[@]}"; do
            echo "  ✗ $tag (see ${LOG_DIR}/${tag}-push.log)"
        done
    fi
    
    echo ""
    echo -e "${YELLOW}Skipped (${#SKIPPED[@]}):${NC}"
    if [ ${#SKIPPED[@]} -eq 0 ]; then
        echo "  None"
    else
        for item in "${SKIPPED[@]}"; do
            echo "  - $item"
        done
    fi
    
    echo ""
    echo -e "${CYAN}Docker Hub:${NC} https://hub.docker.com/r/${DOCKER_USERNAME}/${IMAGE_BASE}"
    echo -e "${CYAN}Build Logs:${NC} ${LOG_DIR}/"
}

# ============================================
# Generate Report
# ============================================
generate_report() {
    local report_file="${LOG_DIR}/report-${TIMESTAMP}.txt"
    
    {
        echo "========================================"
        echo "Build Report - ${TIMESTAMP}"
        echo "========================================"
        echo ""
        echo "Successful Builds: ${#SUCCESSFUL_BUILDS[@]}"
        for tag in "${SUCCESSFUL_BUILDS[@]}"; do
            echo "  - $tag"
        done
        echo ""
        echo "Failed Builds: ${#FAILED_BUILDS[@]}"
        for tag in "${FAILED_BUILDS[@]}"; do
            echo "  - $tag"
        done
        echo ""
        echo "Successful Pushes: ${#SUCCESSFUL_PUSHES[@]}"
        for tag in "${SUCCESSFUL_PUSHES[@]}"; do
            echo "  - $tag"
        done
        echo ""
        echo "Failed Pushes: ${#FAILED_PUSHES[@]}"
        for tag in "${FAILED_PUSHES[@]}"; do
            echo "  - $tag"
        done
        echo ""
        echo "Skipped: ${#SKIPPED[@]}"
        for item in "${SKIPPED[@]}"; do
            echo "  - $item"
        done
        echo ""
        echo "Image Sizes:"
        docker images --filter "reference=${DOCKER_USERNAME}/${IMAGE_BASE}:*" \
            --format "  {{.Repository}}:{{.Tag}} - {{.Size}}" 2>/dev/null || echo "  No images found"
    } > "$report_file"
    
    print_success "Report saved to: ${report_file}"
}

# ============================================
# Scan All Images
# ============================================
scan_all() {
    print_header "Scanning All Images for Vulnerabilities"
    
    mkdir -p "$SCAN_DIR"
    
    for dir in "${!BUILD_MAP[@]}"; do
        local tag="${BUILD_MAP[$dir]}"
        local full_image="${DOCKER_USERNAME}/${IMAGE_BASE}:${tag}"
        local report_file="${SCAN_DIR}/${tag}-scan.txt"
        
        if docker image inspect "$full_image" &> /dev/null; then
            echo -e "${CYAN}[SCAN]${NC} Scanning: ${full_image}"
            
            if command -v trivy &> /dev/null; then
                trivy image --severity HIGH,CRITICAL --format table --output "$report_file" "$full_image" 2>/dev/null || true
            else
                docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                    aquasec/trivy:latest image --severity HIGH,CRITICAL \
                    "$full_image" > "$report_file" 2>&1 || true
            fi
            
            if [ -f "$report_file" ] && [ -s "$report_file" ]; then
                local critical=$(grep -c "CRITICAL" "$report_file" 2>/dev/null || echo "0")
                local high=$(grep -c "HIGH" "$report_file" 2>/dev/null || echo "0")
                
                if [ "$critical" -gt 0 ]; then
                    echo -e "${RED}[SCAN]${NC} ${tag}: ${critical} CRITICAL, ${high} HIGH"
                elif [ "$high" -gt 0 ]; then
                    echo -e "${YELLOW}[SCAN]${NC} ${tag}: ${high} HIGH"
                else
                    echo -e "${GREEN}[SCAN]${NC} ${tag}: Clean"
                fi
            else
                echo -e "${GREEN}[SCAN]${NC} ${tag}: No vulnerabilities found"
            fi
        else
            echo -e "${YELLOW}[SCAN]${NC} ${tag}: Image not found locally"
        fi
    done
}

# ============================================
# Clean Images
# ============================================
clean_images() {
    print_header "Cleaning Local Images"
    
    for dir in "${!BUILD_MAP[@]}"; do
        local tag="${BUILD_MAP[$dir]}"
        local full_image="${DOCKER_USERNAME}/${IMAGE_BASE}:${tag}"
        
        if docker image inspect "$full_image" &> /dev/null; then
            echo "Removing: ${full_image}"
            docker rmi "$full_image" 2>/dev/null || true
        fi
    done
    
    echo ""
    echo "Pruning dangling images..."
    docker image prune -f
    
    print_success "Cleanup complete"
}

# ============================================
# Deploy Pipeline
# ============================================
deploy() {
    local total_start=$(date +%s)
    
    check_prerequisites
    check_docker_login
    
    build_all_sequential_with_push
    
    show_image_sizes
    print_summary
    generate_report
    
    local total_end=$(date +%s)
    local total_duration=$((total_end - total_start))
    
    echo ""
    print_info "Total Pipeline Time: ${total_duration}s"
}

# ============================================
# Show Usage
# ============================================
show_usage() {
    echo ""
    echo -e "${CYAN}Usage:${NC} $0 [command]"
    echo ""
    echo -e "${CYAN}Commands:${NC}"
    echo "  build    Build all images (no push)"
    echo "  push     Push all existing images"
    echo "  deploy   Build and push each image sequentially"
    echo "  scan     Scan all images for vulnerabilities"
    echo "  sizes    Show all image sizes"
    echo "  clean    Remove all local images"
    echo "  help     Show this help message"
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo "  $0 deploy    # Build and push all images"
    echo "  $0 build     # Only build, don't push"
    echo "  $0 push      # Only push existing images"
    echo "  $0 scan      # Scan for vulnerabilities"
    echo ""
    echo -e "${CYAN}Logs:${NC}"
    echo "  Build logs: ${LOG_DIR}/<tag>-build.log"
    echo "  Push logs:  ${LOG_DIR}/<tag>-push.log"
    echo "  Scan logs:  ${SCAN_DIR}/<tag>-scan.txt"
    echo ""
}

# ============================================
# Main
# ============================================
main() {
    cd "$(dirname "$0")"
    
    mkdir -p "$LOG_DIR" "$SCAN_DIR"
    
    case "${1:-help}" in
        build)
            check_prerequisites
            build_only
            show_image_sizes
            print_summary
            generate_report
            ;;
        push)
            push_only
            print_summary
            ;;
        deploy)
            deploy
            ;;
        scan)
            scan_all
            ;;
        sizes)
            show_image_sizes
            ;;
        clean)
            clean_images
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "Unknown command: $1"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"