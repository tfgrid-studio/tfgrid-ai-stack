# Web Publishing Instructions

You are an AI agent helping to publish a project for web hosting on the TFGrid AI stack.

## Your Task

You will:
1. **Check the Git repository** for this project
2. **Analyze the project structure** to determine the optimal hosting format
3. **Publish the project** to web hosting

## Dynamic Deployment Information

- **GIT_BASE_URL**: The base URL where Gitea is deployed (dynamically determined)
- **WEB_BASE_URL**: The base URL where web hosting is available (same as GIT_BASE_URL)
- **Project Path**: The git path to this specific project
- **Full Git URL**: `${GIT_BASE_URL}/${PROJECT_PATH}`
- **Full Web URL**: `${WEB_BASE_URL}/web/${PROJECT_PATH}`

## Step 1: Check Git Repository

**Check the git repository for this project:**
```
curl "${GIT_BASE_URL}/${PROJECT_PATH}"
```

Analyze what you find to determine:
- **Project type** (website, ebook, documentation, data, code, etc.)
- **File structure** (HTML files, markdown, data files, etc.)
- **Dependencies** (if any)
- **Configuration files** (package.json, requirements.txt, etc.)

## Step 2: Determine Hosting Strategy

Based on your analysis, choose the best hosting approach:

### Website Projects
- **Files**: HTML, CSS, JS files
- **Strategy**: Serve as static website
- **Web URL**: `${WEB_BASE_URL}/web/${PROJECT_PATH}/`

### Documentation Projects  
- **Files**: Markdown files, README, docs/ folder
- **Strategy**: Convert to web documentation
- **Output**: HTML documentation site at `${WEB_BASE_URL}/web/${PROJECT_PATH}/`

### Data Projects
- **Files**: CSV, JSON, data files
- **Strategy**: Create data visualization
- **Output**: Interactive data explorer at `${WEB_BASE_URL}/web/${PROJECT_PATH}/`

### Ebook Projects
- **Files**: PDF, EPUB, markdown book files
- **Strategy**: Create web-based ebook reader
- **Output**: Web ebook at `${WEB_BASE_URL}/web/${PROJECT_PATH}/`

## Step 3: Publish to Web Hosting

1. **Get the project files** from the git repository
2. **Process/convert** as needed for web hosting
3. **Deploy to web hosting** at the correct path
4. **Set proper permissions** for web access
5. **Test the deployment** to ensure it works

## Important Requirements

### Organization Name
- **USE THE ACTUAL GIT ORGANIZATION** from the git URL
- Extract from the URL structure: `${GIT_BASE_URL}/ORG_NAME/PROJECT_NAME/`
- **DO NOT use "default"** - use the real organization name from git

### Web Hosting Setup
- The nginx is already configured to serve from `/web/`
- **DO NOT create individual nginx config files** 
- **Use the existing nginx configuration** that serves from the projects directory
- **Just ensure the project files are properly placed** in the correct directory structure

### Directory Structure
- Project should be accessible at: `${WEB_BASE_URL}/web/ORG_NAME/PROJECT_NAME/`
- The existing nginx already maps `/web/` to serve files from the projects directory
- **No need to modify nginx configs** - just ensure files are in the right place

### Permissions
- Ensure files have proper read permissions (644 for files, 755 for directories)
- The nginx user (www-data) needs to be able to read the files

## What TO Do
1. **Fetch project from git**: Download/clone from `${GIT_BASE_URL}/${PROJECT_PATH}`
2. **Analyze project type**: Determine if it's website, documentation, data, ebook, etc.
3. **Process for web**: Convert or prepare as needed for web hosting
4. **Place in hosting directory**: Put files in the correct web hosting path
5. **Set permissions**: Ensure nginx can serve the content
6. **Test web hosting**: Verify `${WEB_BASE_URL}/web/${PROJECT_PATH}/` is accessible
7. **Report success**: Provide both Git and Web URLs

## What NOT to Do
- **Do NOT create individual nginx config files**
- **Do NOT use "default" as organization** - extract from git URL
- **Do NOT overwrite existing nginx configuration**
- **Do NOT try to modify system nginx files**
- **Do NOT hardcode URLs** - use the dynamic deployment URLs
- **Do NOT break the `/git/` service** - ensure it continues working

## Success Criteria
- Project is accessible at `${WEB_BASE_URL}/web/REAL_ORG/PROJECT_NAME/`
- Gitea continues to work at `${GIT_BASE_URL}/`
- Files have proper permissions for web serving
- No conflicts with existing services
- Both Git and Web URLs work correctly

## Final URLs
- **Git URL**: `${GIT_BASE_URL}/${PROJECT_PATH}`
- **Web URL**: `${WEB_BASE_URL}/web/${PROJECT_PATH}/`