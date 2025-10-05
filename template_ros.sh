#!/bin/bash

function show_help(){
    echo Usage: ${THIS_SCRIPT} [OPTION]
    echo 
    echo 
    echo Mandatory arguments to long options are mandatory for short options too.
    printf " %-20s %s\n" "--help" "Display this help and exit"
}

function echo_note(){
    echo "${GRAY}[NOTE]:$@${NORM}"
}

function echo_info(){
    echo "${CYAN}[INFO]:$@${NORM}"
}

function echo_warning(){
    echo "${YELLOW}[WARNING]:$@${NORM}"
}

function echo_error(){
    echo "${RED}[ERROR]:$@${NORM}"
}

function install_setup_bash(){
    while [[ "$(pwd)" != "/" ]];do
	if [[ -e ./install/setup.bash ]];then
	    echo_info "$(pwd)/install/setup.bash"
	    source ./install/setup.bash
	    return "$?"
	fi
	cd ..
    done
    echo_error "setup.bash is not found"
    return 1
}

function set_ros_distro(){
    declare -a ros_distro_list
    mapfile -t ros_distro_list<<EOF 
iron
humble
galactic
foxy
eloquent
dashing
crystal
bouncy
ardent
noetic
melodic
lunar
kinetic
jade
indigo
hydro
groovy
fuerte
electric
diamondback
cturtle
bOX
EOF
    if [ "${ROS_DISTRO}" == "" ];then
	for distro in ${ros_distro_list[@]};do
	    if [ -e /opt/ros/${distro}/ ];then
		ROS_DISTRO="${distro}"
		break
	    fi
	done
	echo_info "ROS_DISTRO=${ROS_DISTRO}"
    fi
}

function set_cyclone_dds(){
    CYCLONEDDS_FILE="/home/${USER}/cyclonedds_config.xml"
    if [ -e "${CYCLONEDDS_FILE}" ];then
	export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
	export CYCLONEDDS_URI="file://${CYCLONEDDS_FILE}"
	echo_info  RMW_IMPLEMENTATION=${RMW_IMPLEMENTATION}
	echo_info  CYCLONEDDS_URI=${CYCLONEDDS_URI}
    fi    
}

function set_jetson(){
    if [ -e "/etc/nv_tegra_release" ] ;then
	IS_JETSON=true
	echo jetson | sudo -S sysctl -w net.core.rmem_max=2147483647
	echo jetson | sudo -S jetson_clocks
    else
	IS_JETSON=false
    fi
    if [[ ${IS_JETSON} == true ]];then
	echo_info This is jetson
    else
	echo_info This is NOT jetson
    fi
}


function set_escape_sequence(){
    #Forground color 
    BLACK=`printf "\e[30m"`
    RED=`printf "\e[31m"`
    GREEN=`printf "\e[32m"`
    YELLOW=`printf "\e[33m"`
    BLUE=`printf "\e[34m"`
    MAGENTA=`printf "\e[35m"`
    CYAN=`printf "\e[36m"`
    WHITE=`printf "\e[37m"`
    GRAY=`printf "\e[38;2;128;128;128m"` # You can specify R,G,B
    DGRAY=`printf "\e[38;2;64;64;64m"` # You can specify R,G,B
    
    NORM=`printf "\e[0m"` # Return to default color
    
    CLS=`printf "\e[2J"` # CLear Screen
    CLL=`printf "\e[2K"` # CLear Line
    LOCATE_0_0=`printf "\e[0;0H"` # Locate cursor position to 0[raw],0[col]
}

## Prepare 
set_escape_sequence

SCRIPT_DIR=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
THIS_SCRIPT=$(basename ${BASH_SOURCE[0]})

## Parse Argument
while (( "$#" > 0 ));do
    arg=$1
    case ${arg} in
	--help)
	    show_help
	    exit 0
	    ;;
    esac
    shift
done

pushd ${SCRIPT_DIR} > /dev/null

## Prepare for ros
set_ros_distro
install_setup_bash
set_cyclone_dds
set_jetson

## Main
popd > /dev/null
