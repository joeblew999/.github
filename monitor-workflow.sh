#!/bin/bash
# monitor-workflow.sh - Monitor the full template → GitHub Actions → regeneration workflow

set -e

GITHUB_ORG="joeblew999"
REPO="$GITHUB_ORG/.github"

echo "🔍 GitHub Workflow Monitor"
echo "=========================="
echo "Organization: $GITHUB_ORG"
echo "Repository: $REPO"
echo ""

# Function to check if GitHub CLI is authenticated
check_gh_auth() {
    if ! gh auth status >/dev/null 2>&1; then
        echo "❌ GitHub CLI not authenticated. Run: gh auth login"
        exit 1
    fi
    echo "✅ GitHub CLI authenticated"
}

# Function to get the latest commit
get_latest_commit() {
    gh api repos/$REPO/commits/main --jq '.sha[0:7] + " - " + .commit.message' 2>/dev/null || echo "Unable to fetch"
}

# Function to get workflow runs
get_workflow_runs() {
    echo "📋 Recent Workflow Runs:"
    gh run list --repo $REPO --limit 5 --json conclusion,status,workflowName,createdAt,headSha --template '
{{- range . -}}
{{- $time := timeago .createdAt -}}
{{- if eq .conclusion "success" -}}✅{{- else if eq .conclusion "failure" -}}❌{{- else if eq .status "in_progress" -}}🔄{{- else -}}⏳{{- end -}} 
{{ .workflowName }} ({{ $time }}) - {{ .headSha | slice 0 7 }}
{{ end -}}' 2>/dev/null || echo "  Unable to fetch workflow runs"
}

# Function to check if files were regenerated
check_regeneration() {
    echo "🔍 Checking if files are being regenerated..."
    
    # Look for recent commits with [skip-regen] tag
    echo "📝 Recent regeneration commits:"
    gh api repos/$REPO/commits --jq '.[] | select(.commit.message | contains("[skip-regen]")) | "  " + (.sha[0:7]) + " - " + .commit.message' 2>/dev/null | head -3 || echo "  No regeneration commits found"
}

# Function to compare local vs GitHub
compare_with_github() {
    echo "🔄 Comparing local generated files with GitHub..."
    
    # Check if PR template was updated
    LOCAL_PR_TEMPLATE=".github/pull_request_template.md"
    if [ -f "$LOCAL_PR_TEMPLATE" ]; then
        echo "  Local PR template exists"
        if grep -q "Template update" "$LOCAL_PR_TEMPLATE"; then
            echo "  ✅ Local template has test marker"
        else
            echo "  ❌ Local template missing test marker"
        fi
        
        # Check GitHub version
        if gh api repos/$REPO/contents/.github/pull_request_template.md --jq '.content' 2>/dev/null | base64 -d | grep -q "Template update"; then
            echo "  ✅ GitHub template has test marker"
        else
            echo "  ❌ GitHub template missing test marker (may not be regenerated yet)"
        fi
    else
        echo "  ❌ Local PR template not found"
    fi
}

# Function to monitor workflow in real-time
monitor_realtime() {
    echo "⏰ Monitoring workflow execution..."
    echo "   Press Ctrl+C to stop monitoring"
    echo ""
    
    local count=0
    while [ $count -lt 30 ]; do  # Monitor for 5 minutes max
        echo -n "."
        
        # Check if there's an active workflow
        ACTIVE=$(gh run list --repo $REPO --status in_progress --json workflowName --template '{{len .}}' 2>/dev/null || echo "0")
        
        if [ "$ACTIVE" -gt 0 ]; then
            echo ""
            echo "🔄 Active workflow detected!"
            gh run list --repo $REPO --status in_progress --json workflowName,createdAt --template '
{{- range . -}}
  Running: {{ .workflowName }} ({{ timeago .createdAt }})
{{ end -}}' 2>/dev/null
            
            # Wait for completion
            echo "   Waiting for completion..."
            sleep 10
        else
            sleep 10
        fi
        
        count=$((count + 1))
    done
    echo ""
}

# Main execution
main() {
    check_gh_auth
    echo ""
    
    echo "📊 Current State:"
    echo "  Latest commit: $(get_latest_commit)"
    echo ""
    
    get_workflow_runs
    echo ""
    
    check_regeneration
    echo ""
    
    compare_with_github
    echo ""
    
    echo "🚀 How to test the full workflow:"
    echo "1. Make a change to any file in templates/"
    echo "2. Commit and push: git add . && git commit -m 'test: update template' && git push"
    echo "3. Run this script to monitor: ./monitor-workflow.sh"
    echo "4. Watch for:"
    echo "   - GitHub Actions workflow triggers"
    echo "   - New commit with [skip-regen] appears"
    echo "   - Generated files update on GitHub"
    echo ""
    
    read -p "🔄 Monitor workflow execution now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        monitor_realtime
        echo ""
        echo "🔍 Final check:"
        get_workflow_runs
        echo ""
        compare_with_github
    fi
}

main "$@"
