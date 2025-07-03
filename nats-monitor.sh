#!/bin/bash
# nats-monitor.sh - NATS-based workflow monitoring and orchestration
# This demonstrates how NATS could be used for advanced GitHub workflow monitoring

set -e

NATS_URL="${NATS_URL:-nats://localhost:4222}"
GITHUB_ORG="joeblew999"
REPO="$GITHUB_ORG/.github"

echo "🚀 NATS GitHub Workflow Monitor"
echo "==============================="
echo "NATS Server: $NATS_URL"
echo "Organization: $GITHUB_ORG"
echo "Repository: $REPO"
echo ""

# Check if NATS CLI is available
check_nats_cli() {
    if ! command -v nats >/dev/null 2>&1; then
        echo "❌ NATS CLI not found. Install with:"
        echo "   go install github.com/nats-io/natscli/nats@latest"
        echo "   # or"
        echo "   brew install nats-io/nats-tools/nats"
        return 1
    fi
    echo "✅ NATS CLI available"
}

# Check NATS connection
check_nats_connection() {
    if ! nats --server="$NATS_URL" server check >/dev/null 2>&1; then
        echo "❌ Cannot connect to NATS server at $NATS_URL"
        echo ""
        echo "🐳 To start a local NATS server with Docker:"
        echo "   docker run -p 4222:4222 -p 8222:8222 nats:latest"
        echo ""
        echo "📦 Or install NATS server:"
        echo "   brew install nats-server"
        echo "   nats-server"
        return 1
    fi
    echo "✅ NATS server connected"
}

# Publish GitHub event to NATS
publish_github_event() {
    local event_type="$1"
    local data="$2"
    local subject="github.${GITHUB_ORG}.${event_type}"
    
    local payload=$(cat <<EOF
{
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)",
    "org": "$GITHUB_ORG",
    "repo": "$REPO",
    "event_type": "$event_type",
    "data": $data
}
EOF
)
    
    echo "📡 Publishing to NATS: $subject"
    echo "$payload" | nats --server="$NATS_URL" pub "$subject" --stdin
}

# Subscribe to GitHub events
monitor_events() {
    local subject="github.${GITHUB_ORG}.>"
    echo "👂 Monitoring NATS events: $subject"
    echo "   Press Ctrl+C to stop"
    echo ""
    
    nats --server="$NATS_URL" sub "$subject" --translate "jq .timestamp + ' - ' + .event_type + ': ' + (.data | tostring)"
}

# Workflow orchestration controller
workflow_controller() {
    echo "🎛️  Starting workflow controller..."
    echo "   This would handle complex multi-repo orchestration"
    echo ""
    
    # Subscribe to template change events
    nats --server="$NATS_URL" sub "github.${GITHUB_ORG}.template_changed" --queue="controllers" | while read -r event; do
        echo "🔄 Template change detected: $event"
        
        # Parse the event
        local repo_name=$(echo "$event" | jq -r '.data.repo // empty')
        local changed_files=$(echo "$event" | jq -r '.data.files[]? // empty')
        
        echo "   Repository: $repo_name"
        echo "   Changed files: $changed_files"
        
        # Trigger regeneration workflow
        echo "   Triggering regeneration..."
        publish_github_event "regeneration_requested" "{\"triggered_by\": \"controller\", \"repo\": \"$repo_name\"}"
        
        # In a real controller, we could:
        # - Coordinate updates across multiple repos
        # - Implement backpressure and rate limiting
        # - Handle failed regenerations with retry logic
        # - Send notifications to Slack/Discord
        # - Update external systems (databases, monitoring)
    done
}

# Monitor GitHub Actions using NATS
monitor_github_actions() {
    echo "🔍 Monitoring GitHub Actions via NATS..."
    
    # Simulate polling GitHub and publishing to NATS
    while true; do
        # Get latest workflow runs
        local runs=$(gh run list --repo "$REPO" --limit 1 --json conclusion,status,workflowName,createdAt,headSha 2>/dev/null || echo "[]")
        
        if [ "$runs" != "[]" ]; then
            local latest_run=$(echo "$runs" | jq '.[0]')
            local status=$(echo "$latest_run" | jq -r '.status')
            local workflow_name=$(echo "$latest_run" | jq -r '.workflowName')
            
            # Publish workflow status
            publish_github_event "workflow_status" "{\"workflow\": \"$workflow_name\", \"status\": \"$status\", \"run\": $latest_run}"
        fi
        
        sleep 30  # Poll every 30 seconds
    done
}

# Template change detector
detect_template_changes() {
    echo "📝 Monitoring template changes..."
    
    local last_commit=""
    while true; do
        local current_commit=$(gh api repos/$REPO/commits/main --jq '.sha' 2>/dev/null || echo "")
        
        if [ "$current_commit" != "$last_commit" ] && [ -n "$current_commit" ]; then
            # Check if templates changed
            local changed_files=$(gh api repos/$REPO/commits/$current_commit --jq '.files[].filename' 2>/dev/null | grep "^templates/" || echo "")
            
            if [ -n "$changed_files" ]; then
                echo "🔄 Template changes detected in commit $current_commit"
                
                # Publish template change event
                local files_json=$(echo "$changed_files" | jq -R . | jq -s .)
                publish_github_event "template_changed" "{\"commit\": \"$current_commit\", \"files\": $files_json}"
            fi
            
            last_commit="$current_commit"
        fi
        
        sleep 10  # Check every 10 seconds
    done
}

# NATS Stream setup for persistent events
setup_nats_streams() {
    echo "🗂️  Setting up NATS JetStream..."
    
    # Create stream for GitHub events
    nats --server="$NATS_URL" stream add GITHUB_EVENTS \
        --subjects="github.>" \
        --storage=file \
        --retention=limits \
        --max-age=24h \
        --max-msgs=10000 \
        --replicas=1 2>/dev/null || echo "Stream already exists"
    
    echo "✅ NATS streams configured"
}

# Dashboard - real-time event display
dashboard() {
    echo "📊 NATS GitHub Dashboard"
    echo "========================"
    
    # Show stream info
    echo "📈 Stream Statistics:"
    nats --server="$NATS_URL" stream info GITHUB_EVENTS --json 2>/dev/null | jq -r '
        "  Messages: " + (.state.messages | tostring) +
        "  Consumers: " + (.state.consumers | tostring) +
        "  Size: " + (.state.bytes | tostring) + " bytes"
    ' || echo "  Stream not available"
    
    echo ""
    echo "🕐 Recent Events:"
    nats --server="$NATS_URL" stream view GITHUB_EVENTS --limit=5 2>/dev/null | tail -n +2 || echo "  No events"
    
    echo ""
    echo "👂 Live Events (press Ctrl+C to stop):"
    monitor_events
}

# Enhanced workflow with NATS coordination
nats_enhanced_workflow() {
    echo "🚀 NATS-Enhanced GitHub Workflow"
    echo "================================="
    echo ""
    echo "This demonstrates how NATS could enhance the GitHub workflow:"
    echo ""
    echo "1. 📝 Developer pushes template change"
    echo "2. 🔍 NATS monitor detects change → publishes event"
    echo "3. 🎛️  Controller receives event → orchestrates response"
    echo "4. 🤖 GitHub Actions triggered → regenerates files"
    echo "5. ✅ Controller verifies completion → publishes success"
    echo "6. 📊 Dashboard shows real-time status"
    echo ""
    echo "Benefits:"
    echo "• 🔄 Real-time event streaming"
    echo "• 🎯 Precise event routing"
    echo "• 🛡️  Backpressure and rate limiting"
    echo "• 📈 Observability and metrics"
    echo "• 🔧 Multi-repo coordination"
    echo "• 💾 Event persistence and replay"
    echo ""
}

# GitOps Bootstrap - handling the chicken-and-egg problem
gitops_bootstrap() {
    echo "🥾 GitOps Bootstrap Strategy"
    echo "============================"
    echo ""
    echo "🐔🥚 The Bootstrap Problem:"
    echo "   Day 1: No servers → GitHub CI must bootstrap everything"
    echo "   Day N: Servers exist → NATS can orchestrate GitHub CI"
    echo ""
    
    # Check what infrastructure exists
    local nats_exists=false
    local terraform_state_exists=false
    
    echo "🔍 Infrastructure Discovery:"
    
    # Check if NATS is available
    if nats --server="$NATS_URL" server check >/dev/null 2>&1; then
        nats_exists=true
        echo "   ✅ NATS: Available"
    else
        echo "   ❌ NATS: Not available"
    fi
    
    # Check if Terraform state exists
    if [ -f "terraform/terraform.tfstate" ] || [ -n "$TF_BACKEND_CONFIG" ]; then
        terraform_state_exists=true
        echo "   ✅ Terraform State: Available"
    else
        echo "   ❌ Terraform State: Not available"
    fi
    
    echo ""
    echo "🎯 Bootstrap Strategy:"
    
    if [ "$nats_exists" = false ] && [ "$terraform_state_exists" = false ]; then
        echo "   📋 Stage 1: GitHub CI Bootstrap (cold start)"
        echo "      1. GitHub Actions creates Terraform backend"
        echo "      2. GitHub Actions deploys minimal NATS"
        echo "      3. GitHub Actions registers webhooks"
        echo "      4. Transition to Stage 2"
        
    elif [ "$nats_exists" = false ] && [ "$terraform_state_exists" = true ]; then
        echo "   📋 Stage 1.5: Terraform Recovery"
        echo "      1. GitHub Actions uses existing state"
        echo "      2. GitHub Actions deploys NATS infrastructure"
        echo "      3. Transition to Stage 2"
        
    elif [ "$nats_exists" = true ]; then
        echo "   📋 Stage 2: NATS Orchestration (steady state)"
        echo "      1. NATS receives infrastructure events"
        echo "      2. NATS triggers GitHub Actions via API"
        echo "      3. GitHub Actions executes deployment"
        echo "      4. NATS verifies completion"
    fi
    
    echo ""
    echo "🔄 Idempotency Checks:"
    echo "   • State validation before any action"
    echo "   • Distributed locking via NATS (when available)"
    echo "   • GitHub Actions idempotency tokens"
    echo "   • Terraform plan validation"
    echo ""
}

# Simulate the bootstrap decision tree
bootstrap_decision_tree() {
    echo "🌳 Bootstrap Decision Tree"
    echo "=========================="
    
    local stage="unknown"
    
    # Decision logic
    if ! nats --server="$NATS_URL" server check >/dev/null 2>&1; then
        if [ ! -f "terraform/terraform.tfstate" ]; then
            stage="cold_start"
        else
            stage="terraform_recovery"
        fi
    else
        stage="nats_orchestration"
    fi
    
    echo "🎯 Current Stage: $stage"
    echo ""
    
    case $stage in
        "cold_start")
            echo "❄️  Cold Start Bootstrap"
            echo "   GitHub CI must create everything from scratch"
            echo ""
            echo "   GitHub Actions Workflow:"
            echo "   1. 🏗️  terraform init (create backend)"
            echo "   2. 🚀 terraform apply (deploy NATS)"
            echo "   3. 🔗 setup webhooks"
            echo "   4. ✅ verify bootstrap"
            echo ""
            echo "   Next: Transition to NATS orchestration"
            ;;
            
        "terraform_recovery")
            echo "🔄 Terraform Recovery"
            echo "   State exists but NATS is down"
            echo ""
            echo "   GitHub Actions Workflow:"
            echo "   1. 📋 terraform plan (verify state)"
            echo "   2. 🚀 terraform apply (restore NATS)"
            echo "   3. ✅ verify recovery"
            echo ""
            echo "   Next: Resume NATS orchestration"
            ;;
            
        "nats_orchestration")
            echo "🎛️  NATS Orchestration (Steady State)"
            echo "   NATS coordinates all infrastructure"
            echo ""
            echo "   Event Flow:"
            echo "   1. 📨 Event → NATS"
            echo "   2. 🎯 NATS → GitHub API"
            echo "   3. 🤖 GitHub Actions → Deploy"
            echo "   4. ✅ Result → NATS"
            echo ""
            echo "   Benefits: Event-driven, reliable, observable"
            ;;
    esac
    
    echo ""
}

# Show GitHub CI integration patterns
github_ci_integration() {
    echo "🔗 GitHub CI Integration Patterns"
    echo "=================================="
    echo ""
    echo "🥾 Bootstrap Phase (GitHub CI leads):"
    echo "   .github/workflows/bootstrap.yml"
    echo "   • Checks infrastructure state"
    echo "   • Creates NATS if missing"
    echo "   • Registers webhooks"
    echo "   • Transitions control to NATS"
    echo ""
    echo "🎛️  Orchestration Phase (NATS leads):"
    echo "   .github/workflows/deploy.yml"
    echo "   • Triggered by NATS via GitHub API"
    echo "   • Receives deployment payload"
    echo "   • Executes Terraform/deployments"
    echo "   • Reports back to NATS"
    echo ""
    echo "🔄 Idempotency Mechanisms:"
    echo "   • NATS message IDs (deduplication)"
    echo "   • GitHub Actions run IDs (tracking)"
    echo "   • Terraform state locking"
    echo "   • Deployment status verification"
    echo ""
    echo "💡 Key Insight:"
    echo "   GitHub CI is both the bootstrap mechanism AND"
    echo "   the execution environment - NATS just orchestrates it!"
    echo ""
}

# Cost optimization with staged approach
staged_cost_optimization() {
    echo "💰 Staged Cost Optimization"
    echo "==========================="
    echo ""
    echo "📊 Cost by Stage:"
    echo ""
    echo "🥾 Bootstrap Stage (Day 1):"
    echo "   • GitHub Actions: \$0 (2000 free minutes)"
    echo "   • NATS creation: ~\$5-10 one-time"
    echo "   • Total: ~\$5-10"
    echo ""
    echo "🎛️  Orchestration Stage (Day 2+):"
    echo "   • Synadia Cloud: ~\$29/month (basic)"
    echo "   • GitHub Actions: \$0 (for coordination only)"
    echo "   • Cloudflare: ~\$5-10/month (if using containers)"
    echo "   • Total: ~\$30-40/month"
    echo ""
    echo "🎯 Optimization Strategy:"
    echo "   • Use NATS for lightweight coordination only"
    echo "   • Heavy lifting on free/cheap platforms"
    echo "   • Pay for reliability, not compute"
    echo ""
    echo "💡 The Trick You Asked About:"
    echo "   Use GitHub CI as the 'universal executor' but"
    echo "   NATS as the 'intelligent coordinator'!"
    echo ""
}

# Main menu
main() {
    if ! check_nats_cli; then
        exit 1
    fi
    
    echo "Available commands:"
    echo "1. check        - Check NATS connection"
    echo "2. setup        - Setup NATS streams"
    echo "3. monitor      - Monitor events"
    echo "4. controller   - Start workflow controller"
    echo "5. detect       - Detect template changes"
    echo "6. actions      - Monitor GitHub Actions"
    echo "7. dashboard    - Real-time dashboard"
    echo "8. demo         - Show enhanced workflow"
    echo "9. bootstrap    - Show GitOps bootstrap strategy"
    echo "10. decision    - Show bootstrap decision tree"
    echo "11. integration - Show GitHub CI integration"
    echo "12. costs       - Show staged cost optimization"
    echo ""
    
    case "${1:-menu}" in
        "check")
            check_nats_connection
            ;;
        "setup")
            check_nats_connection && setup_nats_streams
            ;;
        "monitor")
            check_nats_connection && monitor_events
            ;;
        "controller")
            check_nats_connection && workflow_controller
            ;;
        "detect")
            check_nats_connection && detect_template_changes &
            ;;
        "actions")
            check_nats_connection && monitor_github_actions &
            ;;
        "dashboard")
            check_nats_connection && dashboard
            ;;
        "demo")
            nats_enhanced_workflow
            ;;
        "bootstrap")
            gitops_bootstrap
            ;;
        "decision")
            bootstrap_decision_tree
            ;;
        "integration")
            github_ci_integration
            ;;
        "costs")
            staged_cost_optimization
            ;;
        *)
            read -p "Choose command (1-12): " choice
            case $choice in
                1) check_nats_connection ;;
                2) check_nats_connection && setup_nats_streams ;;
                3) check_nats_connection && monitor_events ;;
                4) check_nats_connection && workflow_controller ;;
                5) check_nats_connection && detect_template_changes ;;
                6) check_nats_connection && monitor_github_actions ;;
                7) check_nats_connection && dashboard ;;
                8) nats_enhanced_workflow ;;
                9) gitops_bootstrap ;;
                10) bootstrap_decision_tree ;;
                11) github_ci_integration ;;
                12) staged_cost_optimization ;;
                *) echo "Invalid choice" ;;
            esac
            ;;
    esac
}

main "$@"
