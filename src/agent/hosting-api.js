#!/usr/bin/env node
/**
 * TFGrid AI Stack Hosting API
 * Handles project hosting requests and serves web applications
 * 
 * Integrates with nginx routing for:
 * - /web/org/repo-name/* → Serve web applications
 * - /web/org/repo-name/static/* → Serve static assets
 */

const express = require('express');
const path = require('path');
const fs = require('fs');
const { exec } = require('child_process');
const util = require('util');

const execPromise = util.promisify(exec);

class HostingAPI {
    constructor() {
        this.app = express();
        this.port = process.env.HOSTING_API_PORT || 8081;
        this.projectsDir = process.env.PROJECT_WORKSPACE || '/home/developer/code/tfgrid-ai-stack-projects';
        this.projectHostingDir = '/etc/tfgrid-ai-stack/projects';
        
        this.setupMiddleware();
        this.setupRoutes();
    }

    setupMiddleware() {
        // Enable CORS for development
        this.app.use(express.json());
        this.app.use(express.urlencoded({ extended: true }));
        
        // Log all requests
        this.app.use((req, res, next) => {
            console.log(`${new Date().toISOString()} ${req.method} ${req.url}`);
            next();
        });
    }

    setupRoutes() {
        // Health check endpoint
        this.app.get('/health', (req, res) => {
            res.json({ 
                status: 'healthy', 
                service: 'hosting-api',
                timestamp: new Date().toISOString()
            });
        });

        // Check if a project supports hosting
        this.app.get('/api/project/:org/:name/hosting', async (req, res) => {
            try {
                const { org, name } = req.params;
                const result = await this.checkProjectHosting(org, name);
                res.json(result);
            } catch (error) {
                console.error('Error checking hosting:', error);
                res.status(500).json({ error: 'Internal server error' });
            }
        });

        // Serve static assets for hosted projects
        this.app.get('/api/project/:org/:name/static/*', async (req, res) => {
            try {
                const { org, name } = req.params;
                const assetPath = req.params[0];
                const result = await this.serveStaticAsset(org, name, assetPath);
                res.send(result);
            } catch (error) {
                console.error('Error serving static asset:', error);
                res.status(404).send('Asset not found');
            }
        });

        // Get list of all hosted projects
        this.app.get('/api/projects/list', async (req, res) => {
            try {
                const projects = await this.getHostedProjects();
                res.json({ projects });
            } catch (error) {
                console.error('Error listing projects:', error);
                res.status(500).json({ error: 'Internal server error' });
            }
        });

        // Get hosting status for a project
        this.app.get('/api/project/:org/:name/status', async (req, res) => {
            try {
                const { org, name } = req.params;
                const status = await this.getProjectStatus(org, name);
                res.json(status);
            } catch (error) {
                console.error('Error getting project status:', error);
                res.status(500).json({ error: 'Internal server error' });
            }
        });
    }

    /**
     * Check if a project supports hosting
     */
    async checkProjectHosting(org, name) {
        const projectPath = this.getProjectPath(org, name);
        
        if (!fs.existsSync(projectPath)) {
            return { 
                hostable: false, 
                error: 'Project not found',
                message: `Project ${org}/${name} does not exist`
            };
        }

        // Check if project has hosting configuration
        const hostingConfig = `${this.projectHostingDir}/${org}-${name}.conf`;
        if (!fs.existsSync(hostingConfig)) {
            return { 
                hostable: false, 
                error: 'Not hosted',
                message: 'Project exists but is not configured for hosting',
                suggestion: 'Run: t publish ' + name
            };
        }

        // Detect project type
        const projectType = this.detectProjectType(projectPath);
        
        return {
            hostable: true,
            projectType,
            projectPath,
            org,
            name,
            message: `Project ${org}/${name} is available for hosting`
        };
    }

    /**
     * Serve static assets for hosted projects
     */
    async serveStaticAsset(org, name, assetPath) {
        const projectPath = this.getProjectPath(org, name);
        
        // Check if project is actually hosted
        const hostingConfig = `${this.projectHostingDir}/${org}-${name}.conf`;
        if (!fs.existsSync(hostingConfig)) {
            throw new Error('Project not hosted');
        }

        // Determine the base path for static files based on project type
        const projectType = this.detectProjectType(projectPath);
        let staticBasePath;

        switch (projectType) {
            case 'react':
            case 'vue':
            case 'nextjs':
            case 'nuxt':
                staticBasePath = path.join(projectPath, 'dist');
                if (!fs.existsSync(staticBasePath)) {
                    staticBasePath = path.join(projectPath, 'build');
                }
                break;
            case 'static':
            case 'built-static':
                staticBasePath = projectPath;
                break;
            default:
                staticBasePath = projectPath;
        }

        const assetFullPath = path.join(staticBasePath, assetPath);
        
        if (!fs.existsSync(assetFullPath)) {
            throw new Error(`Asset not found: ${assetPath}`);
        }

        return fs.readFileSync(assetFullPath);
    }

    /**
     * Get list of all hosted projects
     */
    async getHostedProjects() {
        const projects = [];
        
        if (!fs.existsSync(this.projectHostingDir)) {
            return projects;
        }

        const configFiles = fs.readdirSync(this.projectHostingDir)
            .filter(file => file.endsWith('.conf'));

        for (const configFile of configFiles) {
            try {
                const [orgName] = configFile.split('-');
                const name = configFile.replace('.conf', '').replace(`${orgName}-`, '');
                const projectPath = this.getProjectPath(orgName, name);
                
                if (fs.existsSync(projectPath)) {
                    const projectType = this.detectProjectType(projectPath);
                    const stat = fs.statSync(projectPath);
                    
                    projects.push({
                        org: orgName,
                        name,
                        type: projectType,
                        path: projectPath,
                        hosted: true,
                        lastModified: stat.mtime
                    });
                }
            } catch (error) {
                console.warn(`Error processing config ${configFile}:`, error);
            }
        }

        return projects;
    }

    /**
     * Get detailed status for a project
     */
    async getProjectStatus(org, name) {
        const projectPath = this.getProjectPath(org, name);
        
        if (!fs.existsSync(projectPath)) {
            return { error: 'Project not found' };
        }

        const hostingConfig = `${this.projectHostingDir}/${org}-${name}.conf`;
        const isHosted = fs.existsSync(hostingConfig);
        const projectType = this.detectProjectType(projectPath);
        
        let buildStatus = 'unknown';
        let publishedAt = null;
        
        if (isHosted) {
            // Try to get build status
            const buildStatusFile = path.join(projectPath, '.hosting', 'build-status');
            if (fs.existsSync(buildStatusFile)) {
                buildStatus = fs.readFileSync(buildStatusFile, 'utf8').trim();
            }
            
            // Try to get publish time
            const publishTimeFile = path.join(projectPath, '.hosting', 'published-at');
            if (fs.existsSync(publishTimeFile)) {
                publishedAt = fs.readFileSync(publishTimeFile, 'utf8').trim();
            }
        }

        return {
            org,
            name,
            path: projectPath,
            type: projectType,
            hosted: isHosted,
            buildStatus,
            publishedAt,
            urls: {
                git: `http://localhost/git/${org}/${name}`,
                web: `http://localhost/web/${org}/${name}`
            }
        };
    }

    /**
     * Get project path for org/name
     */
    getProjectPath(org, name) {
        // Search in the projects directory
        const searchPath = path.join(this.projectsDir, name);
        
        if (fs.existsSync(searchPath)) {
            return searchPath;
        }
        
        // Fallback: search in workspace
        const workspacePath = path.join(process.env.PROJECT_WORKSPACE || '/home/developer/code', name);
        if (fs.existsSync(workspacePath)) {
            return workspacePath;
        }
        
        return null;
    }

    /**
     * Detect project type
     */
    detectProjectType(projectPath) {
        if (!fs.existsSync(projectPath)) {
            return 'unknown';
        }

        // Check for package.json
        const packageJsonPath = path.join(projectPath, 'package.json');
        if (fs.existsSync(packageJsonPath)) {
            try {
                const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
                const deps = { ...packageJson.dependencies, ...packageJson.devDependencies };

                // Check for specific frameworks
                if (deps.react || deps['react-dom'] || deps['react-router']) {
                    return 'react';
                }
                if (deps.vue || deps['@vue'] || deps.nuxt) {
                    return 'vue';
                }
                if (deps.next) {
                    return 'nextjs';
                }
                if (deps.nuxt) {
                    return 'nuxt';
                }
                if (deps.express) {
                    return 'api';
                }

                // Check if it's buildable
                if (packageJson.scripts && packageJson.scripts.build) {
                    return 'buildable';
                }
            } catch (error) {
                console.warn('Error parsing package.json:', error);
            }
        }

        // Check for static files
        if (fs.existsSync(path.join(projectPath, 'index.html')) ||
            fs.existsSync(path.join(projectPath, 'public', 'index.html'))) {
            return 'static';
        }

        // Check for built dist/build directories
        if (fs.existsSync(path.join(projectPath, 'dist')) ||
            fs.existsSync(path.join(projectPath, 'build'))) {
            return 'built-static';
        }

        // Check for Vue files
        const vueFiles = fs.readdirSync(projectPath)
            .filter(file => file.endsWith('.vue'));
        if (vueFiles.length > 0) {
            return 'vue';
        }

        return 'unknown';
    }

    /**
     * Start the API server
     */
    start() {
        this.app.listen(this.port, () => {
            console.log(`🚀 TFGrid AI Stack Hosting API running on port ${this.port}`);
            console.log(`📁 Projects directory: ${this.projectsDir}`);
            console.log(`⚙️  Hosting config directory: ${this.projectHostingDir}`);
        });
    }
}

// Start the server if this file is run directly
if (require.main === module) {
    const api = new HostingAPI();
    api.start();
}

module.exports = HostingAPI;