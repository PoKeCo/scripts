#!/bin/bash
# Template for ROS2 + Jetson scripts.
# Includes workspace auto-detection, DDS configuration, and Jetson tuning.
# Copy this file and edit it.

function usage(){
    echo "Usage: ${THIS_SCRIPT} [OPTION]"
    echo
    printf " %-20s %s\n" "--help" "Display this help and exit"
}

function install_setup_bash(){
    # Walk up from the current directory looking for install/setup.bash and source it.
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
    echo_error "install/setup.bash not found"
    return 1
}

function set_ros_distro(){
    # Auto-detect the installed ROS distribution when ROS_DISTRO is not set.
    if [[ -z "${ROS_DISTRO:-}" ]]; then
        local distro
        for distro in iron humble galactic foxy eloquent dashing noetic melodic; do
            if [[ -e "/opt/ros/${distro}/" ]]; then
                ROS_DISTRO="${distro}"
                break
            fi
        done
        echo_info "ROS_DISTRO=${ROS_DISTRO:-not found}"
    fi
}

function set_cyclone_dds(){
    # Use CycloneDDS as the DDS implementation if ~/cyclonedds_config.xml exists.
    local cfg="/home/${USER}/cyclonedds_config.xml"
    if [[ -e "${cfg}" ]]; then
        export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
        export CYCLONEDDS_URI="file://${cfg}"
        echo_info "RMW_IMPLEMENTATION=${RMW_IMPLEMENTATION}"
        echo_info "CYCLONEDDS_URI=${CYCLONEDDS_URI}"
    fi
}

function set_jetson(){
    # Detect a Jetson device and set clocks / receive buffer to maximum.
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

    # ROS2 setup
    set_ros_distro
    install_setup_bash
    # set_cyclone_dds  # uncomment to use CycloneDDS
    # set_jetson       # uncomment for Jetson performance tuning

    echo_info "WORKSPACE=${WORKSPACE:-not set}"
    echo_note "non-parsed argument(s)=${args}"

    popd > /dev/null
}

main "$@"
