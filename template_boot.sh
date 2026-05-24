#!/bin/bash
# =============================================================================
# template_boot.sh — Template for launching commands across multiple hosts
#
# How to use:
#   1. Copy this file and save it as e.g. my_boot.sh
#   2. Edit SEQUENCE_LIST and the on_all_success / on_any_failure hooks below
#   3. Run: ./my_boot.sh
#
# SEQUENCE_LIST format (one entry per line, fields separated by ":"):
#
#   HOST:COMMAND:WINDOW_MODE:WAIT_OPT
#
#   HOST         ADDR@USR@PASS   connect to remote host via SSH
#                localhost       open a local gnome-terminal tab
#                .               run locally in the current shell (no tab)
#   COMMAND      shell command to run (must not contain ":")
#   WINDOW_MODE  k=keep tab open  e=close on success  f=always close
#   WAIT_OPT     w=block until done  0=no wait  N=sleep N seconds then proceed
#
#   Lines starting with # are treated as comments and ignored.
#
# SEQUENCE_LIST examples:
#   192.168.1.10@jetson@pass:ros2 launch robot bringup.launch.py:k:w
#   192.168.1.11@jetson@pass:ros2 launch sensor lidar.launch.py:k:5
#   localhost:rviz2:e:0
#   .:echo "All nodes launched":f:0
# =============================================================================

# =============================================================================
# -- User configuration (edit this section) -----------------------------------

SEQUENCE_LIST=$(cat << 'EOF'
# HOST                    :COMMAND                  :WINDOW_MODE:WAIT_OPT
192.168.1.10@user@pass    :echo "hello from host1"  :k          :0
192.168.1.11@user@pass    :echo "hello from host2"  :k          :w
localhost                 :echo "local tab"         :e          :0
.                         :echo "inline local"      :f          :0
EOF
)

function on_all_success(){
    # Called when all sequences complete without errors.
    # Override this function in your copy.
    echo_info "All sequences completed successfully."
}

function on_any_failure(){
    # Called when one or more sequences fail.
    # Override this function in your copy.
    echo_warning "One or more sequences failed. Check the Summary above."
}

# -- End of user configuration ------------------------------------------------
# =============================================================================

function show_help(){
    echo "Usage: ${THIS_SCRIPT} [OPTION]"
    echo
    echo "Run commands on multiple hosts in parallel via gnome-terminal tabs."
    echo
    printf " %-20s %s\n" "--help" "Display this help and exit"
}

function _run_sequences(){
    # Parse SEQUENCE_LIST, execute each entry, then display a Summary.
    declare -A _seqs _hosts _cmds _wmodes _wopts _ret_files
    local _count=0

    while IFS= read -r _line; do
        # Skip comments and blank lines
        _line="${_line%%#*}"
        _line="${_line#"${_line%%[![:space:]]*}"}"  # trim leading whitespace
        [[ -z "${_line}" ]] && continue

        # Split fields (delimiter: ":")
        local _host _cmd _wmode _wopt
        IFS=":" read -r _host _cmd _wmode _wopt <<< "${_line}"

        # Trim surrounding whitespace from each field
        _host="${_host#"${_host%%[![:space:]]*}"}"; _host="${_host%"${_host##*[![:space:]]}"}"
        _cmd="${_cmd#"${_cmd%%[![:space:]]*}"}";   _cmd="${_cmd%"${_cmd##*[![:space:]]}"}"
        _wmode="${_wmode#"${_wmode%%[![:space:]]*}"}"; _wmode="${_wmode%"${_wmode##*[![:space:]]}"}"
        _wopt="${_wopt#"${_wopt%%[![:space:]]*}"}"; _wopt="${_wopt%"${_wopt##*[![:space:]]}"}"

        [[ -z "${_cmd}" ]] && continue  # skip lines with no COMMAND

        _seqs[$_count]="${_line}"
        _hosts[$_count]="${_host}"
        _cmds[$_count]="${_cmd}"
        _wmodes[$_count]="${_wmode}"
        _wopts[$_count]="${_wopt}"
        (( _count++ ))
    done <<< "${SEQUENCE_LIST}"

    # Execute each entry
    for (( i=0; i<_count; i++ )); do
        local _host="${_hosts[$i]}"
        local _cmd="${_cmds[$i]}"
        local _wmode="${_wmodes[$i]}"
        local _wopt="${_wopts[$i]}"

        # Extract ADDR from the HOST field (everything before the first @)
        local _addr="${_host%%@*}"

        # Clear stale known_hosts entry for SSH targets only
        if [[ "${_addr}" != "localhost" && "${_addr}" != "." ]]; then
            prepare_ssh "${_addr}" 2>/dev/null
        fi

        # Dispatch based on host type
        if   [[ "${_addr}" == "." ]];         then
            lexec                                 "${_wopt}"  "${_cmd}"
        elif [[ "${_addr}" == "localhost" ]];  then
            gnome_terminal_lexec  "${_wmode}"    "${_wopt}"  "${_cmd}"
        else
            gnome_terminal_rexec  "${_wmode}"    "${_wopt}"  "${_host}" "${_cmd}"
        fi
        _ret_files[$i]="${RETURN_VALUE_FILE}"

        # A numeric WAIT_OPT means "sleep N seconds before launching the next entry"
        if is_number "${_wopt}" && [[ "${_wopt}" != "0" ]]; then
            echo_note "Waiting ${_wopt}s..."
            sleep "${_wopt}"
        fi
    done

    # Wait for all tabs to finish and display the Summary
    local _sum_err=0
    echo
    printf "${BLACK}$(BK_RGB 255 255 255) Summary ${NORM}\n\n"
    printf " %-5s  %s\n" "Exit" "Sequence"
    for (( i=0; i<_count; i++ )); do
        # Wait until the tab writes its exit code file
        while [[ ! -f "${_ret_files[$i]}" ]]; do sleep 0.2; done
        local _rv; _rv=$(cat "${_ret_files[$i]}")
        rm -f "${_ret_files[$i]}"
        local _col; (( _rv == 0 )) && _col="${GREEN}" || _col="${RED}"
        printf "${_col}%5d  %s${NORM}\n" "${_rv}" "${_seqs[$i]}"
        (( _sum_err += _rv ))
    done

    echo
    if (( _sum_err == 0 )); then
        on_all_success
    else
        on_any_failure
    fi
}

# =============================================================================
# Main
# =============================================================================

SCRIPT_DIR=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")
THIS_SCRIPT=$(basename "${BASH_SOURCE[0]}")
source "${SCRIPT_DIR}/benlib.sh"
set_escape_sequence

_IS_SUB=0
while (( "$#" > 0 )); do
    case "$1" in
        --help) show_help; exit 0 ;;
        --sub)  _IS_SUB=1 ;;
    esac
    shift
done

if (( _IS_SUB == 0 )); then
    # Open a dedicated gnome-terminal window and re-launch in --sub mode
    gnome-terminal \
        --zoom=0.75 \
        --geometry=220x30-26+4 \
        --title="${THIS_SCRIPT}" \
        -- bash -c "\"${SCRIPT_DIR}/${THIS_SCRIPT}\" --sub; bash"
else
    _run_sequences
fi
