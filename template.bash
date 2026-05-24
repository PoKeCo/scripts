#!/bin/bash
# 基本テンプレート。使い方: このファイルをコピーして編集する。

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
    # 1段下のディレクトリにある場合: "${SCRIPT_DIR}/../benlib.sh"
    source "${SCRIPT_DIR}/benlib.sh"
    set_escape_sequence

    # デフォルト値
    args=""

    # オプション解析
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
