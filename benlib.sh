#!/bin/bash

function set_escape_sequence(){
    #Forground color
    BLACK=$(printf "\e[30m")
    RED=$(printf "\e[31m")
    GREEN=$(printf "\e[32m")
    YELLOW=$(printf "\e[33m")
    BLUE=$(printf "\e[34m")
    MAGENTA=$(printf "\e[35m")
    CYAN=$(printf "\e[36m")
    WHITE=$(printf "\e[37m")
    GRAY=$(printf "\e[38;2;128;128;128m")
    DGRAY=$(printf "\e[38;2;64;64;64m")
    
    NORM=$(printf "\e[0m") # Return to default color
    
    CLS=$(printf "\e[2J") # CLear Screen
    CLL=$(printf "\e[2K") # CLear Line
    LOCATE_0_0=$(printf "\e[0;0H") # Locate cursor position to 0[raw],0[col]

    if [[ "$1" == "-v" ]];then
        color_list="CLS CLL LOCATE_0_0 BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE GRAY DGRAY NORM"
        for i in ${color_list};do
            echo "    echo -e \"\${${i}} ${i} \${NORM}\""
        done
        echo -e "${CLS}"
        echo -e "${CLL}"
        echo -e "${LOCATE_0_0} LOCATE_0_0 ${NORM}"
        echo -e "${BLACK} BLACK ${NORM}"
        echo -e "${RED} RED ${NORM}"
        echo -e "${GREEN} GREEN ${NORM}"
        echo -e "${YELLOW} YELLOW ${NORM}"
        echo -e "${BLUE} BLUE ${NORM}"
        echo -e "${MAGENTA} MAGENTA ${NORM}"
        echo -e "${CYAN} CYAN ${NORM}"
        echo -e "${WHITE} WHITE ${NORM}"
        echo -e "${GRAY} GRAY ${NORM}"
        echo -e "${DGRAY} DGRAY ${NORM}"
        echo -e "${NORM} NORM ${NORM}"
    fi
}

function echo_note(){
    echo "${GRAY}[NOTE]:$*${NORM}"
}

function echo_info(){
    echo "${CYAN}[INFO]:$*${NORM}"
}

function echo_warning(){
    echo "${YELLOW}[WARNING]:$*${NORM}"
}

function echo_error(){
    echo "${RED}[ERROR]:$*${NORM}"
}

function show_var(){
    echo "$1=${!1}"
}

function echo_template(){
cat <<'EOF'
#!/bin/bash

function usage(){
    echo "Usage: ${THIS_SCRIPT} [OPTION]"
    echo
    echo
    echo Mandatory arguments to long options are mandatory for short options too.
    printf " %-20s %s\n" "--help" "Display this help and exit"
}

function main(){
    
    # BENLI functions
    RERATIVE_SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
    SCRIPT_DIR=$(readlink -f "${RERATIVE_SCRIPT_DIR}")
    THIS_SCRIPT=$(basename "${BASH_SOURCE[0]}")
    source "${SCRIPT_DIR}/benlib.sh"
    
    # Initialize
    set_escape_sequence --
    
    # Default values
    VALUE="none"
    
    # Parse options
    # -o:Short option, -l:Long option, :is argument
    SHORT_OPT_STRING="hv:"
    LONG_OPT_STRING="help,value:"
    PARSED=$(getopt -o "${SHORT_OPT_STRING}" -l "${LONG_OPT_STRING}" -- "$@")
    GETOPT_RETVAL="$?"
    if (( "${GETOPT_RETVAL}" != 0 ));then 
        echo_error "Invalid Options"
        exit 1
    fi
    eval set -- "$PARSED"
    while true; do
        case "$1" in
            -v)
            shift; VALUE="$1"; shift ;;
            -h)
            usage; exit 0;;
            --help)
            usage; exit 0;;
            --)
            shift; break ;; # Argument parse done
            *)
            echo_erro "Invalid option";usage_template; exit 1 ;;
        esac
    done
    
    # Main Procedure
    echo VALUE="${VALUE}"
    
}

main "$@"
EOF
}

function create_scripts(){
    while (( "$#" > 0 )) ;do
        echo_info "Create $1"
        echo_template > "$1"
        chmod +x "$1"
        shift
    done
}

