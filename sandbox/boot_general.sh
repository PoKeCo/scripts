#!/bin/bash
# =============================================================================
# boot_general.sh
#
# NOTE: This file is an experimental sandbox.
# For the general-purpose template, see ../template_boot.sh.
# It is recommended to copy ../template_boot.sh and edit it instead.
# =============================================================================
#
# SEQUENCE_LIST format (delimiter: ":"):
#   HOST:COMMAND:WINDOW_MODE:WAIT_OPT
#
#   HOST         ADDR@USR@PASS (SSH)  / localhost  / .  (run locally inline)
#   COMMAND      shell command to run (must not contain ":")
#   WINDOW_MODE  k=keep tab open  e=close on success  f=always close
#   WAIT_OPT     w=wait until done  0=no wait  N=sleep N seconds then proceed

function on_all_success(){
    echo_info "All sequences completed successfully."
    # Add any post-processing here if needed.
}

function on_any_failure(){
    echo_warning "One or more sequences failed."
    # Add error handling here if needed.
}

function show_help(){
    echo "Usage: ${THIS_SCRIPT} [OPTION]"
    echo
    printf " %-20s %s\n" "--help" "Display this help and exit"
}

## ── User configuration ───────────────────────────────────────────────────────

SEQUENCE_LIST=$(cat << 'EOF'
# HOST                  :COMMAND           :WINDOW_MODE:WAIT_OPT
192.168.1.1@hoge@hoge   :echo "process 1"  :k          :0
192.168.1.2@hoge@hoge   :echo "process 2"  :k          :w
192.168.1.3@hoge@hoge   :echo "process 3"  :e          :0
192.168.1.4@hoge@hoge   :echo "process 4"  :f          :0
localhost               :echo "process 5"  :f          :0
EOF
)

## ── Engine (do not modify) ───────────────────────────────────────────────────

function _run_sequences(){
    declare -A _seqs _hosts _cmds _wmodes _wopts _ret_files
    local _count=0

    while IFS= read -r _line; do
        _line="${_line%%#*}"
        _line="${_line#"${_line%%[![:space:]]*}"}"
        [[ -z "${_line}" ]] && continue

        local _host _cmd _wmode _wopt
        IFS=":" read -r _host _cmd _wmode _wopt <<< "${_line}"
        _host="${_host%"${_host##*[![:space:]]}"}"; _host="${_host#"${_host%%[![:space:]]*}"}"
        _cmd="${_cmd%"${_cmd##*[![:space:]]}"}";   _cmd="${_cmd#"${_cmd%%[![:space:]]*}"}"
        _wmode="${_wmode%"${_wmode##*[![:space:]]}"}"; _wmode="${_wmode#"${_wmode%%[![:space:]]*}"}"
        _wopt="${_wopt%"${_wopt##*[![:space:]]}"}"; _wopt="${_wopt#"${_wopt%%[![:space:]]*}"}"
        [[ -z "${_cmd}" ]] && continue

        _seqs[$_count]="${_line}"
        _hosts[$_count]="${_host}"
        _cmds[$_count]="${_cmd}"
        _wmodes[$_count]="${_wmode}"
        _wopts[$_count]="${_wopt}"
        (( _count++ ))
    done <<< "${SEQUENCE_LIST}"

    for (( i=0; i<_count; i++ )); do
        local _host="${_hosts[$i]}" _cmd="${_cmds[$i]}"
        local _wmode="${_wmodes[$i]}" _wopt="${_wopts[$i]}"
        local _addr="${_host%%@*}"

        [[ "${_addr}" != "localhost" && "${_addr}" != "." ]] && prepare_ssh "${_addr}" 2>/dev/null

        if   [[ "${_addr}" == "." ]];        then lexec                               "${_wopt}"  "${_cmd}"
        elif [[ "${_addr}" == "localhost" ]]; then gnome_terminal_lexec  "${_wmode}"  "${_wopt}"  "${_cmd}"
        else                                      gnome_terminal_rexec   "${_wmode}"  "${_wopt}"  "${_host}" "${_cmd}"
        fi
        _ret_files[$i]="${RETURN_VALUE_FILE}"

        if is_number "${_wopt}" && [[ "${_wopt}" != "0" ]]; then
            echo_note "Waiting ${_wopt}s..."
            sleep "${_wopt}"
        fi
    done

    local _sum_err=0
    echo
    printf "${BLACK}$(BK_RGB 255 255 255) Summary ${NORM}\n\n"
    printf " %-5s  %s\n" "Exit" "Sequence"
    for (( i=0; i<_count; i++ )); do
        while [[ ! -f "${_ret_files[$i]}" ]]; do sleep 0.2; done
        local _rv; _rv=$(cat "${_ret_files[$i]}")
        rm -f "${_ret_files[$i]}"
        local _col; (( _rv == 0 )) && _col="${GREEN}" || _col="${RED}"
        printf "${_col}%5d  %s${NORM}\n" "${_rv}" "${_seqs[$i]}"
        (( _sum_err += _rv ))
    done

    echo
    (( _sum_err == 0 )) && on_all_success || on_any_failure
}

## ── Main ─────────────────────────────────────────────────────────────────────

SCRIPT_DIR=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")
THIS_SCRIPT=$(basename "${BASH_SOURCE[0]}")
source "${SCRIPT_DIR}/../benlib.sh"
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
    gnome-terminal \
        --zoom=0.75 \
        --geometry=220x30-26+4 \
        --title="${THIS_SCRIPT}" \
        -- bash -c "\"${SCRIPT_DIR}/${THIS_SCRIPT}\" --sub; bash"
else
    _run_sequences
fi
