#!/bin/bash
# =============================================================================
# benlib.sh — 共通ライブラリ
#
# 使い方（各スクリプトの main() 冒頭に記述）:
#   SCRIPT_DIR=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")
#   source "${SCRIPT_DIR}/benlib.sh"       # スクリプトと同じ階層の場合
#   source "${SCRIPT_DIR}/../benlib.sh"    # 1段下のディレクトリにある場合
#   set_escape_sequence
# =============================================================================

# =============================================================================
# Section 1: ターミナルカラー / カーソル制御
# =============================================================================

function set_escape_sequence(){
    # 前景色
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

    # 背景色
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

    NORM=$(printf "\e[0m")          # 色リセット
    CLS=$(printf "\e[2J")           # 画面クリア
    CLL=$(printf "\e[2K")           # 行クリア
    LOCATE_0_0=$(printf "\e[0;0H")  # カーソルを左上へ

    # -v オプションで色見本を表示
    if [[ "${1:-}" == "-v" ]]; then
        for _c in BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE GRAY DGRAY NORM; do
            echo -e "${!_c} ${_c} ${NORM}"
        done
    fi
}

function RGB(){
    # 任意の前景色を指定  Usage: $(RGB <R> <G> <B>)
    printf "\e[38;2;%d;%d;%dm" "$1" "$2" "$3"
}

function BK_RGB(){
    # 任意の背景色を指定  Usage: $(BK_RGB <R> <G> <B>)
    printf "\e[48;2;%d;%d;%dm" "$1" "$2" "$3"
}

function LOCATE(){
    # カーソル移動  Usage: $(LOCATE <ROW> <COL>)
    printf "\e[%d;%dH" "$1" "$2"
}

# =============================================================================
# Section 2: ログ出力
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
    # 変数名を渡すと "NAME=value" を表示  Usage: show_var VAR_NAME
    echo "$1=${!1}"
}

# =============================================================================
# Section 3: エラーハンドリング
# =============================================================================

function enable_strict_mode(){
    # main() の冒頭で呼ぶと、未定義変数・コマンド失敗を即座に検出できる。
    #
    # 注意:
    #   - if/while の条件式で意図的に失敗を許容している場合は使わないこと。
    #   - set -u により、未初期化変数の参照でエラーになる。
    #     ${VAR:-default} 形式で安全に参照すること。
    set -euo pipefail
    trap '_benlib_err_handler ${LINENO} "${BASH_COMMAND}" $?' ERR
}

function _benlib_err_handler(){
    echo_error "line $1: '$2' が失敗しました (exit $3)"
}

# =============================================================================
# Section 4: SSH / リモート実行ユーティリティ
# =============================================================================

function uuid_gen(){
    cat /proc/sys/kernel/random/uuid
}

function is_number(){
    # 数値なら 0、それ以外なら 1 を返す  Usage: is_number <value>
    [[ "$1" =~ ^-?[0-9]+([.][0-9]+)?$ ]]
}

function prepare_ssh(){
    # 接続前に known_hosts の古いエントリを削除する  Usage: prepare_ssh <ADDR>
    ssh-keygen -f "/home/${USER}/.ssh/known_hosts" -R "$1" 2>/dev/null || true
}

function ssh_exec(){
    # SSH でコマンドを実行（結果を現在のターミナルに表示）
    # Usage: ssh_exec <ADDR> <USR> <PASS> <COMMAND>
    local addr="$1" usr="$2" pass="$3" command="$4"
    echo "${GREEN}${usr}@${addr}: ${CYAN}${command}${NORM}"
    sshpass -p "${pass}" ssh -o "StrictHostKeyChecking=no" -t "${usr}@${addr}" -- "${command}"
}

function ssh_rsync(){
    # SSH 経由でファイルを同期  Usage: ssh_rsync <PASS> <SRC> <DST>
    sshpass -p "$1" rsync -e "ssh -o StrictHostKeyChecking=no" -avzP "$2" "$3"
}

function rexec(){
    # SSH でコマンドを実行（認証情報が不足していれば対話的に補完）
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
    # コマンドを現在のシェルでローカル実行する（gnome-terminal タブなし）
    # 終了コードは ${RETURN_VALUE_FILE} ファイルに書き込まれる
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
# Section 5: gnome-terminal 実行ヘルパー
# =============================================================================
#
# WINDOW_MODE 引数の意味:
#   k  実行後もタブを開いたまま（デフォルト）
#   e  成功時はタブを閉じ、失敗時は開いたまま
#   f  成功・失敗に関わらず常にタブを閉じる
#
# WAIT_OPT 引数の意味:
#   w    コマンド完了まで呼び出し元をブロックする
#   0    即座に戻る（ノンブロッキング）
#   <N>  N 秒スリープしてから戻る（ノンブロッキング）
#
# 各関数は終了後に RETURN_VALUE_FILE にタブの終了コードが書かれるパスを設定する。
# 複数タブを並列起動する場合は、各呼び出し直後に値を別変数に保存すること:
#   gnome_terminal_rexec ...
#   my_ret_file[$i]="${RETURN_VALUE_FILE}"

function _benlib_setup_window_mode(){
    # 内部ヘルパー: err_bash / suc_bash を設定する
    case "$1" in
        e) err_bash="bash"; suc_bash="exit" ;;
        f) err_bash="exit"; suc_bash="exit" ;;
        *) err_bash="bash"; suc_bash="bash" ;;  # k またはデフォルト
    esac
}

function gnome_terminal_rexec(){
    # SSH 経由のコマンドを新しい gnome-terminal タブで実行する
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

    # 多重エスケープを避けるため、タブの処理を一時スクリプトファイルに書き出す
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
    # コマンドを新しい gnome-terminal タブでローカル実行する
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
# Section 6: スクリプト雛形生成
# =============================================================================

function echo_template(){
    # benlib.sh を source する新しいスクリプトの雛形を標準出力に書き出す。
    # benlib.sh への相対パスはスクリプトの配置場所に応じて調整すること。
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

    # benlib.sh のパスはこのスクリプトの配置場所に応じて変更すること
    # 同階層: "${SCRIPT_DIR}/benlib.sh"
    # 1段上: "${SCRIPT_DIR}/../benlib.sh"
    source "${SCRIPT_DIR}/benlib.sh"
    set_escape_sequence

    # デフォルト値
    VALUE="none"

    # オプション解析 (-o: 短いオプション, -l: 長いオプション, :: は任意引数)
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
    # 雛形から新しいスクリプトファイルを生成する  Usage: create_scripts <file> [<file> ...]
    while (( "$#" > 0 )); do
        echo_info "Create $1"
        echo_template > "$1"
        chmod +x "$1"
        shift
    done
}
