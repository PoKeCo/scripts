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
    MAGENTA=`printf "\e[35m"`
    CYAN=`printf "\e[36m"`
    WHITE=`printf "\e[37m"`
    GLAY=`printf "\e[38;2;128;128;128m"` # You can specify R,G,B
    DGLAY=`printf "\e[38;2;64;64;64m"` # You can specify R,G,B
    
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
    MVUP=`printf "\e[1A"`
    MVDOWN=`printf "\e[1B"`
    MVRIGHT=`printf "\e[1C"`
    MVLEFT=`printf "\e[1D"`
    MVUPHEAD=`printf "\e[1E"`
    MVDOWNHEAD=`printf "\e[1F"`    
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
#hbar="█▉▊▋▌▍▎▏ "

function show_bar(){
    printf "${WHITE}${BK_DGLAY}"
    vbar=" ▁▂▃▄▅▆▇█"

    hbar=" ▏▎▍▌▋▊▉█"
    bar="█"
    val=$1
    val_d=$[val/8]
    val_f=$[val%8]
    for (( j=0 ; j<val_d ; j++ ));do
	printf ${bar}
    done
    mv_left=$[val_d+1]
    printf "${hbar:val_f:1}"
    #printf "${hbar:val_f:1}\e[${mv_left}D"

    if [ -n "$2" ];then
	j=$[j+1]
	val_end=$2
	val_end_d=$[(val_end)/8]
	for ((  ; j<val_end_d ; j++ ));do
	    printf " "
	done
	printf "\e[${val_end_d}D"
    else
	printf "\e[${mv_left}D"
    fi
    printf "${NORM}"
}

printf "count = "
for (( i=0 ; i<=63 ; i++ ));do
    show_bar ${i} 64
    #printf "\e[0G"
    sleep 0.01
done
printf "\n"


#echo ${CYAN}${SCRIPT_DIR}${NORM}
#if [ -n "${message}" ];then
#    echo message=${YELLOW}${message}${NORM}
#fi


