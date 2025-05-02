#!/bin/bash

function show_help(){
    echo Usage: ${THIS_SCRIPT} [OPTION]
    echo This is template of scripts
    echo 
    echo Mandatory arguments to long options are mandatory for short options too.
    printf " %-20s %s\n" "-m" "Show message of argument"
}

function set_escape_sequence(){
    RED=`printf "\e[31m"`
    GREEN=`printf "\e[32m"`
    YELLOW=`printf "\e[33m"`
    BLUE=`printf "\e[34m"`
    CYAN=`printf "\e[36m"`
    MAGENTA=`printf "\e[35m"`
    GRAY=`printf "\e[38;2;128;128;128m"` # You can specify R,G,B
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
if [ -n "${message}" ];then
    echo message=${YELLOW}${message}${NORM}
fi


