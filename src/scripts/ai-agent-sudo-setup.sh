#!/bin/bash
# AI Agent Sudo Setup - Give AI agent full permissions for web hosting
# Run this to enable the AI agent to manage nginx, create files, and deploy websites

echo "🔐 Setting up AI agent sudo permissions for web hosting..."

# Create sudoers file for developer user (AI agent user)
cat > /etc/sudoers.d/developer-nginx << 'EOF'
# AI Agent (developer user) can manage nginx and hosting without password
developer ALL=(ALL) NOPASSWD: /usr/bin/nginx
developer ALL=(ALL) NOPASSWD: /usr/bin/systemctl reload nginx
developer ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx
developer ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop nginx
developer ALL=(ALL) NOPASSWD: /usr/bin/systemctl start nginx

# File operations for web hosting
developer ALL=(ALL) NOPASSWD: /bin/mkdir
developer ALL=(ALL) NOPASSWD: /bin/chmod
developer ALL=(ALL) NOPASSWD: /bin/chown
developer ALL=(ALL) NOPASSWD: /bin/cp
developer ALL=(ALL) NOPASSWD: /bin/mv
developer ALL=(ALL) NOPASSWD: /bin/rm
developer ALL=(ALL) NOPASSWD: /bin/cat
developer ALL=(ALL) NOPASSWD: /bin/echo
developer ALL=(ALL) NOPASSWD: /usr/bin/cp
developer ALL=(ALL) NOPASSWD: /usr/bin/mv
developer ALL=(ALL) NOPASSWD: /usr/bin/rm

# Editor permissions
developer ALL=(ALL) NOPASSWD: /usr/bin/vim
developer ALL=(ALL) NOPASSWD: /usr/bin/nano
developer ALL=(ALL) NOPASSWD: /bin/vi

# Services management
developer ALL=(ALL) NOPASSWD: /usr/bin/systemctl
developer ALL=(ALL) NOPASSWD: /bin/systemctl

# Any nginx-related operations
developer ALL=(ALL) NOPASSWD: /usr/sbin/nginx

# Mount and file system operations
developer ALL=(ALL) NOPASSWD: /bin/mount
developer ALL=(ALL) NOPASSWD: /bin/umount

# Network operations
developer ALL=(ALL) NOPASSWD: /usr/bin/curl
developer ALL=(ALL) NOPASSWD: /usr/bin/wget
developer ALL=(ALL) NOPASSWD: /bin/ip
developer ALL=(ALL) NOPASSWD: /sbin/ip

EOF

# Set proper permissions on sudoers file
chmod 0440 /etc/sudoers.d/developer-nginx

# Test sudo access
echo "✅ Testing sudo access for developer user..."
if sudo -u developer sudo -n whoami >/dev/null 2>&1; then
    echo "✅ Developer user has sudo access"
else
    echo "❌ Developer user still doesn't have sudo access"
    echo "   Trying to restart sudo service..."
    systemctl restart sudo || systemctl restart systemd-logind || true
fi

echo "🎉 AI agent sudo setup complete!"
echo ""
echo "The AI agent (developer user) can now:"
echo "  • Manage nginx configuration and service"
echo "  • Create and modify web hosting files"
echo "  • Set proper file permissions"
echo "  • Reload nginx after configuration changes"
echo "  • Perform all system operations needed for web hosting"
echo ""
echo "No password prompts will be required for these operations."