# Web Publishing Instructions

You are an AI agent helping to publish a project for web hosting on the TFGrid AI stack.

## Your Task

1. **Analyze the project structure** - understand what type of content this is
2. **Set up web hosting** - ensure the project is accessible via nginx
3. **Verify the deployment** - confirm the web server is working

## Important Requirements

### Organization Name
- **USE THE ACTUAL GIT ORGANIZATION** from the git config
- Get the organization from: `git config --get remote.origin.url`
- For example, if git remote shows `tfgrid-ai-agent/mathweb`, use organization `tfgrid-ai-agent`
- **DO NOT use "default"** - use the real organization name

### Web Hosting Setup
- The nginx is already configured to serve from `/web/`
- **DO NOT create individual nginx config files** 
- The existing nginx configuration serves from: `/home/developer/code/tfgrid-ai-stack-projects/`
- **Just ensure the project files are properly placed** in the correct directory structure

### Directory Structure
- Project should be accessible at: `http://SERVER_IP/web/ORGANIZATION/PROJECT_NAME/`
- The existing nginx already maps `/web/` to serve files from the projects directory
- **No need to modify nginx configs** - just ensure files are in the right place

### Permissions
- Ensure files have proper read permissions (644 for files, 755 for directories)
- The nginx user (www-data) needs to be able to read the files

## What TO Do
1. Check git config to get the actual organization name
2. Ensure project files are in `/home/developer/code/tfgrid-ai-stack-projects/ORGANIZATION/PROJECT_NAME/src/`
3. Set proper permissions so nginx can serve the content
4. Test the web hosting by making a curl request
5. Report success with the actual URLs

## What NOT to Do
- Do NOT create individual nginx config files
- Do NOT use "default" as organization - use real git org name
- Do NOT overwrite existing nginx configuration
- Do NOT try to modify system nginx files

## Success Criteria
- Project is accessible at `http://SERVER_IP/web/REAL_ORG/PROJECT_NAME/`
- Gitea continues to work at `http://SERVER_IP/git/`
- Files have proper permissions for web serving
- No conflicts with existing services