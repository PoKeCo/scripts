#!/bin/bash
# Basic template. Copy this file and edit it.

function usage(){
    echo "Usage: ${THIS_SCRIPT} [OPTION]"
    echo
    echo "Mandatory arguments to long options are mandatory for short options too."
    printf " %-20s %s\n" "--help" "Display this help and exit"
}

function main(){
    SCRIPT_DIR=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")
    THIS_SCRIPT=$(basename "${BASH_SOURCE[0]}")

    # Adjust the path to benlib.sh based on where this script is placed:
    #   same directory : "${SCRIPT_DIR}/benlib.sh"
    #   one level down : "${SCRIPT_DIR}/../benlib.sh"
    source "${SCRIPT_DIR}/benlib.sh"
    set_escape_sequence

    # Default values
    args=""

    # Option parsing
    while (( "$#" > 0 )); do
        case "$1" in
            --help) usage; exit 0 ;;
            *)      args="${args} $1" ;;
        esac
        shift
    done

    echo_note "non-parsed argument(s)=${args}"
}

main "$@"
