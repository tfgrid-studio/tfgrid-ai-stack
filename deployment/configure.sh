#!/usr/bin/env bash
# Configure script - Set up SSL and domain configuration
# This runs after setup to configure external access

set -e

echo "⚙️ Configuring tfgrid-ai-stack SSL and domain..."

VM_IP="${PRIMARY_IP}"
SSH_KEY_PATH="${SSH_KEY_PATH}"

# Configure domain and SSL if provided
if [ -n "${DOMAIN}" ]; then
    echo "🔒 Setting up SSL for ${DOMAIN}..."

    ssh -i "${SSH_KEY_PATH}" -o StrictHostKeyChecking=no root@${VM_IP} << EOF
# Update nginx config with domain
sed -i "s/server_name _;/server_name ${DOMAIN};/" /etc/nginx/sites-available/ai-stack

# Get SSL certificate
certbot --nginx -d ${DOMAIN} --email ${SSL_EMAIL:-admin@${DOMAIN}} --agree-tos --non-interactive

# Reload nginx
systemctl reload nginx

echo "✅ SSL configured for ${DOMAIN}"
EOF
else
    echo "ℹ️ No domain specified - running in private mode"
fi

# Configure firewall for public access
ssh -i "${SSH_KEY_PATH}" -o StrictHostKeyChecking=no root@${VM_IP} << 'EOF'
ufw allow 80
ufw allow 443
ufw --force enable

echo "✅ Firewall configured"
EOF

echo "✅ Configuration completed"