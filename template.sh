#!/bin/bash

function show_help(){
    echo Usage: ${THIS_SCRIPT} [OPTION]
    echo This is template of scripts
    echo 
    echo Mandatory arguments to long options are mandatory for short options too.
    printf " %-20s %s\n" "-m <message> " "Show message of argument"
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
    # Usage: $(RGB 128 128 0)
    printf "\e[38;2;%d;%d;%dm" $1 $2 $3
}

function BK_RGB(){
    # Usage: $(BK_RGB 128 128 0)
    printf "\e[48;2;%d;%d;%dm" $1 $2 $3
}

function LOCATE(){
    # Usage: $(LOCATE 10 20)
    printf "\e[%d;%dH" $1 $2
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
