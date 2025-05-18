#!/bin/bash

function show_help(){
    echo Usage: ${THIS_SCRIPT} [OPTION]
    echo This is template of scripts
    echo 
    echo Mandatory arguments to long options are mandatory for short options too.
    printf " %-20s %s\n" "-m <message> " "Show message of argument"
    printf " %-20s %s\n" "--help" "Display this help and exit"
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
    GLAY=`printf "\e[38;2;128;128;128m"` # You can specify R,G,B
    DGLAY=`printf "\e[38;2;64;64;64m"` # You can specify R,G,B
    
    #Background color 
    BK_BLACK=`printf "\e[40m"`
    BK_RED=`printf "\e[41m"`
    BK_GREEN=`printf "\e[42m"`
    BK_YELLOW=`printf "\e[43m"`
    BK_BLUE=`printf "\e[44m"`
    BK_MAGENTA=`printf "\e[45m"`
    BK_CYAN=`printf "\e[46m"`
    BK_WHITE=`printf "\e[47m"`
    BK_GLAY=`printf "\e[48;2;128;128;128m"` # You can specify R,G,B
    BK_DGLAY=`printf "\e[48;2;64;64;64m"` # You can specify R,G,B

    NORM=`printf "\e[0m"` # Return to default color
    
    CLS=`printf "\e[2J"` # CLear Screen
    CLL=`printf "\e[2K"` # CLear Line
    LOCATE_0_0=`printf "\e[0;0H"` # Locate cursor position to 0[raw],0[col]
}

function RGB(){
    # Usage: $(RGB <R> <G> <B>)
    printf "\e[38;2;%d;%d;%dm" $1 $2 $3
}

function BK_RGB(){
    # Usage: $(BK_RGB <R> <G> <B>)
    printf "\e[48;2;%d;%d;%dm" $1 $2 $3
}

function LOCATE(){
    # Usage: $(LOCATE <X> <Y>)
    printf "\e[%d;%dH" $1 $2
}

function prepare_ssh(){
    # Usage : prepare_ssh <ADDR>
    ADDR=$1
    ssh-keygen -f "/home/${USER}/.ssh/known_hosts" -R "${ADDR}" 
}

function ssh_exec(){
    # Usage : ssh_exec <ADDR> <USR> <PASS> <COMMAND>
    ADDR=$1
    USR=$2
    PASS=$3
    COMMAND=$4
    echo "${GREEN}${USR}@${ADDR}: ${CYAN}${COMMAND}${NORM}"
    sshpass -p ${PASS} ssh -o "StrictHostKeyChecking=no" -t ${USR}@${ADDR} -- "${COMMAND}"
}

function ssh_rsync(){
    # Usage : ssh_rsync <PASS> <SRC> <DST>
    PASS=$1
    SRC=$2
    DST=$3
    sshpass -p ${PASS} rsync -e "ssh -o StrictHostKeyChecking=no" -avzP ${SRC} ${DST}
}

function rexec(){
    # Usage : rexec <COMMAND> [ADDR[@USR[@PASS]]]
    COMMAND=$1
    ADDR_USR_PASS=$2
    IFS="@" read -ra ADDR_USR_PASS_ARRAY <<< "${ADDR_USR_PASS}"
    ADDR="${ADDR_USR_PASS_ARRAY[0]}"
    USR="${ADDR_USR_PASS_ARRAY[1]}"
    PASS="${ADDR_USR_PASS_ARRAY[2]}"
    if [ -z "${ADDR}" ] ; then
	read -p "${GREEN}target address:${NORM}" ADDR
    fi
    if [ -z "${USR}" ] ; then
	read -p "${GREEN}${ADDR}'s user:${NORM}" USR
    fi
    if [ -z "${PASS}" ] ; then
	read -sp "${GREEN}${USR}@${ADDR}'s password:${NORM}" PASS
	echo 
    fi
    echo "${GREEN}${USR}@${ADDR}: ${CYAN}${COMMAND}${NORM}"
    sshpass -p ${PASS} ssh -o "StrictHostKeyChecking=no" -t ${USR}@${ADDR} -- "${COMMAND}"
}

## Prepare 
set_escape_sequence

SCRIPT_DIR=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
THIS_SCRIPT=$(basename ${BASH_SOURCE[0]})

## Parse Argument

while (( "$#" > 0 ));do
    arg=$1
    case ${arg} in
	-m)
	    shift
	    message=$1
	    ;;
	--help)
	    show_help
	    exit 0
	    ;;
    esac
    shift
done

## Main

echo ${CYAN}${SCRIPT_DIR}${NORM}
echo $(RGB 128 128 0)color is 128 128 0${NORM}
echo $(BK_RGB 128 0 128)back color is 128 0 128${NORM}
if [ -n "${message}" ];then
    echo message=${YELLOW}${message}${NORM}
fi



