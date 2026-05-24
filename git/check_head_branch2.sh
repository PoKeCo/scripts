#!/bin/bash

function show_help(){
    echo "Usage: ${THIS_SCRIPT} [OPTION]"
    echo
    echo "Mandatory arguments to long options are mandatory for short options too."
    printf " %-20s %s\n" "--help" "Display this help and exit"
}

function get_branch_name(){
    local ret_val=0
    local branch_rel="" branch_dev="" branch_f=""
    local commit_id="$1"
    local branch_list
    branch_list=$(git branch -r --points-at "${commit_id}" | grep -v HEAD | sed 's%  origin/\(.*\)%\1%')
    while IFS= read -r branch_elem; do
        case "${branch_elem}" in
            rel-*) branch_rel="${branch_elem}"; break ;;
            dev-*) branch_dev="${branch_elem}" ;;
            f-*)   branch_f="${branch_elem}" ;;
        esac
    done <<< "${branch_list}"

    if   [[ -n "${branch_rel}" ]]; then branch="${branch_rel}"
    elif [[ -n "${branch_dev}" ]]; then branch="${branch_dev}"
    elif [[ -n "${branch_f}"   ]]; then branch="${branch_f}"
    else
        branch="detached_HEAD_${commit_id}"
        ret_val=1
    fi

    echo "${branch}"
    return "${ret_val}"
}

function run_core(){
    local target_commit_id="${commit_id#+}"
    local target_branch
    target_branch=$(get_branch_name "${target_commit_id}")

    local message=""
    if [[ "${commit_id:0:1}" == "+" ]]; then
        printf "${RED}"
        message=" : Different branch"
    else
        case "${target_branch}" in
            rel-*) printf "${CYAN}"    ;;
            dev-*) printf "${YELLOW}"  ;;
            f-*)   printf "${MAGENTA}" ;;  # 修正: MAZENDA → MAGENTA
            *)     printf "${RED}"     ;;
        esac
    fi

    local spaces
    spaces=$(printf '%*s' $((2 + stack_ptr * 2)) '')
    local dir_name
    dir_name=$(pwd | sed "s%${GIT_TOP_LEVEL}%%")
    printf "%-50s %s${message}${NORM}\n" "${spaces}${dir_name}" "${target_branch}"
}

## Prepare
SCRIPT_DIR=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")
THIS_SCRIPT=$(basename "${BASH_SOURCE[0]}")
source "${SCRIPT_DIR}/../benlib.sh"
set_escape_sequence

## Parse Argument
while (( "$#" > 0 )); do
    case "$1" in
        --help) show_help; exit 0 ;;
    esac
    shift
done

## Main
declare -a commit_ids stack_commit_ids subdirs stack_subdirs branches stack_branches stack_index

stack_ptr=0
index=-1

GIT_TOP_LEVEL=$(git rev-parse --show-toplevel)

branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "${branch}" =~ ^rel- ]]; then
    printf "${CYAN}"
else
    printf "${YELLOW}"
fi
printf "%-50s %s${NORM}\n" "${GIT_TOP_LEVEL}" "${branch}"

i=0
while read -r line; do
    read -ra line_sep <<< "${line}"
    commit_ids[$i]="${line_sep[0]}"
    subdirs[$i]="${line_sep[1]}"
    branches[$i]=$(sed 's/(\(.*\)\/\(.*\))/\2/' <<< "${line_sep[2]}")
    (( i++ ))
done <<< "$(git submodule)"
index=$((i - 1))

stack_commit_ids[$stack_ptr]="${commit_ids[*]}"
stack_subdirs[$stack_ptr]="${subdirs[*]}"
stack_branches[$stack_ptr]="${branches[*]}"
stack_index[$stack_ptr]="${index}"

while true; do
    read -ra commit_ids  <<< "${stack_commit_ids[$stack_ptr]}"
    read -ra subdirs     <<< "${stack_subdirs[$stack_ptr]}"
    read -ra branches    <<< "${stack_branches[$stack_ptr]}"
    index="${stack_index[$stack_ptr]}"

    if (( index >= 0 )); then
        commit_id="${commit_ids[$index]}"
        subdir="${subdirs[$index]}"
        branch="${branches[$index]}"
        index=$(( index - 1 ))
        stack_index[$stack_ptr]="${index}"
        #######################################
        pushd "${subdir}" > /dev/null
        run_core
        #######################################
        i=0
        while read -r line; do
            [[ -z "${line}" ]] && break
            read -ra line_sep <<< "${line}"
            commit_ids[$i]="${line_sep[0]}"
            subdirs[$i]="${line_sep[1]}"
            branches[$i]=$(sed 's/(\(.*\)\/\(.*\))/\2/' <<< "${line_sep[2]}")
            (( i++ ))
        done <<< "$(git submodule)"
        popd > /dev/null
        #######################################

        if (( i != 0 )); then
            stack_ptr=$(( stack_ptr + 1 ))
            index=$(( i - 1 ))
            stack_commit_ids[$stack_ptr]="${commit_ids[*]}"
            stack_subdirs[$stack_ptr]="${subdirs[*]}"
            stack_branches[$stack_ptr]="${branches[*]}"
            stack_index[$stack_ptr]="${index}"
            pushd "${subdir}" > /dev/null
        fi
    else
        stack_ptr=$(( stack_ptr - 1 ))
        if (( stack_ptr >= 0 )); then
            popd > /dev/null
        else
            break
        fi
    fi
done
