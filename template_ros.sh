#!/bin/bash
# ROS2 + Jetson 対応テンプレート。
# ROS2 ワークスペースの自動検出・DDS 設定・Jetson チューニングを含む。
# 使い方: このファイルをコピーして編集する。

function usage(){
    echo "Usage: ${THIS_SCRIPT} [OPTION]"
    echo
    printf " %-20s %s\n" "--help" "Display this help and exit"
}

function install_setup_bash(){
    # カレントディレクトリから上に向かって install/setup.bash を探して source する。
    local dir; dir=$(pwd)
    while [[ "${dir}" != "/" ]]; do
        if [[ -e "${dir}/install/setup.bash" ]]; then
            WORKSPACE="${dir}"
            echo_info "source ${dir}/install/setup.bash"
            source "${dir}/install/setup.bash"
            return $?
        fi
        dir=$(dirname "${dir}")
    done
    echo_error "install/setup.bash が見つかりません"
    return 1
}

function set_ros_distro(){
    # ROS_DISTRO が未設定の場合、インストール済みのディストリビューションを自動検出する。
    if [[ -z "${ROS_DISTRO:-}" ]]; then
        local distro
        for distro in iron humble galactic foxy eloquent dashing noetic melodic; do
            if [[ -e "/opt/ros/${distro}/" ]]; then
                ROS_DISTRO="${distro}"
                break
            fi
        done
        echo_info "ROS_DISTRO=${ROS_DISTRO:-未検出}"
    fi
}

function set_cyclone_dds(){
    # ~/cyclonedds_config.xml が存在する場合、CycloneDDS を DDS 実装として設定する。
    local cfg="/home/${USER}/cyclonedds_config.xml"
    if [[ -e "${cfg}" ]]; then
        export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
        export CYCLONEDDS_URI="file://${cfg}"
        echo_info "RMW_IMPLEMENTATION=${RMW_IMPLEMENTATION}"
        echo_info "CYCLONEDDS_URI=${CYCLONEDDS_URI}"
    fi
}

function set_jetson(){
    # Jetson デバイスを検出し、クロック・受信バッファを最大値に設定する。
    if [[ -e "/etc/nv_tegra_release" ]]; then
        IS_JETSON=true
        echo jetson | sudo -S sysctl -w net.core.rmem_max=2147483647
        echo jetson | sudo -S jetson_clocks
        echo_info "This is Jetson"
    else
        IS_JETSON=false
        echo_info "This is NOT Jetson"
    fi
}

function main(){
    SCRIPT_DIR=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")
    THIS_SCRIPT=$(basename "${BASH_SOURCE[0]}")
    source "${SCRIPT_DIR}/benlib.sh"
    set_escape_sequence

    args=""
    while (( "$#" > 0 )); do
        case "$1" in
            --help) usage; exit 0 ;;
            *)      args="${args} $1" ;;
        esac
        shift
    done

    pushd "${SCRIPT_DIR}" > /dev/null

    # ROS2 セットアップ
    set_ros_distro
    install_setup_bash
    # set_cyclone_dds  # CycloneDDS を使う場合はコメントを外す
    # set_jetson       # Jetson チューニングが必要な場合はコメントを外す

    echo_info "WORKSPACE=${WORKSPACE:-未設定}"
    echo_note "non-parsed argument(s)=${args}"

    popd > /dev/null
}

main "$@"
