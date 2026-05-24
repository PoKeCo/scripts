#!/bin/bash
# =============================================================================
# benlib.sh — Shared library for shell scripts
#
# Usage in your script:
#   SCRIPT_DIR=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")
#   source "${SCRIPT_DIR}/benlib.sh"       # when benlib.sh is in the same directory
#   source "${SCRIPT_DIR}/../benlib.sh"    # when the script is one level below
#   set_escape_sequence
# =============================================================================

# =============================================================================
# Section 1: Terminal Color / Cursor Control
# =============================================================================

function set_escape_sequence(){
    # Foreground colors
    BLACK=$(printf "\e[30m")
    RED=$(printf "\e[31m")
    GREEN=$(printf "\e[32m")
    YELLOW=$(printf "\e[33m")
    BLUE=$(printf "\e[34m")
    MAGENTA=$(printf "\e[35m")
    CYAN=$(printf "\e[36m")
    WHITE=$(printf "\e[37m")
    GRAY=$(printf "\e[38;2;128;128;128m")
    DGRAY=$(printf "\e[38;2;64;64;64m")

    # Background colors
    BK_BLACK=$(printf "\e[40m")
    BK_RED=$(printf "\e[41m")
    BK_GREEN=$(printf "\e[42m")
    BK_YELLOW=$(printf "\e[43m")
    BK_BLUE=$(printf "\e[44m")
    BK_MAGENTA=$(printf "\e[45m")
    BK_CYAN=$(printf "\e[46m")
    BK_WHITE=$(printf "\e[47m")
    BK_GRAY=$(printf "\e[48;2;128;128;128m")
    BK_DGRAY=$(printf "\e[48;2;64;64;64m")

    NORM=$(printf "\e[0m")          # Reset to default
    CLS=$(printf "\e[2J")           # Clear screen
    CLL=$(printf "\e[2K")           # Clear line
    LOCATE_0_0=$(printf "\e[0;0H")  # Move cursor to top-left

    # Pass -v to print color swatches
    if [[ "${1:-}" == "-v" ]]; then
        for _c in BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE GRAY DGRAY NORM; do
            echo -e "${!_c} ${_c} ${NORM}"
        done
    fi
}

function RGB(){
    # Arbitrary foreground color  Usage: $(RGB <R> <G> <B>)
    printf "\e[38;2;%d;%d;%dm" "$1" "$2" "$3"
}

function BK_RGB(){
    # Arbitrary background color  Usage: $(BK_RGB <R> <G> <B>)
    printf "\e[48;2;%d;%d;%dm" "$1" "$2" "$3"
}

function LOCATE(){
    # Move cursor  Usage: $(LOCATE <ROW> <COL>)
    printf "\e[%d;%dH" "$1" "$2"
}

# =============================================================================
# Section 2: Logging
# =============================================================================

function echo_note(){
    echo "${GRAY}[NOTE]: $*${NORM}"
}

function echo_info(){
    echo "${CYAN}[INFO]: $*${NORM}"
}

function echo_warning(){
    echo "${YELLOW}[WARNING]: $*${NORM}"
}

function echo_error(){
    echo "${RED}[ERROR]: $*${NORM}" >&2
}

function show_var(){
    # Print "NAME=value" for debugging  Usage: show_var VAR_NAME
    echo "$1=${!1}"
}

# =============================================================================
# Section 3: Error Handling
# =============================================================================

function enable_strict_mode(){
    # Call at the top of main() to immediately catch unbound variables and
    # command failures.
    #
    # Notes:
    #   - Avoid using this when intentional failures are expected in
    #     if/while conditions.
    #   - set -u causes an error on unbound variable references.
    #     Use ${VAR:-default} for safe access.
    set -euo pipefail
    trap '_benlib_err_handler ${LINENO} "${BASH_COMMAND}" $?' ERR
}

function _benlib_err_handler(){
    echo_error "line $1: '$2' failed (exit $3)"
}

# =============================================================================
# Section 4: SSH / Remote Execution Utilities
# =============================================================================

function uuid_gen(){
    cat /proc/sys/kernel/random/uuid
}

function is_number(){
    # Returns 0 if the value is numeric, 1 otherwise  Usage: is_number <value>
    [[ "$1" =~ ^-?[0-9]+([.][0-9]+)?$ ]]
}

function prepare_ssh(){
    # Remove stale known_hosts entry before connecting  Usage: prepare_ssh <ADDR>
    ssh-keygen -f "/home/${USER}/.ssh/known_hosts" -R "$1" 2>/dev/null || true
}

function ssh_exec(){
    # Execute a command on a remote host and display output in the current terminal
    # Usage: ssh_exec <ADDR> <USR> <PASS> <COMMAND>
    local addr="$1" usr="$2" pass="$3" command="$4"
    echo "${GREEN}${usr}@${addr}: ${CYAN}${command}${NORM}"
    sshpass -p "${pass}" ssh -o "StrictHostKeyChecking=no" -t "${usr}@${addr}" -- "${command}"
}

function ssh_rsync(){
    # Sync files over SSH  Usage: ssh_rsync <PASS> <SRC> <DST>
    sshpass -p "$1" rsync -e "ssh -o StrictHostKeyChecking=no" -avzP "$2" "$3"
}

function rexec(){
    # Execute a command on a remote host via SSH.
    # Credentials missing from ADDR@USR@PASS are prompted interactively.
    # Usage: rexec <ADDR[@USR[@PASS]]> <COMMAND>
    local addr_usr_pass="$1" command="$2"
    local addr="" usr="" pass=""
    IFS="@" read -r addr usr pass <<< "${addr_usr_pass}"
    [[ -z "${addr}" ]] && read -r -p "${GREEN}target address:${NORM} " addr
    [[ -z "${usr}"  ]] && read -r -p "${GREEN}${addr}'s user:${NORM} " usr
    if [[ -z "${pass}" ]]; then
        read -r -s -p "${GREEN}${usr}@${addr}'s password:${NORM} " pass
        echo
    fi
    echo "${GREEN}${usr}@${addr}: ${CYAN}${command}${NORM}"
    sshpass -p "${pass}" ssh -n -o "StrictHostKeyChecking=no" -t "${usr}@${addr}" -- "${command}" 2>/dev/null
}

function lexec(){
    # Run a command locally in the current shell (no gnome-terminal tab).
    # Sets global RETURN_VALUE_FILE to the file where the exit code is written.
    # Usage: lexec <WAIT_OPT> <COMMAND>
    local wait_opt="$1" command="$2"
    local id; id=$(uuid_gen)
    RETURN_VALUE_FILE="/tmp/benlib_return_${id}"
    local wait_icon=""
    [[ "${wait_opt}" == "w" ]] && wait_icon="(w)"
    echo "${GRAY}[.]${GREEN}localhost${wait_icon}: ${CYAN}${command}${NORM}"
    eval "${command}"
    local _err=$?
    echo "${_err}" > "${RETURN_VALUE_FILE}"
    return "${_err}"
}

# =============================================================================
# Section 5: gnome-terminal Execution Helpers
# =============================================================================
#
# WINDOW_MODE argument:
#   k  keep the tab open regardless of result          (default)
#   e  close on success, keep open on error
#   f  always close  (fire and forget)
#
# WAIT_OPT argument:
#   w     block the caller until the tab's command finishes
#   0     return immediately (non-blocking)
#   <N>   return immediately; caller should sleep N seconds separately
#
# After each call, RETURN_VALUE_FILE holds the path to a file that will
# contain the tab's exit code once it completes.
# When launching multiple tabs in parallel, save the value immediately:
#   gnome_terminal_rexec ...
#   my_ret_file[$i]="${RETURN_VALUE_FILE}"

function _benlib_setup_window_mode(){
    # Internal helper: set err_bash / suc_bash based on window mode
    case "$1" in
        e) err_bash="bash"; suc_bash="exit" ;;
        f) err_bash="exit"; suc_bash="exit" ;;
        *) err_bash="bash"; suc_bash="bash" ;;  # k or default: keep open
    esac
}

function gnome_terminal_rexec(){
    # Run a command on a remote host in a new gnome-terminal tab via SSH.
    # Usage: gnome_terminal_rexec <WINDOW_MODE> <WAIT_OPT> <ADDR[@USR[@PASS]]> <COMMAND>
    local window_mode="$1" wait_opt="$2" addr_usr_pass="$3" command="$4"
    local addr="" usr="" pass="" err_bash="" suc_bash=""
    IFS="@" read -r addr usr pass <<< "${addr_usr_pass}"
    [[ -z "${addr}" ]] && read -r -p "${GREEN}target address:${NORM} " addr
    [[ -z "${usr}"  ]] && read -r -p "${GREEN}${addr}'s user:${NORM} " usr
    if [[ -z "${pass}" ]]; then
        read -r -s -p "${GREEN}${usr}@${addr}'s password:${NORM} " pass
        echo
    fi
    _benlib_setup_window_mode "${window_mode}"
    local wait_icon=""
    [[ "${wait_opt}" == "w" ]] && wait_icon="(w)"
    echo "${GRAY}[gnome-terminal]${GREEN}${usr}@${addr}${wait_icon}: ${CYAN}${command}${NORM}"

    local id; id=$(uuid_gen)
    local done_file="/tmp/benlib_done_${id}"
    RETURN_VALUE_FILE="/tmp/benlib_return_${id}"

    # Write the tab logic to a temp script to avoid multi-level escape issues
    local script_file="/tmp/benlib_script_${id}.sh"
    cat > "${script_file}" << SCRIPT_EOF
#!/bin/bash
echo "${GRAY}[tab]${GREEN}${usr}@${addr}${wait_icon}: ${CYAN}${command}${NORM}"
sshpass -p "${pass}" ssh -o "StrictHostKeyChecking=no" -t "${usr}@${addr}" -- "${command}"
_err=\$?
echo "\${_err}" > "${RETURN_VALUE_FILE}"
touch "${done_file}"
if [ "\${_err}" -ne 0 ]; then
    echo "${RED}[tab] ERROR(exit=\${_err}): ${command}${NORM}"
    ${err_bash}
else
    echo "${GRAY}[tab] Succeeded: ${command}${NORM}"
    ${suc_bash}
fi
rm -f "${script_file}"
SCRIPT_EOF
    chmod +x "${script_file}"
    gnome-terminal --tab -- bash "${script_file}"

    while [[ "${wait_opt}" == "w" && ! -f "${done_file}" ]]; do sleep 0.2; done
    rm -f "${done_file}"
}

function gnome_terminal_lexec(){
    # Run a command locally in a new gnome-terminal tab.
    # Usage: gnome_terminal_lexec <WINDOW_MODE> <WAIT_OPT> <COMMAND>
    local window_mode="$1" wait_opt="$2" command="$3"
    local err_bash="" suc_bash=""
    _benlib_setup_window_mode "${window_mode}"
    local wait_icon=""
    [[ "${wait_opt}" == "w" ]] && wait_icon="(w)"
    echo "${GRAY}[gnome-terminal]${GREEN}localhost${wait_icon}: ${CYAN}${command}${NORM}"

    local id; id=$(uuid_gen)
    local done_file="/tmp/benlib_done_${id}"
    RETURN_VALUE_FILE="/tmp/benlib_return_${id}"

    local script_file="/tmp/benlib_script_${id}.sh"
    cat > "${script_file}" << SCRIPT_EOF
#!/bin/bash
echo "${GRAY}[tab]${GREEN}localhost${wait_icon}: ${CYAN}${command}${NORM}"
${command}
_err=\$?
echo "\${_err}" > "${RETURN_VALUE_FILE}"
touch "${done_file}"
if [ "\${_err}" -ne 0 ]; then
    echo "${RED}[tab] ERROR(exit=\${_err}): ${command}${NORM}"
    ${err_bash}
else
    echo "${GRAY}[tab] Succeeded: ${command}${NORM}"
    ${suc_bash}
fi
rm -f "${script_file}"
SCRIPT_EOF
    chmod +x "${script_file}"
    gnome-terminal --tab -- bash "${script_file}"

    while [[ "${wait_opt}" == "w" && ! -f "${done_file}" ]]; do sleep 0.2; done
    rm -f "${done_file}"
}

# =============================================================================
# Section 6: Script Scaffolding
# =============================================================================

function echo_template(){
    # Print a script template that already sources benlib.sh to stdout.
    # Adjust the path to benlib.sh based on where the generated script is placed.
    cat << 'TMPL'
#!/bin/bash

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
    VALUE="none"

    # Option parsing  (-o: short options, -l: long options, :: optional arg)
    PARSED=$(getopt -o "hv:" -l "help,value:" -- "$@")
    if (( $? != 0 )); then echo_error "Invalid options"; exit 1; fi
    eval set -- "${PARSED}"
    while true; do
        case "$1" in
            -v|--value) shift; VALUE="$1"; shift ;;
            -h|--help)  usage; exit 0 ;;
            --)         shift; break ;;
            *)          echo_error "Unexpected option: $1"; exit 1 ;;
        esac
    done

    echo_info "VALUE=${VALUE}"
}

main "$@"
TMPL
}

function create_scripts(){
    # Create new script files from the built-in template and make them executable.
    # Usage: create_scripts <file> [<file> ...]
    while (( "$#" > 0 )); do
        echo_info "Create $1"
        echo_template > "$1"
        chmod +x "$1"
        shift
    done
}
