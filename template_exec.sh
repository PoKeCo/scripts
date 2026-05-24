#!/bin/bash
# Template for scripts using SSH execution and extended color utilities.
# Reference for ssh_exec / ssh_rsync / rexec / RGB / BK_RGB / LOCATE.
# Copy this file and edit it.

function usage(){
    echo "Usage: ${THIS_SCRIPT} [OPTION]"
    echo
    printf " %-20s %s\n" "-m <message>" "Show message"
    printf " %-20s %s\n" "--help"       "Display this help and exit"
}

function main(){
    SCRIPT_DIR=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")
    THIS_SCRIPT=$(basename "${BASH_SOURCE[0]}")
    source "${SCRIPT_DIR}/benlib.sh"
    set_escape_sequence

    message=""
    args=""

    while (( "$#" > 0 )); do
        case "$1" in
            -m)     shift; message="$1" ;;
            --help) usage; exit 0 ;;
            *)      args="${args} $1" ;;
        esac
        shift
    done

    # Color check (RGB / BK_RGB are defined in benlib.sh)
    echo "${CYAN}SCRIPT_DIR=${SCRIPT_DIR}${NORM}"
    echo "$(RGB 128 128 0)foreground RGB(128,128,0)${NORM}"
    echo "$(BK_RGB 128 0 128)background RGB(128,0,128)${NORM}"

    if [[ -n "${message}" ]]; then
        echo_info "message=${message}"
    fi
    echo_note "non-parsed argument(s)=${args}"
}

main "$@"
