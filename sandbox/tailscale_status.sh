#!/bin/bash
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
    
    NORM=`printf "\e[0m"` # Return to default color
    
    CLS=`printf "\e[2J"` # CLear Screen
    CLL=`printf "\e[2K"` # CLear Line
    LOCATE_0_0=`printf "\e[0;0H"` # Locate cursor position to 0[raw],0[col]
}
function max_length(){
    if (( "$1" < "${#2}" ));then
	echo "${#2}"
    else
	echo "$1"
    fi
}

set_escape_sequence

TMP=$(mktemp)
tailscale.exe status > ${TMP}

IP_LEN=0
NAME_LEN=0
USR_LEN=0
OS_LEN=0
STATUS_LEN=0
while IFS= read line ;do
    IFS=" " read -ra term_array <<< ${line}
    IP="${term_array[0]}"
    NAME="${term_array[1]}"
    USR="${term_array[2]}"
    OS="${term_array[3]}"
    STATUS="${term_array[4]}"
    IP_LEN=$(max_length     "${IP_LEN}"     "${IP}")
    NAME_LEN=$(max_length   "${NAME_LEN}"   "${NAME}")
    USR_LEN=$(max_length    "${USR_LEN}"    "${USR}")
    OS_LEN=$(max_length     "${OS_LEN}"     "${OS}")
    STATUS_LEN=$(max_length "${STATUS_LEN}" "${STATUS}")
done < ${TMP}

FMT="%-${IP_LEN}s %-${NAME_LEN}s %-${USR_LEN}s %-${OS_LEN}s %${STATUS_LEN}s\n"

while IFS= read line ;do
    IFS=" " read -ra term_array <<< ${line}
    IP="${term_array[0]}"
    NAME="${term_array[1]}"
    USR="${term_array[2]}"
    OS="${term_array[3]}"
    STATUS="${term_array[4]}"
    if [[ "${STATUS}" == "offline" ]];then
	printf "${GLAY}"
    else
	printf "${NORM}"
    fi
    printf "${FMT}${NORM}" ${IP} ${NAME} ${USR} ${OS} ${STATUS}
done < ${TMP}

rm ${TMP}
