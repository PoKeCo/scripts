#!/bin/bash
# =============================================================================
# boot_general.sh
#
# 注意: このファイルは実験用サンドボックスです。
# 汎用テンプレートとして整備されたものは ../template_boot.sh を参照してください。
# このファイルを利用する場合は ../template_boot.sh をコピーして編集することを推奨します。
# =============================================================================
#
# SEQUENCE_LIST のフォーマット（区切り文字は「:」）:
#   HOST:COMMAND:WINDOW_MODE:WAIT_OPT
#
#   HOST         ADDR@USR@PASS  (SSH接続)  / localhost  / .  (ローカル直接実行)
#   COMMAND      実行コマンド（コマンド内に「:」を含めないこと）
#   WINDOW_MODE  k=開いたまま  e=成功時に閉じる  f=常に閉じる
#   WAIT_OPT     w=完了まで待機  0=待機なし  N=N秒後に次へ

function on_all_success(){
    echo_info "全シーケンスが正常に完了しました。"
    # 必要に応じてここに後処理を記述する
}

function on_any_failure(){
    echo_warning "失敗したシーケンスがあります。"
    # 必要に応じてここにエラー処理を記述する
}

function show_help(){
    echo "Usage: ${THIS_SCRIPT} [OPTION]"
    echo
    printf " %-20s %s\n" "--help" "Display this help and exit"
}

## ── ユーザー設定 ─────────────────────────────────────────────────────────────

SEQUENCE_LIST=$(cat << 'EOF'
# HOST                  :COMMAND           :WINDOW_MODE:WAIT_OPT
192.168.1.1@hoge@hoge   :echo "process 1"  :k          :0
192.168.1.2@hoge@hoge   :echo "process 2"  :k          :w
192.168.1.3@hoge@hoge   :echo "process 3"  :e          :0
192.168.1.4@hoge@hoge   :echo "process 4"  :f          :0
localhost               :echo "process 5"  :f          :0
EOF
)

## ── エンジン（変更不要）─────────────────────────────────────────────────────

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
            echo_note "${_wopt}秒待機..."
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

## ── メイン ───────────────────────────────────────────────────────────────────

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
