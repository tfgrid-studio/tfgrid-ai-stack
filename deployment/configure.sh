#!/usr/bin/env bash
# Configure script - Set up SSL and domain configuration
# This runs after setup to configure external access

set -e

echo "⚙️ Configuring tfgrid-ai-stack SSL and domain..."

# Get VM IP from environment or try to detect it
VM_IP="${PRIMARY_IP}"
if [ -z "$VM_IP" ]; then
    # Try to get from state file with fallback to vm_ip
    if [ -f "/tmp/app-deployment/state.yaml" ]; then
        VM_IP=$(grep "^primary_ip:" /tmp/app-deployment/state.yaml 2>/dev/null | awk '{print $2}')
        # Fallback to vm_ip if primary_ip not found
        if [ -z "$VM_IP" ]; then
            VM_IP=$(grep "^vm_ip:" /tmp/app-deployment/state.yaml 2>/dev/null | awk '{print $2}')
        fi
    fi
    if [ -z "$VM_IP" ] && [ -f "/tmp/app-deployment/../state.yaml" ]; then
        VM_IP=$(grep "^primary_ip:" /tmp/app-deployment/../state.yaml 2>/dev/null | awk '{print $2}')
        # Fallback to vm_ip if primary_ip not found
        if [ -z "$VM_IP" ]; then
            VM_IP=$(grep "^vm_ip:" /tmp/app-deployment/../state.yaml 2>/dev/null | awk '{print $2}')
        fi
    fi
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
