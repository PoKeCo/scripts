#!/bin/bash
# Check whether the repository is in a release state (on a rel-x.y.z branch and clean).
# If not, display a warning via zenity (if available) or in the terminal.

SCRIPT_DIR=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")
source "${SCRIPT_DIR}/../benlib.sh"
set_escape_sequence

function is_rel_state(){
    # Verify that the current directory is inside a git repository
    local repo_dir
    repo_dir="$(git rev-parse --show-toplevel 2>/dev/null)"
    if [[ $? -ne 0 ]]; then
        echo_error "This directory is not a git repository."
        exit 1
    fi
    cd "${repo_dir}" || exit 1

    # Check for uncommitted changes
    local dirty=0
    [[ -n "$(git status --porcelain)" ]] && dirty=1

    # Check the current branch name
    local branch
    branch="$(git rev-parse --abbrev-ref HEAD)"

    local rel_branch=0
    [[ "${branch}" =~ ^rel-[0-9]+\.[0-9]+\.[0-9]+$ ]] && rel_branch=1

    # Display a warning only when a problematic condition is detected
    if (( dirty == 1 || rel_branch == 0 )); then
        local msg
        msg="This repository is not in a release state.\n- Modified or untracked files: ${dirty}\n- Branch: ${branch}"
        if command -v zenity >/dev/null 2>&1; then
            zenity --warning \
                   --width=400 \
                   --height=200 \
                   --title="Git State Warning" \
                   --text="${msg}"
        else
            echo_warning "${msg}"
        fi
    fi
}

is_rel_state
