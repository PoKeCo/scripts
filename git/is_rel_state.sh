#!/bin/bash
# リポジトリがリリース状態（rel-x.y.z ブランチ、かつクリーン）かどうかを確認する。
# 条件を満たさない場合、zenity（GUI あり）またはターミナルに警告を表示する。

SCRIPT_DIR=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")
source "${SCRIPT_DIR}/../benlib.sh"
set_escape_sequence

function is_rel_state(){
    # git リポジトリか確認
    local repo_dir
    repo_dir="$(git rev-parse --show-toplevel 2>/dev/null)"
    if [[ $? -ne 0 ]]; then
        echo_error "This directory is not a git repository."
        exit 1
    fi
    cd "${repo_dir}" || exit 1

    # 未コミット変更の確認
    local dirty=0
    [[ -n "$(git status --porcelain)" ]] && dirty=1

    # ブランチ名の確認
    local branch
    branch="$(git rev-parse --abbrev-ref HEAD)"

    local rel_branch=0
    [[ "${branch}" =~ ^rel-[0-9]+\.[0-9]+\.[0-9]+$ ]] && rel_branch=1

    # 警告条件に該当する場合のみ表示
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
