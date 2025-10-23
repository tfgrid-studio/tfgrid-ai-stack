#!/bin/bash
# summary-project.sh - Show project summary
# Part of the AI-Agent framework

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-project.sh"

PROJECT_NAME="$1"

if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: $0 <project-name>"
    exit 1
fi

# Find project in workspace
PROJECT_PATH=$(find_project_path "$PROJECT_NAME")

if [ -z "$PROJECT_PATH" ]; then
    echo "❌ Error: Project '$PROJECT_NAME' not found"
    echo ""
    echo "Available projects:"
    list_projects_brief
    exit 1
fi

cd "$PROJECT_PATH"

echo "📊 Project Summary: $PROJECT_NAME"
echo "═════════════════════════════════════════════════════════════"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Status
PROJECT_PID=$(pgrep -f "agent-loop.sh.*$PROJECT_NAME" 2>/dev/null || echo "")
if [ -n "$PROJECT_PID" ]; then
    STATUS="🟢 Running (PID: $PROJECT_PID)"
else
    STATUS="⭕ Stopped"
fi
echo "Status: $STATUS"

# Version and time constraint
if [ -f ".agent/time_log.txt" ]; then
    VERSION=$(grep "Project Version:" .agent/time_log.txt 2>/dev/null | cut -d':' -f2 | tr -d ' ')
    [ -z "$VERSION" ] && VERSION="1"
    TIME_CONSTRAINT=$(grep "Time Constraint:" .agent/time_log.txt 2>/dev/null | cut -d':' -f2- | xargs)
    [ -z "$TIME_CONSTRAINT" ] && TIME_CONSTRAINT="indefinite"
    START_TIME=$(grep "Project Start Time:" .agent/time_log.txt 2>/dev/null | cut -d':' -f2- | xargs)
    
    echo "Version: $VERSION"
    echo "Time Constraint: $TIME_CONSTRAINT"
    echo "Started: $START_TIME"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Git statistics
if [ -d ".git" ]; then
    TOTAL_COMMITS=$(git rev-list --count HEAD 2>/dev/null || echo "0")
    LAST_COMMIT=$(git log -1 --format="%cr" 2>/dev/null || echo "no commits")
    FIRST_COMMIT=$(git log --reverse --format="%cr" 2>/dev/null | head -1 || echo "unknown")
    
    echo "📦 Git Statistics"
    echo "─────────────────"
    echo "  Total commits: $TOTAL_COMMITS"
    echo "  First commit: $FIRST_COMMIT"
    echo "  Last commit: $LAST_COMMIT"
    
    # File statistics (excluding .agent, .git, logs)
    FILES_CREATED=$(git ls-files | grep -v "^\.agent/" | grep -v "^\.git/" | grep -v "\.log$" | wc -l)
    echo "  Tracked files: $FILES_CREATED"
    
    # Lines changed (from first commit to HEAD)
    if [ "$TOTAL_COMMITS" -gt 1 ]; then
        FIRST_COMMIT_HASH=$(git rev-list --max-parents=0 HEAD)
        STATS=$(git diff --shortstat "$FIRST_COMMIT_HASH" HEAD -- . ':(exclude).agent' ':(exclude)*.log' 2>/dev/null || echo "")
        if [ -n "$STATS" ]; then
            echo "  Changes: $STATS"
        fi
    fi
    
    echo ""
fi

# Edit history
if [ -f ".agent/edit_history.log" ]; then
    EDIT_COUNT=$(grep -c "^Edit Version:" .agent/edit_history.log || echo "0")
    if [ "$EDIT_COUNT" -gt 0 ]; then
        echo "✏️  Edit History"
        echo "─────────────────"
        echo "  Total edits: $EDIT_COUNT"
        echo ""
        echo "  Recent edits:"
        grep -A 5 "^Edit Version:" .agent/edit_history.log | tail -20 | sed 's/^/  /'
        echo ""
    fi
fi

# Final summary if exists
if [ -f ".agent/final_summary.md" ]; then
    echo "📝 Final Summary"
    echo "─────────────────"
    cat .agent/final_summary.md | sed 's/^/  /'
    echo ""
fi

# Current TODO
if [ -f ".agent/TODO.md" ]; then
    echo "📋 Current TODO"
    echo "─────────────────"
    head -20 .agent/TODO.md | sed 's/^/  /'
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Quick Actions:"
echo "   View logs:    make logs"
echo "   Edit config:  make edit"
if [ -n "$PROJECT_PID" ]; then
    echo "   Stop:         make stop"
else
    echo "   Start:        make run"
fi
