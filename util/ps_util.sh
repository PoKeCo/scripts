#!/bin/bash
function main(){
    ## Prepare 
    set_escape_sequence

    SCRIPT_DIR=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
    THIS_SCRIPT=$(basename ${BASH_SOURCE[0]})

    ## Parse Argument
    args=""
    opt=""
    while (( "$#" > 0 ));do
        arg=$1
        case ${arg} in
        --help)
            show_help
            exit 0
            ;;
        -s)
	    opt="snap"
            ;;
        -k)
	    opt="kill"
            ;;
        -c)
	    opt="clean"
            ;;
        *)
            args="${args} ${arg}"
            ;;            
        esac
        shift
    done

    ## Core
    THIS_PID="$$"
    PS_STAMP_SNAP=/tmp/ps_stamp_snap.txt
    PS_STAMP=/tmp/ps_stamp.txt
    pushd ${SCRIPT_DIR} > /dev/null
    case "${opt}" in
	"snap")
	    ps -e | tail -n +2 | awk '{print $1}' | grep -v "${THIS_PID}" > ${PS_STAMP_SNAP}
	    ;;
	"kill")
	    if [ ! -f "${PS_STAMP_SNAP}" ];then
		echo_error "${PS_STAMP_SNAP} was not found"
		exit 2
	    fi
	    ps -e | tail -n +2 | awk '{print $1}' | grep -v "${THIS_PID}" > ${PS_STAMP}
	    diff ${PS_STAMP_SNAP} ${PS_STAMP} | sed '/^>/!d;s/^> //' | xargs ps -lf | grep ${USER} | awk '{print $4}' | xargs kill
	    ;;
	"clean")
	    if [ -f "${PS_STAMP_SNAP}" ];then
		rm "${PS_STAMP_SNAP}"
	    fi
	    if [ -f "${PS_STAMP}" ];then
		rm "${PS_STAMP}"
	    fi
	    echo_note "Clean ${PS_STAMP} ${PS_STAMP_SNAP}"
	    ;;
	*)
	    if [ ! -f "${PS_STAMP_SNAP}" ];then
		echo_warning "${PS_STAMP_SNAP} was not found. Create ${PS_STAMP_SNAP}."
		ps -e | tail -n +2 | awk '{print $1}' | grep -v "${THIS_PID}" > ${PS_STAMP_SNAP}
		exit 3
	    fi
	    ps -e | tail -n +2 | awk '{print $1}' | grep -v "${THIS_PID}" > ${PS_STAMP}
	    diff ${PS_STAMP_SNAP} ${PS_STAMP} | sed '/^>/!d;s/^> //' | xargs ps -lf | grep ${USER}
	    ;;
    esac
    popd > /dev/null
}

function show_help(){
    echo Usage: ${THIS_SCRIPT} [OPTION]
    echo 
    echo 
    echo Mandatory arguments to long options are mandatory for short options too.
    printf " %-20s %s\n" "--help" "Display this help and exit"
    printf " %-20s %s\n" "-s"     "Save Current PIDs"
    printf " %-20s %s\n" "-k"     "Kill process w/o Saved PIDs"
    printf " %-20s %s\n" "-c"     "Clear PID files"
    printf " %-20s %s\n" "(no option)" "Show process w/o Saved PIDs"
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

main $@
