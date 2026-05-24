#!/bin/bash
# =============================================================================
# template_boot.sh — 複数ホストへの一括コマンド実行テンプレート
#
# 使い方:
#   1. このファイルをコピーして my_boot.sh などの名前で保存する
#   2. SEQUENCE_LIST と on_all_success / on_any_failure を編集する
#   3. ./my_boot.sh で実行する
#
# SEQUENCE_LIST のフォーマット（1行1エントリ、区切り文字は「:」）:
#
#   HOST:COMMAND:WINDOW_MODE:WAIT_OPT
#
#   HOST         ADDR@USR@PASS   SSH でリモートホストに接続
#                localhost       ローカルで gnome-terminal タブを開く
#                .               ローカルで現在のシェルに直接実行（タブなし）
#   COMMAND      実行するシェルコマンド（コマンド内に「:」を含めないこと）
#   WINDOW_MODE  k=実行後もタブを開いたまま  e=成功時に閉じる  f=常に閉じる
#   WAIT_OPT     w=完了まで待機  0=待機なし  N=N秒スリープ後に次へ進む
#
#   行頭が # の行はコメントとして無視される。
#
# SEQUENCE_LIST の例:
#   192.168.1.10@jetson@pass:ros2 launch robot bringup.launch.py:k:w
#   192.168.1.11@jetson@pass:ros2 launch sensor lidar.launch.py:k:5
#   localhost:rviz2:e:0
#   .:echo "全ノード起動完了":f:0
# =============================================================================

# =============================================================================
# ── ユーザー設定エリア（ここを編集する）────────────────────────────────────

SEQUENCE_LIST=$(cat << 'EOF'
# HOST                    :COMMAND                  :WINDOW_MODE:WAIT_OPT
192.168.1.10@user@pass    :echo "hello from host1"  :k          :0
192.168.1.11@user@pass    :echo "hello from host2"  :k          :w
localhost                 :echo "local tab"         :e          :0
.                         :echo "inline local"      :f          :0
EOF
)

function on_all_success(){
    # 全シーケンスがエラーなく完了したときに呼ばれる。
    # このコピーでオーバーライドして使う。
    echo_info "全シーケンスが正常に完了しました。"
}

function on_any_failure(){
    # 1つ以上のシーケンスが失敗したときに呼ばれる。
    # このコピーでオーバーライドして使う。
    echo_warning "失敗したシーケンスがあります。上記 Summary を確認してください。"
}

# ── ユーザー設定エリアここまで ───────────────────────────────────────────────
# =============================================================================

function show_help(){
    echo "Usage: ${THIS_SCRIPT} [OPTION]"
    echo
    echo "複数ホストへのコマンドを gnome-terminal タブで一括実行します。"
    echo
    printf " %-20s %s\n" "--help" "このヘルプを表示して終了"
}

function _run_sequences(){
    # SEQUENCE_LIST を解析して各エントリを実行し、最後に Summary を表示する。
    declare -A _seqs _hosts _cmds _wmodes _wopts _ret_files
    local _count=0

    while IFS= read -r _line; do
        # コメント・空行をスキップ
        _line="${_line%%#*}"
        _line="${_line#"${_line%%[![:space:]]*}"}"  # 先頭の空白を除去
        [[ -z "${_line}" ]] && continue

        # フィールド分割（区切りは「:」）
        local _host _cmd _wmode _wopt
        IFS=":" read -r _host _cmd _wmode _wopt <<< "${_line}"

        # 空白トリム
        _host="${_host#"${_host%%[![:space:]]*}"}"; _host="${_host%"${_host##*[![:space:]]}"}"
        _cmd="${_cmd#"${_cmd%%[![:space:]]*}"}";   _cmd="${_cmd%"${_cmd##*[![:space:]]}"}"
        _wmode="${_wmode#"${_wmode%%[![:space:]]*}"}"; _wmode="${_wmode%"${_wmode##*[![:space:]]}"}"
        _wopt="${_wopt#"${_wopt%%[![:space:]]*}"}"; _wopt="${_wopt%"${_wopt##*[![:space:]]}"}"

        [[ -z "${_cmd}" ]] && continue  # COMMAND が空の行はスキップ

        _seqs[$_count]="${_line}"
        _hosts[$_count]="${_host}"
        _cmds[$_count]="${_cmd}"
        _wmodes[$_count]="${_wmode}"
        _wopts[$_count]="${_wopt}"
        (( _count++ ))
    done <<< "${SEQUENCE_LIST}"

    # 各エントリを実行
    for (( i=0; i<_count; i++ )); do
        local _host="${_hosts[$i]}"
        local _cmd="${_cmds[$i]}"
        local _wmode="${_wmodes[$i]}"
        local _wopt="${_wopts[$i]}"

        # ADDR を HOST フィールドの最初の @ 前から取得
        local _addr="${_host%%@*}"

        # known_hosts をクリーン（SSH 接続先のみ）
        if [[ "${_addr}" != "localhost" && "${_addr}" != "." ]]; then
            prepare_ssh "${_addr}" 2>/dev/null
        fi

        # ホスト種別に応じて実行
        if   [[ "${_addr}" == "." ]];         then
            lexec                                 "${_wopt}"  "${_cmd}"
        elif [[ "${_addr}" == "localhost" ]];  then
            gnome_terminal_lexec  "${_wmode}"    "${_wopt}"  "${_cmd}"
        else
            gnome_terminal_rexec  "${_wmode}"    "${_wopt}"  "${_host}" "${_cmd}"
        fi
        _ret_files[$i]="${RETURN_VALUE_FILE}"

        # 数値の WAIT_OPT は「次のエントリまでの待機秒数」として扱う
        if is_number "${_wopt}" && [[ "${_wopt}" != "0" ]]; then
            echo_note "${_wopt}秒待機..."
            sleep "${_wopt}"
        fi
    done

    # 全タブの完了を待って Summary を表示
    local _sum_err=0
    echo
    printf "${BLACK}$(BK_RGB 255 255 255) Summary ${NORM}\n\n"
    printf " %-5s  %s\n" "Exit" "Sequence"
    for (( i=0; i<_count; i++ )); do
        # タブが終了ファイルを書き込むまで待機
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
# メイン
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
    # 専用の gnome-terminal ウィンドウを開いて --sub モードで自分自身を再起動する
    gnome-terminal \
        --zoom=0.75 \
        --geometry=220x30-26+4 \
        --title="${THIS_SCRIPT}" \
        -- bash -c "\"${SCRIPT_DIR}/${THIS_SCRIPT}\" --sub; bash"
else
    _run_sequences
fi
