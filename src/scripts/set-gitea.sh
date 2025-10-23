#!/bin/bash
# Configure Gitea organization for AI projects

set -e

CONFIG_FILE="/opt/tfgrid-ai-stack/config/gitea.json"

echo "🏢 Gitea Organization Configuration"
echo "===================================="
echo ""

# Load current config
if [ -f "$CONFIG_FILE" ]; then
    CURRENT_ORG=$(jq -r '.default_org' "$CONFIG_FILE")
    GITEA_URL=$(jq -r '.gitea_url' "$CONFIG_FILE")
    API_TOKEN=$(jq -r '.api_token' "$CONFIG_FILE")
else
    echo "❌ Gitea config not found. Run setup first."
    exit 1
fi

echo "Current organization: $CURRENT_ORG"
echo ""

# Get org name from argument or prompt
ORG_NAME="${1:-}"

if [ -z "$ORG_NAME" ]; then
    echo "Options:"
    echo "  1. Keep current organization ($CURRENT_ORG)"
    echo "  2. Use existing organization"
    echo "  3. Create new organization"
    echo ""
    read -p "Choose option (1-3): " CHOICE

    case $CHOICE in
        1)
            echo "✅ Keeping current organization: $CURRENT_ORG"
            exit 0
            ;;
        2)
            # List existing organizations
            echo ""
            echo "Existing organizations:"
            curl -s "$GITEA_URL/api/v1/orgs" \
                -H "Authorization: token $API_TOKEN" | \
                jq -r '.[].username' | nl
            echo ""
            read -p "Enter organization name: " ORG_NAME
            ;;
        3)
            read -p "Enter new organization name: " ORG_NAME
            read -p "Display name [$ORG_NAME]: " DISPLAY_NAME
            DISPLAY_NAME="${DISPLAY_NAME:-$ORG_NAME}"
            read -p "Description [optional]: " DESCRIPTION

            # Create organization
            echo "🏢 Creating organization '$ORG_NAME'..."
            RESPONSE=$(curl -s -X POST "$GITEA_URL/api/v1/orgs" \
                -H "Authorization: token $API_TOKEN" \
                -H "Content-Type: application/json" \
                -d "{
                    \"username\": \"$ORG_NAME\",
                    \"full_name\": \"$DISPLAY_NAME\",
                    \"description\": \"$DESCRIPTION\",
                    \"visibility\": \"public\"
                }")

            if echo "$RESPONSE" | jq -e '.id' >/dev/null 2>&1; then
                echo "✅ Organization created"
            else
                echo "❌ Failed to create organization"
                echo "$RESPONSE" | jq .
                exit 1
            fi
            ;;
        *)
            echo "Invalid choice"
            exit 1
            ;;
    esac
fi

# Verify organization exists
ORG_CHECK=$(curl -s "$GITEA_URL/api/v1/orgs/$ORG_NAME" \
    -H "Authorization: token $API_TOKEN")

if ! echo "$ORG_CHECK" | jq -e '.id' >/dev/null 2>&1; then
    echo "❌ Organization '$ORG_NAME' not found"
    exit 1
fi

# Update config
jq ".default_org = \"$ORG_NAME\"" "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

echo ""
echo "✅ Default organization set to: $ORG_NAME"
echo ""
echo "All future projects will create repos in: $GITEA_URL/$ORG_NAME/"
echo "Existing projects are unchanged"