#!/usr/bin/env bash
# Configure script - Wire together tfgrid-ai-stack components
# This runs after setup to configure networking and routing

set -e

echo "⚙️ Configuring tfgrid-ai-stack component integration..."

# Get component IPs from deployed apps
AI_AGENT_IP=$(tfgrid-compose info ai-agent-${DEPLOYMENT_NAME} | grep "IP:" | cut -d: -f2 | tr -d ' ')
GITEA_IP=$(tfgrid-compose info gitea-${DEPLOYMENT_NAME} | grep "IP:" | cut -d: -f2 | tr -d ' ')

# Configure Nginx on gateway VM to route traffic
cat > /tmp/nginx-sites << EOF
# AI Stack Gateway Configuration
server {
    listen 80;
    server_name ${DOMAIN:-_};

    # Git routing
    location /git/ {
        proxy_pass http://${GITEA_IP}:3000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # AI Agent API routing
    location /api/ {
        proxy_pass http://${AI_AGENT_IP}:8080/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # Project routing (dynamic)
    location ~ ^/project([0-9]+)/ {
        # This will be configured dynamically when projects are created
        return 404 "Project not found";
    }

    # Default: AI Stack dashboard
    location / {
        # Serve static dashboard or redirect to git
        return 302 /git/;
    }
}
EOF

# Copy nginx config to gateway VM
scp -i "${SSH_KEY_PATH}" -o StrictHostKeyChecking=no /tmp/nginx-sites root@${PRIMARY_IP}:/etc/nginx/sites-available/ai-stack
ssh -i "${SSH_KEY_PATH}" -o StrictHostKeyChecking=no root@${PRIMARY_IP} "ln -sf /etc/nginx/sites-available/ai-stack /etc/nginx/sites-enabled/ && systemctl reload nginx"

echo "✅ Component integration completed"