#!/usr/bin/env bash
# Configure script - Set up SSL and domain configuration
# This runs after setup to configure external access

set -e

echo "⚙️ Configuring tfgrid-ai-stack SSL and domain..."

# Source shared network helper for VM IP resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "/opt/tfgrid-ai-stack/scripts/network-helper.sh" ]; then
	source "/opt/tfgrid-ai-stack/scripts/network-helper.sh"
elif [ -f "$SCRIPT_DIR/../scripts/network-helper.sh" ]; then
	source "$SCRIPT_DIR/../scripts/network-helper.sh"
fi

# Get VM IP using network-aware selection
VM_IP="${PRIMARY_IP}"
if [ -z "$VM_IP" ]; then
	VM_IP=$(get_deployment_ip_vm)
fi

# Configure Gitea with network-aware ROOT_URL
echo "🌐 Configuring Gitea for network preference..."
configure_gitea_for_network() {
    local vm_ip="$1"

    # Get network preference - try environment variable first, then state file
    local network_preference="${NETWORK_PREFERENCE:-wireguard}"
    if [ -f "/opt/tfgrid-ai-stack/.gitea_network_config" ]; then
        local net_pref_from_file=$(grep "^mycelium_network_preference:" /opt/tfgrid-ai-stack/.gitea_network_config | cut -d':' -f2 | tr -d ' ')
        if [ -n "$net_pref_from_file" ] && [ "$net_pref_from_file" != "unknown" ]; then
            network_preference="$net_pref_from_file"
        fi
    fi

    echo "  Network preference: $network_preference"
    echo "  VM IP: ${vm_ip}"

    # Determine ROOT_URL based on network preference
    local root_url=""
    if [ "$network_preference" = "mycelium" ]; then
        # Use mycelium IPv6 with brackets for URL
        root_url="http://[${vm_ip}]/git/"
    else
        # Use wireguard IPv4
        root_url="http://${vm_ip}/git/"
    fi

    echo "  Gitea ROOT_URL: $root_url"

    # Update Gitea configuration
    if [ -f "/etc/gitea/app.ini" ]; then
        sed -i "s|^ROOT_URL.*|ROOT_URL = ${root_url}|" /etc/gitea/app.ini
        echo "  ✅ Gitea app.ini updated"
    fi

    # Update gitea.json configuration
    if [ -f "/opt/tfgrid-ai-stack/config/gitea.json" ]; then
        local gitea_json_external_url=""
        if [ "$network_preference" = "mycelium" ]; then
            gitea_json_external_url="http://[${vm_ip}]:3000"
        else
            gitea_json_external_url="http://${vm_ip}:3000"
        fi

        # Use jq if available, otherwise sed
        if command -v jq &> /dev/null && jq --version >/dev/null 2>&1; then
            jq --arg url "$gitea_json_external_url" '.gitea_url = $url' /opt/tfgrid-ai-stack/config/gitea.json > /tmp/gitea_config_temp.json
            if [ $? -eq 0 ]; then
                mv /tmp/gitea_config_temp.json /opt/tfgrid-ai-stack/config/gitea.json
                echo "  ✅ gitea.json updated with jq"
            fi
        fi
    fi

    # Restart Gitea to apply changes
    if systemctl is-active --quiet gitea; then
        systemctl restart gitea
        sleep 3
        echo "  ✅ Gitea restarted"
    fi
}

# Always configure Gitea (regardless of domain settings)
if [ -n "$VM_IP" ]; then
    configure_gitea_for_network "$VM_IP"
else
    echo "ℹ️ VM IP not available for Gitea configuration"
    echo "ℹ️ Gitea will remain configured for localhost access"
fi

# Get SSH key path from environment or use default
SSH_KEY_PATH="${SSH_KEY_PATH}"
if [ -z "$SSH_KEY_PATH" ]; then
    # Try common SSH key locations
    if [ -f "$HOME/.ssh/id_rsa" ]; then
        SSH_KEY_PATH="$HOME/.ssh/id_rsa"
    elif [ -f "$HOME/.ssh/id_ed25519" ]; then
        SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
    fi
fi

# For private deployments (no domain), skip SSH-based configuration
if [ -z "${DOMAIN}" ]; then
    echo "ℹ️ No domain specified - running in private mode"
    echo "ℹ️ Skipping external configuration (SSL, firewall) for private deployment"
    echo "✅ Configuration completed (private mode)"
    exit 0
fi

# Validate required variables for domain configuration
if [ -z "$VM_IP" ]; then
    echo "❌ Cannot configure domain: PRIMARY_IP not available"
    echo "ℹ️ This is expected for private deployments without domain"
    exit 0
fi

if [ -z "$SSH_KEY_PATH" ] || [ ! -f "$SSH_KEY_PATH" ]; then
    echo "❌ Cannot configure domain: SSH key not found at $SSH_KEY_PATH"
    echo "ℹ️ This is expected for private deployments without domain"
    exit 0
fi

# Configure domain and SSL if provided
echo "🔒 Setting up SSL for ${DOMAIN}..."

ssh -i "${SSH_KEY_PATH}" -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@${VM_IP} << EOF
# Update nginx config with domain
sed -i "s/server_name _;/server_name ${DOMAIN};/" /etc/nginx/sites-available/ai-stack

# Get SSL certificate
certbot --nginx -d ${DOMAIN} --email ${SSL_EMAIL:-admin@${DOMAIN}} --agree-tos --non-interactive

# Reload nginx
systemctl reload nginx

echo "✅ SSL configured for ${DOMAIN}"
EOF

# Configure firewall for public access
ssh -i "${SSH_KEY_PATH}" -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@${VM_IP} << 'EOF'
ufw allow 80
ufw allow 443
ufw --force enable

echo "✅ Firewall configured"
EOF

echo "✅ Configuration completed"
