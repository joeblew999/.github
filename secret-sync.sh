#!/bin/bash
# secret-sync.sh - Synchronize secrets across platforms
# Handles .env → GitHub Secrets → Platform secrets

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
ENV_EXAMPLE_FILE="${SCRIPT_DIR}/.env.example"

echo "🔐 Secret Management & Sync"
echo "=========================="

# Create .env.example template
create_env_example() {
    echo "📝 Creating .env.example template..."
    
    cat > "$ENV_EXAMPLE_FILE" << 'EOF'
# GitHub Organization Configuration
GITHUB_ORG=joeblew999
GITHUB_TOKEN=ghp_your_github_token_here

# Synadia Cloud Configuration  
SYNADIA_TOKEN=your_synadia_token_here
SYNADIA_ACCOUNT=your_account_name
NATS_CREDS_FILE=path_to_nats_creds_file

# Cloudflare Configuration
CLOUDFLARE_API_TOKEN=your_cloudflare_api_token
CLOUDFLARE_ACCOUNT_ID=your_cloudflare_account_id
CLOUDFLARE_ZONE_ID=your_zone_id_if_using_custom_domain

# R2 Storage Configuration
CLOUDFLARE_R2_ACCESS_KEY=your_r2_access_key
CLOUDFLARE_R2_SECRET_KEY=your_r2_secret_key

# Terraform Backend Configuration (optional)
TF_BACKEND_TYPE=r2  # or 's3', 'local'
TF_STATE_BUCKET=terraform-state-joeblew999

# Development Configuration
NATS_URL=nats://localhost:4222
DEBUG=true
EOF
    
    echo "✅ Created .env.example"
}

# Check if .env exists
check_env_file() {
    if [ ! -f "$ENV_FILE" ]; then
        echo "❌ .env file not found!"
        echo ""
        echo "💡 To get started:"
        echo "   1. Copy .env.example to .env"
        echo "   2. Fill in your actual values"
        echo "   3. Run this script again"
        echo ""
        echo "   cp .env.example .env"
        echo "   # Edit .env with your values"
        echo ""
        return 1
    fi
    echo "✅ .env file found"
}

# Load environment variables
load_env() {
    if [ -f "$ENV_FILE" ]; then
        echo "📂 Loading environment variables..."
        set -a  # automatically export all variables
        source "$ENV_FILE"
        set +a
        echo "✅ Environment loaded"
    fi
}

# Validate required secrets
validate_secrets() {
    echo "🔍 Validating required secrets..."
    
    local missing_secrets=()
    
    # Check GitHub
    if [ -z "$GITHUB_TOKEN" ]; then
        missing_secrets+=("GITHUB_TOKEN")
    fi
    
    # Check at least one NATS option
    if [ -z "$SYNADIA_TOKEN" ] && [ -z "$NATS_URL" ]; then
        missing_secrets+=("SYNADIA_TOKEN or NATS_URL")
    fi
    
    if [ ${#missing_secrets[@]} -gt 0 ]; then
        echo "❌ Missing required secrets:"
        for secret in "${missing_secrets[@]}"; do
            echo "   - $secret"
        done
        echo ""
        echo "💡 Update your .env file with these values"
        return 1
    fi
    
    echo "✅ All required secrets present"
}

# Sync secrets to GitHub
sync_to_github() {
    echo "📤 Syncing secrets to GitHub..."
    
    if [ -z "$GITHUB_TOKEN" ]; then
        echo "❌ GITHUB_TOKEN required for GitHub sync"
        return 1
    fi
    
    # Set up gh CLI authentication
    export GH_TOKEN="$GITHUB_TOKEN"
    
    echo "🔄 Uploading secrets to GitHub repository..."
    
    # GitHub secrets
    [ -n "$GITHUB_TOKEN" ] && echo "GITHUB_TOKEN" | gh secret set GITHUB_TOKEN --body "$GITHUB_TOKEN"
    
    # Synadia secrets
    [ -n "$SYNADIA_TOKEN" ] && gh secret set SYNADIA_TOKEN --body "$SYNADIA_TOKEN"
    [ -n "$SYNADIA_ACCOUNT" ] && gh secret set SYNADIA_ACCOUNT --body "$SYNADIA_ACCOUNT"
    
    # NATS credentials (base64 encoded)
    if [ -n "$NATS_CREDS_FILE" ] && [ -f "$NATS_CREDS_FILE" ]; then
        NATS_CREDS_B64=$(cat "$NATS_CREDS_FILE" | base64 -w 0)
        gh secret set NATS_CREDS_FILE --body "$NATS_CREDS_B64"
    fi
    
    # Cloudflare secrets
    [ -n "$CLOUDFLARE_API_TOKEN" ] && gh secret set CLOUDFLARE_API_TOKEN --body "$CLOUDFLARE_API_TOKEN"
    [ -n "$CLOUDFLARE_ACCOUNT_ID" ] && gh secret set CLOUDFLARE_ACCOUNT_ID --body "$CLOUDFLARE_ACCOUNT_ID"
    [ -n "$CLOUDFLARE_ZONE_ID" ] && gh secret set CLOUDFLARE_ZONE_ID --body "$CLOUDFLARE_ZONE_ID"
    [ -n "$CLOUDFLARE_R2_ACCESS_KEY" ] && gh secret set CLOUDFLARE_R2_ACCESS_KEY --body "$CLOUDFLARE_R2_ACCESS_KEY"
    [ -n "$CLOUDFLARE_R2_SECRET_KEY" ] && gh secret set CLOUDFLARE_R2_SECRET_KEY --body "$CLOUDFLARE_R2_SECRET_KEY"
    
    # Terraform backend configuration
    [ -n "$TF_BACKEND_TYPE" ] && gh secret set TF_BACKEND_TYPE --body "$TF_BACKEND_TYPE"
    [ -n "$TF_STATE_BUCKET" ] && gh secret set TF_STATE_BUCKET --body "$TF_STATE_BUCKET"
    
    echo "✅ Secrets synced to GitHub"
}

# Test secret access
test_secrets() {
    echo "🧪 Testing secret access..."
    
    # Test GitHub
    if [ -n "$GITHUB_TOKEN" ]; then
        if gh auth status >/dev/null 2>&1; then
            echo "✅ GitHub: Authentication successful"
        else
            echo "❌ GitHub: Authentication failed"
        fi
    fi
    
    # Test NATS/Synadia
    if [ -n "$NATS_CREDS_FILE" ] && [ -f "$NATS_CREDS_FILE" ]; then
        if command -v nats >/dev/null 2>&1; then
            if nats --creds="$NATS_CREDS_FILE" server check >/dev/null 2>&1; then
                echo "✅ NATS: Connection successful"
            else
                echo "⚠️ NATS: Connection failed (server may be down)"
            fi
        else
            echo "⚠️ NATS CLI not installed"
        fi
    elif [ -n "$NATS_URL" ]; then
        if command -v nats >/dev/null 2>&1; then
            if nats --server="$NATS_URL" server check >/dev/null 2>&1; then
                echo "✅ NATS: Local connection successful"
            else
                echo "⚠️ NATS: Local server not running"
            fi
        fi
    fi
    
    # Test Cloudflare
    if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
        if command -v wrangler >/dev/null 2>&1; then
            export CLOUDFLARE_API_TOKEN
            if wrangler whoami >/dev/null 2>&1; then
                echo "✅ Cloudflare: Authentication successful"
            else
                echo "❌ Cloudflare: Authentication failed"
            fi
        else
            echo "⚠️ Wrangler CLI not installed"
        fi
    fi
}

# List current GitHub secrets
list_github_secrets() {
    echo "📋 Current GitHub Secrets:"
    echo "========================="
    
    if command -v gh >/dev/null 2>&1 && [ -n "$GITHUB_TOKEN" ]; then
        export GH_TOKEN="$GITHUB_TOKEN"
        gh secret list || echo "❌ Failed to list secrets"
    else
        echo "❌ GitHub CLI not available or GITHUB_TOKEN not set"
    fi
}

# Generate secure random secrets
generate_secrets() {
    echo "🎲 Generating secure random secrets..."
    
    # Generate API tokens (if not set)
    if [ -z "$WEBHOOK_SECRET" ]; then
        WEBHOOK_SECRET=$(openssl rand -hex 32)
        echo "Generated WEBHOOK_SECRET: $WEBHOOK_SECRET"
    fi
    
    # Add to .env if it exists
    if [ -f "$ENV_FILE" ]; then
        if ! grep -q "WEBHOOK_SECRET" "$ENV_FILE"; then
            echo "WEBHOOK_SECRET=$WEBHOOK_SECRET" >> "$ENV_FILE"
            echo "✅ Added WEBHOOK_SECRET to .env"
        fi
    fi
}

# Secret security check
security_check() {
    echo "🛡️ Security Check"
    echo "=================="
    
    # Check if .env is in .gitignore
    if [ -f ".gitignore" ]; then
        if grep -q "\.env" .gitignore; then
            echo "✅ .env is in .gitignore"
        else
            echo "⚠️ .env should be added to .gitignore"
            echo "   echo '.env' >> .gitignore"
        fi
    else
        echo "⚠️ No .gitignore found - create one!"
    fi
    
    # Check .env permissions
    if [ -f "$ENV_FILE" ]; then
        ENV_PERMS=$(stat -c "%a" "$ENV_FILE" 2>/dev/null || stat -f "%A" "$ENV_FILE" 2>/dev/null)
        if [ "$ENV_PERMS" = "600" ] || [ "$ENV_PERMS" = "0600" ]; then
            echo "✅ .env has secure permissions (600)"
        else
            echo "⚠️ .env permissions should be 600"
            echo "   chmod 600 .env"
        fi
    fi
    
    # Check for common secret leaks
    echo ""
    echo "🔍 Scanning for potential secret leaks..."
    if command -v git >/dev/null 2>&1; then
        # Check if any secrets are in git history
        SECRET_PATTERNS=("ghp_" "gho_" "ghu_" "ghs_" "github_pat_" "API_KEY" "SECRET" "TOKEN")
        for pattern in "${SECRET_PATTERNS[@]}"; do
            if git log --all --full-history -- . | grep -qi "$pattern" 2>/dev/null; then
                echo "⚠️ Potential secret pattern '$pattern' found in git history"
            fi
        done
        echo "✅ Git history scan complete"
    fi
}

# Main menu
main() {
    case "${1:-menu}" in
        "init")
            create_env_example
            echo ""
            echo "💡 Next steps:"
            echo "   1. cp .env.example .env"
            echo "   2. Edit .env with your actual values" 
            echo "   3. ./secret-sync.sh sync"
            ;;
        "sync")
            check_env_file && load_env && validate_secrets && sync_to_github
            ;;
        "test")
            check_env_file && load_env && test_secrets
            ;;
        "list")
            check_env_file && load_env && list_github_secrets
            ;;
        "generate")
            generate_secrets
            ;;
        "security")
            security_check
            ;;
        *)
            echo "Available commands:"
            echo "  init     - Create .env.example template"
            echo "  sync     - Sync .env secrets to GitHub"
            echo "  test     - Test secret access across platforms"
            echo "  list     - List current GitHub secrets"
            echo "  generate - Generate secure random secrets"
            echo "  security - Run security checks"
            echo ""
            echo "Usage: ./secret-sync.sh <command>"
            ;;
    esac
}

main "$@"
