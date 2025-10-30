#!/bin/bash
# test-hosting-setup.sh - Test gateway hosting implementation
# Verifies all components are properly installed and configured

set -e

echo "🧪 Testing TFGrid AI Stack Gateway Hosting Implementation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if running in correct environment
if [ ! -d "tfgrid-studio/tfgrid-ai-stack" ]; then
    echo "❌ Error: Must run from tfgrid-studio root directory"
    exit 1
fi

# Function to check file exists and is executable
check_file() {
    local file="$1"
    local description="$2"
    
    if [ -f "$file" ]; then
        if [ -x "$file" ]; then
            echo "✅ $description: Found and executable"
            return 0
        else
            echo "⚠️  $description: Found but not executable"
            return 1
        fi
    else
        echo "❌ $description: Missing"
        return 1
    fi
}

# Function to check content in file
check_content() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    
    if [ -f "$file" ] && grep -q "$pattern" "$file" 2>/dev/null; then
        echo "✅ $description: Configured"
        return 0
    else
        echo "❌ $description: Missing or incomplete"
        return 1
    fi
}

echo "🔍 Checking Core Hosting Scripts..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check hosting scripts
check_file "tfgrid-studio/tfgrid-ai-stack/src/scripts/hosting-project.sh" "Hosting project functions"
check_file "tfgrid-studio/tfgrid-ai-stack/src/scripts/publish-project.sh" "Publish/unpublish script"
check_file "tfgrid-studio/tfgrid-ai-stack/src/scripts/t-hosting.sh" "CLI wrapper script"
check_file "tfgrid-studio/tfgrid-ai-stack/src/scripts/extend-nginx-config.sh" "Nginx configuration extension"

echo ""
echo "🔍 Checking Enhanced Scripts..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check enhanced scripts
check_content "tfgrid-studio/tfgrid-ai-stack/src/scripts/status-projects.sh" "hosting-project.sh" "Enhanced status script"

echo ""
echo "🔍 Checking Hosting API..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check hosting API
check_file "tfgrid-studio/tfgrid-ai-stack/src/agent/hosting-api.js" "Hosting API Node.js script"
check_file "tfgrid-studio/tfgrid-ai-stack/src/systemd/tfgrid-ai-hosting-api.service" "Hosting API systemd service"

echo ""
echo "🔍 Checking Documentation..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check documentation
check_file "tfgrid-studio/tfgrid-ai-stack/docs/GATEWAY-HOSTING.md" "Gateway hosting documentation"

echo ""
echo "🔍 Checking Implementation Structure..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Verify project structure
SCRIPTS_DIR="tfgrid-studio/tfgrid-ai-stack/src/scripts"
AGENT_DIR="tfgrid-studio/tfgrid-ai-stack/src/agent"
SYSTEMD_DIR="tfgrid-studio/tfgrid-ai-stack/src/systemd"
DOCS_DIR="tfgrid-studio/tfgrid-ai-stack/docs"

echo "📁 Expected directory structure:"
[ -d "$SCRIPTS_DIR" ] && echo "✅ Scripts directory: $SCRIPTS_DIR" || echo "❌ Scripts directory missing"
[ -d "$AGENT_DIR" ] && echo "✅ Agent directory: $AGENT_DIR" || echo "❌ Agent directory missing"
[ -d "$SYSTEMD_DIR" ] && echo "✅ Systemd directory: $SYSTEMD_DIR" || echo "❌ Systemd directory missing"
[ -d "$DOCS_DIR" ] && echo "✅ Documentation directory: $DOCS_DIR" || echo "❌ Documentation directory missing"

echo ""
echo "🔍 Checking Key Function Implementations..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check key functions in hosting-project.sh
check_content "tfgrid-studio/tfgrid-ai-stack/src/scripts/hosting-project.sh" "detect_project_type" "Project type detection"
check_content "tfgrid-studio/tfgrid-ai-stack/src/scripts/hosting-project.sh" "get_project_org" "Organization detection"
check_content "tfgrid-studio/tfgrid-ai-stack/src/scripts/hosting-project.sh" "is_project_hostable" "Hosting capability check"

# Check key functions in publish-project.sh
check_content "tfgrid-studio/tfgrid-ai-stack/src/scripts/publish-project.sh" "publish_project" "Publish functionality"
check_content "tfgrid-studio/tfgrid-ai-stack/src/scripts/publish-project.sh" "unpublish_project" "Unpublish functionality"
check_content "tfgrid-studio/tfgrid-ai-stack/src/scripts/publish-project.sh" "update_nginx_config" "Nginx config management"

# Check nginx configuration extension
check_content "tfgrid-studio/tfgrid-ai-stack/src/scripts/extend-nginx-config.sh" "DUAL-PURPOSE hosting" "Nginx hosting configuration"

echo ""
echo "🔍 Checking CLI Integration..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Check CLI commands
check_content "tfgrid-studio/tfgrid-ai-stack/src/scripts/t-hosting.sh" "publish.*name" "Publish command"
check_content "tfgrid-studio/tfgrid-ai-stack/src/scripts/t-hosting.sh" "unpublish.*name" "Unpublish command"
check_content "tfgrid-studio/tfgrid-ai-stack/src/scripts/t-hosting.sh" "status.*name" "Status command"
check_content "tfgrid-studio/tfgrid-ai-stack/src/scripts/t-hosting.sh" "setup-hosting" "Setup command"

echo ""
echo "🔍 Checking Enhanced Status Display..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Check enhanced status features
check_content "tfgrid-studio/tfgrid-ai-stack/src/scripts/status-projects.sh" "hosting_icon" "Hosting status icons"
check_content "tfgrid-studio/tfgrid-ai-stack/src/scripts/status-projects.sh" "org_name" "Organization display"
check_content "tfgrid-studio/tfgrid-ai-stack/src/scripts/status-projects.sh" "hosting.*URLs" "URL display"

echo ""
echo "🔍 Verifying Implementation Completeness..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Count implemented files
SCRIPT_COUNT=$(find "$SCRIPTS_DIR" -name "*hosting*" -o -name "*publish*" -o -name "*t-hosting*" -o -name "*extend-nginx*" | wc -l)
AGENT_COUNT=$(find "$AGENT_DIR" -name "*hosting*" 2>/dev/null | wc -l)
SYSTEMD_COUNT=$(find "$SYSTEMD_DIR" -name "*hosting*" 2>/dev/null | wc -l)
DOC_COUNT=$(find "$DOCS_DIR" -name "*hosting*" 2>/dev/null | wc -l)

echo "📊 Implementation statistics:"
echo "   🔧 Hosting scripts: $SCRIPT_COUNT files"
echo "   🌐 Hosting API files: $AGENT_COUNT files"
echo "   ⚙️  Systemd services: $SYSTEMD_COUNT files"
echo "   📚 Documentation: $DOC_COUNT files"

echo ""
echo "🔍 Checking Plan Alignment..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Verify implementation matches the plan
PLAN_ALIGNMENT=true

# Check if plan exists and was updated
if [ -f "tfgrid-studio/tfgrid-internal/gateway-project-hosting-plan.md" ]; then
    echo "✅ Implementation plan found and updated"
    
    # Check key plan elements are reflected in implementation
    check_content "tfgrid-studio/tfgrid-internal/gateway-project-hosting-plan.md" "/web/.*org.*repo-name" "Organized URL structure in plan"
    check_content "tfgrid-studio/tfgrid-internal/gateway-project-hosting-plan.md" "Single-VM.*gateway" "Single-VM approach in plan"
    check_content "tfgrid-studio/tfgrid-internal/gateway-project-hosting-plan.md" "ai-stack.*nginx" "nginx extension in plan"
else
    echo "⚠️  Implementation plan not found"
    PLAN_ALIGNMENT=false
fi

echo ""
echo "🎯 Implementation Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

IMPLEMENTATION_SCORE=0
TOTAL_CHECKS=15

# Calculate implementation score
if check_file "tfgrid-studio/tfgrid-ai-stack/src/scripts/hosting-project.sh" "" >/dev/null 2>&1; then ((IMPLEMENTATION_SCORE++)); fi
if check_file "tfgrid-studio/tfgrid-ai-stack/src/scripts/publish-project.sh" "" >/dev/null 2>&1; then ((IMPLEMENTATION_SCORE++)); fi
if check_file "tfgrid-studio/tfgrid-ai-stack/src/scripts/t-hosting.sh" "" >/dev/null 2>&1; then ((IMPLEMENTATION_SCORE++)); fi
if check_file "tfgrid-studio/tfgrid-ai-stack/src/scripts/extend-nginx-config.sh" "" >/dev/null 2>&1; then ((IMPLEMENTATION_SCORE++)); fi
if check_content "tfgrid-studio/tfgrid-ai-stack/src/scripts/status-projects.sh" "hosting" "" >/dev/null 2>&1; then ((IMPLEMENTATION_SCORE++)); fi
if check_file "tfgrid-studio/tfgrid-ai-stack/src/agent/hosting-api.js" "" >/dev/null 2>&1; then ((IMPLEMENTATION_SCORE++)); fi
if check_file "tfgrid-studio/tfgrid-ai-stack/src/systemd/tfgrid-ai-hosting-api.service" "" >/dev/null 2>&1; then ((IMPLEMENTATION_SCORE++)); fi
if check_file "tfgrid-studio/tfgrid-ai-stack/docs/GATEWAY-HOSTING.md" "" >/dev/null 2>&1; then ((IMPLEMENTATION_SCORE++)); fi
if [ "$PLAN_ALIGNMENT" = true ]; then ((IMPLEMENTATION_SCORE++)); fi

echo "📈 Implementation Score: $IMPLEMENTATION_SCORE/$TOTAL_CHECKS"

if [ $IMPLEMENTATION_SCORE -eq $TOTAL_CHECKS ]; then
    echo "🎉 EXCELLENT: Gateway hosting fully implemented!"
elif [ $IMPLEMENTATION_SCORE -gt $((TOTAL_CHECKS * 80 / 100)) ]; then
    echo "✅ GOOD: Core hosting functionality implemented"
elif [ $IMPLEMENTATION_SCORE -gt $((TOTAL_CHECKS * 60 / 100)) ]; then
    echo "⚠️  PARTIAL: Basic implementation present, some features missing"
else
    echo "❌ INCOMPLETE: Major implementation gaps"
fi

echo ""
echo "🚀 Next Steps for Deployment:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Run hosting setup: t setup-hosting
2. Test with a project: t publish test-project
3. Check enhanced status: tfgrid-compose status
4. Review hosting health: t hosting-health
5. Read documentation: tfgrid-ai-stack/docs/GATEWAY-HOSTING.md"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 Gateway Hosting Implementation Test Complete"