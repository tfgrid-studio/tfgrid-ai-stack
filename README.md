# TFGrid AI Stack

AI-powered development platform with integrated Git hosting and deployment.

## Quick Start

Deploy the complete AI development environment:

```bash
tfgrid-compose up tfgrid-ai-stack
```

This deploys a 3-VM architecture:
- **Gateway VM**: Public API gateway with nginx and monitoring
- **AI Agent VM**: Project creation and management APIs
- **Gitea VM**: Git repository hosting

## Features

- 🤖 **AI-Powered Development**: Create projects with AI assistance
- 📦 **Integrated Git Hosting**: Built-in Gitea for version control
- 🌐 **Public Deployment**: Automatic web deployment with SSL
- 📊 **Monitoring**: Prometheus + Grafana dashboards
- 🔒 **Secure Networking**: WireGuard VPN for inter-VM communication
- ⚡ **One-Click Deployment**: Single command setup

## Architecture

```
Internet
    ↓
[Gateway VM] ← nginx, APIs, monitoring
    ↓ (WireGuard VPN)
[AI Agent VM] ← project creation, code generation
    ↓
[Gitea VM] ← Git repositories, web interface
```

## Usage

### Deploy
```bash
tfgrid-compose up tfgrid-ai-stack
```

### Create a Project
```bash
tfgrid-compose exec tfgrid-ai-stack create "portfolio website"
```

### List Projects
```bash
tfgrid-compose exec tfgrid-ai-stack projects
```

### Access Services
```bash
# Get deployment URLs
tfgrid-compose address tfgrid-ai-stack

# SSH into VMs
tfgrid-compose ssh tfgrid-ai-stack
```

## Requirements

- ThreeFold Grid account with sufficient TFT
- tfgrid-compose CLI installed
- SSH key configured

## Resources

- **CPU**: 8 cores total
- **Memory**: 16GB total
- **Disk**: 200GB total
- **Cost**: ~$15-20/month (varies by node pricing)

## Documentation

- [Pattern Documentation](https://docs.tfgrid.studio/patterns/tfgrid-ai-stack)
- [API Reference](https://docs.tfgrid.studio/patterns/tfgrid-ai-stack/api)
- [Troubleshooting](https://docs.tfgrid.studio/patterns/tfgrid-ai-stack/troubleshooting)

## Support

This is an official TFGrid Studio application. For support:
- Documentation: https://docs.tfgrid.studio
- Issues: https://github.com/tfgrid-studio/tfgrid-compose/issues