#!/bin/bash
# Advanced AI Agent Loop Script with monitoring and control features

set -e

# Configuration
PROMPT_FILE="${PROMPT_FILE:-prompt.md}"
LOG_FILE="${LOG_FILE:-agent-output.log}"
ERROR_LOG="${ERROR_LOG:-agent-errors.log}"
AGENT_DIR="${AGENT_DIR:-.agent}"
MAX_ITERATIONS="${MAX_ITERATIONS:-0}"  # 0 means infinite
SLEEP_DELAY="${SLEEP_DELAY:-10}"
COMMIT_PREFIX="${COMMIT_PREFIX:-\"Agent: \"}"

# Create agent directory if it doesn't exist
mkdir -p $AGENT_DIR

# Initialize TODO tracking
TODO_FILE="$AGENT_DIR/TODO.md"
if [ ! -f $TODO_FILE ]; then
    echo "# AI Agent TODO List

## Status
- Running: Yes
- Last Action: Initialization
- Iteration: 0

## TODO
- [ ] Initial setup complete
- [ ] Begin main task

## Progress Log
- $(date): Started AI agent process

" > $TODO_FILE
fi

# Function to update iteration count
update_iteration() {
    iteration=$(grep "Iteration:" $TODO_FILE | cut -d':' -f2 | tr -d ' ')
    new_iteration=$((iteration + 1))
    sed -i "s/Iteration:.*/Iteration: $new_iteration/" $TODO_FILE
}

# Function to log progress
log_progress() {
    echo "- $(date): $1" >> $TODO_FILE
}

echo "Starting Advanced AI Agent Loop..."
echo "Prompt file: $PROMPT_FILE"
echo "Log file: $LOG_FILE"
echo "Error log: $ERROR_LOG"
echo "Agent directory: $AGENT_DIR"
echo "Max iterations: ${MAX_ITERATIONS:-infinite}"
echo "Sleep delay: ${SLEEP_DELAY}s"
echo "Starting at: $(date)"
echo "------------------------"

# Initialize iteration counter
update_iteration

# Main loop with iteration limits
cd "$(dirname "$0")" || exit 1
iteration_count=0
while true; do
    iteration_count=$((iteration_count + 1))
    
    # Log iteration start time for time tracking
    ITERATION_START=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$(date): Starting iteration $iteration_count" >> $LOG_FILE
    echo "$ITERATION_START" > "$AGENT_DIR/last_iteration_start.txt"
    
    # Check if we've reached max iterations
    if [ $MAX_ITERATIONS -gt 0 ] && [ $iteration_count -gt $MAX_ITERATIONS ]; then
        echo "$(date): Reached maximum iterations ($MAX_ITERATIONS), exiting loop" >> $LOG_FILE
        log_progress "Reached maximum iterations, stopping"
        break
    fi
    
    # Check for stop condition
    if [ -f "$AGENT_DIR/STOP" ] || [ -f "STOP" ]; then
        echo "$(date): Stop signal received, exiting loop" >> $LOG_FILE
        log_progress "Stop signal received, stopping"
        break
    fi
    
    # Update TODO status
    STATUS_MSG="Iteration $iteration_count - Running: $(date)"
    sed -i "s/Last Action:.*/Last Action: $STATUS_MSG/" $TODO_FILE
    
    # Run Qwen with the current prompt - allow all tools (yolo mode) with proper configuration
    # If time management instructions exist, prepend them to the prompt
    TIME_MGMT_FILE="$AGENT_DIR/time_management_instructions.md"
    QWEN_START_TIME=$(date)
    if [ -f "$TIME_MGMT_FILE" ]; then
        # Concatenate time management instructions with user prompt
        QWEN_RESULT=$(cat "$TIME_MGMT_FILE" $PROMPT_FILE | qwen --approval-mode yolo --sandbox false 2>>$ERROR_LOG >> $LOG_FILE; echo $?)
    else
        # No time management - just use prompt
        QWEN_RESULT=$(cat $PROMPT_FILE | qwen --approval-mode yolo --sandbox false 2>>$ERROR_LOG >> $LOG_FILE; echo $?)
    fi
    
    if [ "$QWEN_RESULT" -eq 0 ]; then
        # On success, commit changes
        git add .
        if git diff --cached --quiet; then
            echo "$(date): No changes to commit" >> $LOG_FILE
            log_progress "Iteration $iteration_count: No changes made"
        else
            COMMIT_MSG="${COMMIT_PREFIX}Iteration $iteration_count at $(date)"
            git commit -m "$COMMIT_MSG" >> $LOG_FILE 2>&1
            echo "$(date): Changes committed successfully" >> $LOG_FILE
            log_progress "Iteration $iteration_count: Changes committed"
        fi
    else
        # On error, log and continue
        echo "$(date): Qwen execution failed, continuing loop" >> $LOG_FILE
        echo "$(date): Error details logged to $ERROR_LOG" >> $LOG_FILE
        log_progress "Iteration $iteration_count: Qwen execution failed"
    fi
    
    # Update iteration counter in TODO
    update_iteration
    
    # Small delay to avoid overwhelming the API and allow system processing
    sleep $SLEEP_DELAY
    
    # Optional: Cleanup temporary files periodically
    if [ $((iteration_count % 10)) -eq 0 ]; then
        # Run any cleanup commands here if needed
        echo "$(date): Completed $iteration_count iterations, continuing..." >> $LOG_FILE
    fi
done

echo "Advanced AI agent loop stopped at: $(date)"
echo "$(date): Process completed after $iteration_count total iterations" >> $LOG_FILE