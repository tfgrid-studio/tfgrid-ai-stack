# Web Publishing Instructions

You are an AI agent helping to publish a project for web hosting on the TFGrid AI stack.

## 🔧 MASTER NGINX PUBLISHING KNOWLEDGE (Critical - Read First!)

**BEFORE analyzing any project, understand this nginx setup completely - it applies to ALL project types:**

### Core Nginx Architecture (Universal):
- **URL → Path Mapping**: `${WEB_BASE_URL}/web/{ORG}/{PROJECT}/` → `/home/developer/code/tfgrid-ai-stack-projects/{ORG}/{PROJECT}/src/`
- **Web Root Directory**: `/home/developer/code/tfgrid-ai-stack-projects/`
- **Project Structure**: `{ORG}/{PROJECT}/src/` (source) → `{ORG}/{PROJECT}/` (web served)
- **Nginx Config**: `location /web/ { root /home/developer/code/tfgrid-ai-stack-projects; autoindex on; try_files $uri $uri/ =404; }`
- **Permissions**: Files 644, Directories 755, Owner www-data:www-data

### Universal Publishing Commands (All Project Types):
```bash
# Create web directory structure
mkdir -p /home/developer/code/tfgrid-ai-stack-projects/{ORG}/{PROJECT}/src/

# Copy project files with permissions
cp -r {PROJECT_PATH}/src/* /home/developer/code/tfgrid-ai-stack-projects/{ORG}/{PROJECT}/src/ 2>/dev/null || true

# Set correct permissions for nginx
chmod -R 644 /home/developer/code/tfgrid-ai-stack-projects/{ORG}/{PROJECT}/src/ 2>/dev/null || true
chmod -R 755 /home/developer/code/tfgrid-ai-stack-projects/{ORG}/{PROJECT}/ 2>/dev/null || true

# Set nginx ownership
chown -R www-data:www-data /home/developer/code/tfgrid-ai-stack-projects/{ORG}/{PROJECT}/ 2>/dev/null || true
```

## Project-Type-Specific Publishing Strategies

### 📄 Website Projects (HTML, CSS, JS):
**Expected Structure**: `src/index.html`, `src/css/`, `src/js/`, `src/assets/`
**Publishing Action**: Copy entire src/ contents to web directory
**Access Pattern**: `${WEB_BASE_URL}/web/{ORG}/{PROJECT}/` shows index.html
**Special Notes**: Ensure index.html exists, serve static assets

### 📊 Data Projects (CSV, JSON, datasets):
**Expected Structure**: `src/data/`, `src/datasets/`, various data files
**Publishing Action**: Copy all data files, enable directory browsing
**Access Pattern**: `${WEB_BASE_URL}/web/{ORG}/{PROJECT}/data/` lists files
**Special Notes**: Use autoindex for data exploration, no index.html needed

### 📖 Ebook Projects (PDF, EPUB files):
**Expected Structure**: `src/book.pdf`, `src/ebook.epub`, documentation files
**Publishing Action**: Copy document files directly
**Access Pattern**: `${WEB_BASE_URL}/web/{ORG}/{PROJECT}/book.pdf`
**Special Notes**: Set appropriate MIME types, enable direct downloads

### 🔧 API Projects (Node.js, Python backends):
**Expected Structure**: `src/app.js`, `src/server.py`, `src/requirements.txt`, `src/package.json`
**Publishing Action**: Copy source code, assess build/deployment needs
**Access Pattern**: May require additional proxy configuration beyond static serving
**Special Notes**: Source code access for development, not runtime API

### 🎯 Adaptive Publishing (Any Structure):
**If expected patterns don't match, adapt:**
- Scan entire src/ directory for web-serveable content
- Copy all HTML, CSS, JS, data, and document files
- Use autoindex for directory navigation if no clear entry point
- Apply universal permissions and ownership
- Test accessibility and adjust as needed

## Universal Publishing Steps (All Types):
1. **Create web directory**: `mkdir -p` structure
2. **Copy content**: `cp -r` with appropriate filtering
3. **Apply permissions**: 644 files, 755 directories, www-data ownership
4. **Test access**: Verify URL accessibility
5. **Adjust as needed**: Add missing files, fix permissions, optimize structure

## Your Task

You will:
1. **Check the Git repository** for this project (if needed for fresh analysis)
2. **Analyze the project structure** to determine the optimal hosting format
3. **Execute publishing** using the nginx knowledge above
4. **Verify accessibility** at the web URL

## Dynamic Deployment Information

- **GIT_BASE_URL**: The base URL where Gitea is deployed (dynamically determined)
- **WEB_BASE_URL**: The base URL where web hosting is available (same as GIT_BASE_URL)
- **Project Path**: The git path to this specific project
- **Full Git URL**: `${GIT_BASE_URL}/{ORG}/{PROJECT}`
- **Full Web URL**: `${WEB_BASE_URL}/web/{ORG}/{PROJECT}/`

## Intelligent Analysis (Use Cache When Available)

If project metadata is cached, use it to guide analysis and publishing.
If no cache exists, perform full analysis using the nginx knowledge above.
Always adapt to the actual project structure found, even if it differs from expectations.

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
