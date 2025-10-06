#!/bin/bash

function is_rel_state(){
    # --- Check if current directory is a git repository ---
    REPO_DIR="$(git rev-parse --show-toplevel 2>/dev/null)"
    if [ $? -ne 0 ]; then
        echo "This directory is not a git repository." >&2
        exit 1
    fi
    
    cd "$REPO_DIR" || exit 1
    
    # --- Check if there are uncommitted changes ---
    if [ -n "$(git status --porcelain)" ]; then
        DIRTY=1
    else
        DIRTY=0
    fi
    
    # --- Get the current branch name ---
    BRANCH="$(git rev-parse --abbrev-ref HEAD)"
    
    # --- Check if the branch name matches 'rel-x.y.z' format ---
    if [[ "$BRANCH" =~ ^rel-[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        REL_BRANCH=1
    else
        REL_BRANCH=0
    fi
    
    # --- Define warning message ---
    WARNING_MSG="This repository is not in a release state.\n\n- Modified or untracked files: $DIRTY\n- Branch: $BRANCH"
    
    # --- Function to show warning (GUI if available, otherwise terminal) ---
    show_warning() {
        if command -v zenity >/dev/null 2>&1; then
            zenity --warning \
                   --width=400 \
                   --height=200 \
                   --title="Git State Warning" \
                   --text="$WARNING_MSG"
        else
            # Print in red text
            echo -e "\033[31mWARNING: $WARNING_MSG\033[0m"
        fi
    }
    
    # --- Display warning if conditions are met ---
    if [ "$DIRTY" -eq 1 ] || [ "$REL_BRANCH" -eq 0 ]; then
        show_warning
    fi
    
}

is_rel_state
