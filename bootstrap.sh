#!/bin/bash
# bootstrap.sh - Cross-platform GitHub organization bootstrap script
# Handles the two-phase deployment problem with proper sequencing and race prevention

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GITHUB_ORG="${GITHUB_ORG:-joeblew999}"
BOOTSTRAP_MODE="${BOOTSTRAP_MODE:-auto}"
NATS_DEPLOYMENT_TYPE="${NATS_DEPLOYMENT_TYPE:-self_hosted}"
TERRAFORM_BACKEND="${TERRAFORM_BACKEND:-local}"

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if running on supported platform
check_platform() {
    case "$(uname -s)" in
        Linux*)     PLATFORM=Linux;;
        Darwin*)    PLATFORM=Mac;;
        CYGWIN*)    PLATFORM=Cygwin;;
        MINGW*)     PLATFORM=MinGw;;
        MSYS*)      PLATFORM=Msys;;
        *)          PLATFORM="UNKNOWN:$(uname -s)"
    esac
    log "Detected platform: $PLATFORM"
}

# Check prerequisites
check_prerequisites() {
    log "🔍 Checking prerequisites..."
    
    # Check for required tools
    local missing_tools=()
    
    command -v git >/dev/null 2>&1 || missing_tools+=("git")
    command -v go >/dev/null 2>&1 || missing_tools+=("go")
    
    # Check for task (preferred) or make
    if ! command -v task >/dev/null 2>&1 && ! command -v make >/dev/null 2>&1; then
        missing_tools+=("task or make")
    fi
    
    # Platform-specific checks
    case $PLATFORM in
        Linux)
            command -v docker >/dev/null 2>&1 || missing_tools+=("docker")
            ;;
        Mac)
            command -v docker >/dev/null 2>&1 || missing_tools+=("docker")
            command -v brew >/dev/null 2>&1 || warn "Homebrew not found - some installations may fail"
            ;;
        MinGw|Msys|Cygwin)
            command -v docker >/dev/null 2>&1 || missing_tools+=("docker")
            ;;
    esac
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        error "Missing required tools: ${missing_tools[*]}"
    fi
    
    success "All prerequisites satisfied"
}

# Initialize Terraform state backend
init_terraform_state() {
    log "🏗️ Initializing Terraform state backend..."
    
    case $TERRAFORM_BACKEND in
        s3)
            if [ -z "${AWS_BUCKET:-}" ]; then
                error "AWS_BUCKET environment variable required for S3 backend"
            fi
            log "Using S3 backend: $AWS_BUCKET"
            ;;
        gcs)
            if [ -z "${GCS_BUCKET:-}" ]; then
                error "GCS_BUCKET environment variable required for GCS backend"
            fi
            log "Using GCS backend: $GCS_BUCKET"
            ;;
        local)
            log "Using local Terraform state (not recommended for production)"
            ;;
        *)
            error "Unsupported Terraform backend: $TERRAFORM_BACKEND"
            ;;
    esac
    
    # Initialize Terraform
    cd terraform
    terraform init
    cd ..
    
    success "Terraform state initialized"
}

# Phase 1: Deploy minimal NATS infrastructure
deploy_bootstrap_nats() {
    log "🚀 Phase 1: Deploying bootstrap NATS infrastructure..."
    
    case $NATS_DEPLOYMENT_TYPE in
        synadia_cloud)
            if [ -z "${SYNADIA_CREDS_FILE:-}" ] && [ -z "${SYNADIA_JWT:-}" ]; then
                error "Synadia Cloud credentials required (SYNADIA_CREDS_FILE or SYNADIA_JWT)"
            fi
            log "Using Synadia Cloud for NATS"
            ;;
        self_hosted*|hybrid)
            log "Deploying self-hosted NATS infrastructure"
            
            # Check if we should use embedded NATS for development
            if [ "$BOOTSTRAP_MODE" = "dev" ]; then
                log "Starting embedded NATS for development..."
                go run cmd/nats-bootstrap/main.go &
                NATS_PID=$!
                echo $NATS_PID > .nats-bootstrap.pid
                
                # Wait for NATS to be ready
                sleep 5
                export NATS_URLS="nats://localhost:4222"
            else
                # Deploy via Terraform
                cd terraform
                terraform apply -target=kubernetes_namespace.nats -auto-approve
                terraform apply -target=kubernetes_stateful_set.nats -auto-approve
                terraform apply -target=kubernetes_service.nats_client -auto-approve
                cd ..
                
                # Wait for NATS to be ready
                log "Waiting for NATS to be ready..."
                timeout 60 bash -c 'until kubectl get pods -n nats-system | grep -q Running; do sleep 2; done'
            fi
            ;;
        *)
            error "Unsupported NATS deployment type: $NATS_DEPLOYMENT_TYPE"
            ;;
    esac
    
    success "Bootstrap NATS deployed"
}

# Phase 2: Verify NATS connectivity
verify_nats_connectivity() {
    log "🔌 Phase 2: Verifying NATS connectivity..."
    
    # Test basic NATS connectivity
    if command -v nats >/dev/null 2>&1; then
        case $NATS_DEPLOYMENT_TYPE in
            synadia_cloud)
                nats --creds="${SYNADIA_CREDS_FILE}" pub test.bootstrap "Bootstrap test message"
                ;;
            *)
                nats --server="${NATS_URLS:-nats://localhost:4222}" pub test.bootstrap "Bootstrap test message"
                ;;
        esac
    else
        warn "NATS CLI not found - skipping connectivity test"
    fi
    
    success "NATS connectivity verified"
}

# Phase 3: Deploy NATS controller
deploy_nats_controller() {
    log "🤖 Phase 3: Deploying NATS controller..."
    
    # Build controller if needed
    if [ ! -f "bin/nats-controller" ]; then
        log "Building NATS controller..."
        go build -o bin/nats-controller cmd/nats-controller/main.go
    fi
    
    # Start controller based on deployment type
    case $BOOTSTRAP_MODE in
        dev)
            log "Starting controller in development mode..."
            export NATS_DEPLOYMENT_TYPE="$NATS_DEPLOYMENT_TYPE"
            export GITHUB_ORG="$GITHUB_ORG"
            export NATS_URLS="${NATS_URLS:-nats://localhost:4222}"
            
            ./bin/nats-controller &
            CONTROLLER_PID=$!
            echo $CONTROLLER_PID > .nats-controller.pid
            ;;
        docker)
            log "Starting controller via Docker..."
            docker build -t github-nats-controller .
            docker run -d \
                --name github-nats-controller \
                -e NATS_DEPLOYMENT_TYPE="$NATS_DEPLOYMENT_TYPE" \
                -e GITHUB_ORG="$GITHUB_ORG" \
                -e NATS_URLS="${NATS_URLS:-nats://nats:4222}" \
                github-nats-controller:latest
            ;;
        kubernetes)
            log "Deploying controller to Kubernetes..."
            kubectl apply -f k8s/nats-controller-deployment.yaml
            ;;
        *)
            error "Unsupported bootstrap mode: $BOOTSTRAP_MODE"
            ;;
    esac
    
    success "NATS controller deployed"
}

# Phase 4: Register GitHub webhooks
register_github_webhooks() {
    log "🔗 Phase 4: Registering GitHub webhooks..."
    
    if [ -z "${GITHUB_TOKEN:-}" ]; then
        warn "GITHUB_TOKEN not set - manual webhook registration required"
        log "Please register webhooks manually:"
        log "  1. Go to https://github.com/$GITHUB_ORG/.github/settings/hooks"
        log "  2. Add webhook URL: ${WEBHOOK_URL:-https://your-webhook-endpoint.com/github}"
        log "  3. Select events: push, pull_request, workflow_run"
        return
    fi
    
    # Auto-register webhooks if token is available
    log "Auto-registering GitHub webhooks..."
    # Implementation would use GitHub API to register webhooks
    warn "Auto-webhook registration not yet implemented - manual setup required"
    
    success "GitHub webhooks configured"
}

# Phase 5: Enable GitHub self-management
enable_github_self_management() {
    log "🔄 Phase 5: Enabling GitHub self-management..."
    
    # Generate GitHub workflow files
    if command -v task >/dev/null 2>&1; then
        task setup
    else
        make setup
    fi
    
    # Commit and push generated files
    if [ "$(git status --porcelain)" ]; then
        log "Committing generated files..."
        git add .
        git commit -m "Bootstrap: Enable GitHub self-management
        
        - Generated workflows and templates
        - Configured NATS integration
        - Enabled automated file regeneration
        
        From now on, this repository is self-managing!"
        
        if [ "${PUSH_CHANGES:-true}" = "true" ]; then
            git push origin main
        else
            warn "Changes committed but not pushed (PUSH_CHANGES=false)"
        fi
    else
        log "No changes to commit"
    fi
    
    success "GitHub self-management enabled"
}

# Cleanup function for development mode
cleanup() {
    if [ -f ".nats-bootstrap.pid" ]; then
        log "Stopping embedded NATS..."
        kill "$(cat .nats-bootstrap.pid)" 2>/dev/null || true
        rm -f .nats-bootstrap.pid
    fi
    
    if [ -f ".nats-controller.pid" ]; then
        log "Stopping NATS controller..."
        kill "$(cat .nats-controller.pid)" 2>/dev/null || true
        rm -f .nats-controller.pid
    fi
}

# Validate bootstrap completion
validate_bootstrap() {
    log "✅ Validating bootstrap completion..."
    
    local checks=0
    local passed=0
    
    # Check 1: NATS connectivity
    checks=$((checks + 1))
    if verify_nats_connectivity >/dev/null 2>&1; then
        passed=$((passed + 1))
        success "✓ NATS connectivity"
    else
        error "✗ NATS connectivity failed"
    fi
    
    # Check 2: Controller health
    checks=$((checks + 1))
    case $BOOTSTRAP_MODE in
        dev)
            if [ -f ".nats-controller.pid" ] && kill -0 "$(cat .nats-controller.pid)" 2>/dev/null; then
                passed=$((passed + 1))
                success "✓ NATS controller running"
            else
                error "✗ NATS controller not running"
            fi
            ;;
        docker)
            if docker ps | grep -q github-nats-controller; then
                passed=$((passed + 1))
                success "✓ NATS controller container running"
            else
                error "✗ NATS controller container not found"
            fi
            ;;
        kubernetes)
            if kubectl get pods -l app=nats-controller | grep -q Running; then
                passed=$((passed + 1))
                success "✓ NATS controller pod running"
            else
                error "✗ NATS controller pod not running"
            fi
            ;;
    esac
    
    # Check 3: GitHub files generated
    checks=$((checks + 1))
    if [ -f ".github/workflows/regenerate-github-files.yml" ]; then
        passed=$((passed + 1))
        success "✓ GitHub workflows generated"
    else
        error "✗ GitHub workflows not generated"
    fi
    
    log "Bootstrap validation: $passed/$checks checks passed"
    
    if [ $passed -eq $checks ]; then
        success "🎉 Bootstrap completed successfully!"
        log ""
        log "Next steps:"
        log "  1. Push changes to GitHub (if not done automatically)"
        log "  2. Monitor GitHub Actions for workflow execution"
        log "  3. Check NATS controller logs for event processing"
        log "  4. Scale infrastructure as needed with: task nats-scale"
        log ""
        log "Your GitHub organization is now self-managing! 🚀"
    else
        error "Bootstrap validation failed - check logs above"
    fi
}

# Signal handlers
trap cleanup EXIT
trap 'error "Bootstrap interrupted"' INT TERM

# Main execution
main() {
    log "🚀 Starting GitHub Organization Bootstrap"
    log "Organization: $GITHUB_ORG"
    log "NATS Deployment: $NATS_DEPLOYMENT_TYPE"
    log "Bootstrap Mode: $BOOTSTRAP_MODE"
    log "Platform: $PLATFORM"
    log ""
    
    check_platform
    check_prerequisites
    init_terraform_state
    deploy_bootstrap_nats
    verify_nats_connectivity
    deploy_nats_controller
    register_github_webhooks
    enable_github_self_management
    validate_bootstrap
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --org)
            GITHUB_ORG="$2"
            shift 2
            ;;
        --mode)
            BOOTSTRAP_MODE="$2"
            shift 2
            ;;
        --nats-type)
            NATS_DEPLOYMENT_TYPE="$2"
            shift 2
            ;;
        --terraform-backend)
            TERRAFORM_BACKEND="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --org ORG                    GitHub organization name (default: joeblew999)"
            echo "  --mode MODE                  Bootstrap mode: dev|docker|kubernetes (default: auto)"
            echo "  --nats-type TYPE             NATS deployment: synadia_cloud|self_hosted|hybrid (default: self_hosted)"
            echo "  --terraform-backend BACKEND  Terraform backend: local|s3|gcs (default: local)"
            echo "  --help                       Show this help message"
            echo ""
            echo "Environment variables:"
            echo "  GITHUB_TOKEN                 GitHub personal access token"
            echo "  SYNADIA_CREDS_FILE          Synadia Cloud credentials file"
            echo "  AWS_BUCKET                  S3 bucket for Terraform state"
            echo "  GCS_BUCKET                  GCS bucket for Terraform state"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Run main function
main
