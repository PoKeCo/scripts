#!/bin/bash

function show_help(){
    echo "Usage: ${THIS_SCRIPT} [OPTION]"
    echo
    echo "Mandatory arguments to long options are mandatory for short options too."
    printf " %-20s %s\n" "--help"       "Display this help and exit"
    printf " %-20s %s\n" "-t <tag>"     "Git tag name"
    printf " %-20s %s\n" "-m <message>" "Tag message"
}

function run_core(){
    echo "${subdir}"
    git tag "${GIT_TAG}" -m "'${GIT_MESSAGE}'"
    git push origin "${GIT_TAG}"
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
        -t)     shift; GIT_TAG="$1"     ;;
        -m)     shift; GIT_MESSAGE="$1" ;;
    esac
    shift
done

echo "${GIT_TAG} : ${GIT_MESSAGE}"

## Main
declare -a subdirs stack_subdirs branches stack_branches stack_index

stack_ptr=0
index=-1

GIT_TOP_LEVEL=$(git rev-parse --show-toplevel)

branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "${branch}" =~ ^rel- ]]; then
    printf "${CYAN}"
else
    printf "${YELLOW}"
fi
spaces=$(printf '%*s' $((2 + stack_ptr * 2)) '')
printf "%-50s %s${NORM}\n" "${GIT_TOP_LEVEL}" "${branch}"
subdir=""
run_core

i=0
while read -r line; do
    read -ra line_sep <<< "${line}"
    subdirs[$i]="${line_sep[1]}"
    branches[$i]=$(sed 's/(\(.*\)\/\(.*\))/\2/' <<< "${line_sep[2]}")
    (( i++ ))
done <<< "$(git submodule)"
index=$(( i - 1 ))

stack_subdirs[$stack_ptr]="${subdirs[*]}"
stack_branches[$stack_ptr]="${branches[*]}"
stack_index[$stack_ptr]="${index}"

while true; do
    read -ra subdirs  <<< "${stack_subdirs[$stack_ptr]}"
    read -ra branches <<< "${stack_branches[$stack_ptr]}"
    index="${stack_index[$stack_ptr]}"

    if (( index >= 0 )); then
        subdir="${subdirs[$index]}"
        branch="${branches[$index]}"
        index=$(( index - 1 ))
        stack_index[$stack_ptr]="${index}"
        #######################################
        pushd "${subdir}" > /dev/null
        if [[ "${branch}" =~ ^rel- ]]; then
            printf "${CYAN}"
        else
            printf "${YELLOW}"
        fi
        spaces=$(printf '%*s' $((2 + stack_ptr * 2)) '')
        dir_name=$(pwd | sed "s%${GIT_TOP_LEVEL}%%")
        printf "%-50s %s${NORM}\n" "${spaces}${dir_name}" "${branch}"
        run_core
        #######################################
        i=0
        while read -r line; do
            [[ -z "${line}" ]] && break
            read -ra line_sep <<< "${line}"
            subdirs[$i]="${line_sep[1]}"
            branches[$i]=$(sed 's/(\(.*\)\/\(.*\))/\2/' <<< "${line_sep[2]}")
            (( i++ ))
        done <<< "$(git submodule)"
        popd > /dev/null
        #######################################

        if (( i != 0 )); then
            stack_ptr=$(( stack_ptr + 1 ))
            index=$(( i - 1 ))
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
