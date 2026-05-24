#!/bin/bash
# [非推奨] このファイルは旧形式です。新規スクリプトには template.bash を使用してください。

function main(){
    ## Prepare 
    set_escape_sequence

    SCRIPT_DIR=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
    THIS_SCRIPT=$(basename ${BASH_SOURCE[0]})

    ## Parse Argument
    args=""
    while (( "$#" > 0 ));do
        arg=$1
        case ${arg} in
        --help)
            show_help
            exit 0
            ;;
        *)
            args="${args} ${arg}"
            ;;            
        esac
        shift
    done

    ## Core
    pushd ${SCRIPT_DIR} > /dev/null
    echo_note "non-parsed argument(s)=${args}"
    popd > /dev/null
}

function show_help(){
    echo Usage: ${THIS_SCRIPT} [OPTION]
    echo 
    echo 
    echo Mandatory arguments to long options are mandatory for short options too.
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