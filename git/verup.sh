#!/bin/bash

function show_help(){
    echo Usage: ${THIS_SCRIPT} [OPTION]
    echo 
    echo 
    echo Mandatory arguments to long options are mandatory for short options too.
    printf " %-20s %s\n" "--help" "Display this help and exit"
    printf " %-20s %s\n" "-p id"  "Process stop phase ID (0-8). Default: ${proc_stop}"
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

function parse_branch(){
    branch=$1
    PREFIX=
    MAJOR=
    MINOR=
    PATCH=
    FEATURE=
    if [[ "${branch}" =~ ^([a-z]+)-([0-9]+)\.([0-9]+)\.([0-9]+)(-(.+))?$ ]];then
        PREFIX=${BASH_REMATCH[1]}
        MAJOR=${BASH_REMATCH[2]}
        MINOR=${BASH_REMATCH[3]}
        PATCH=${BASH_REMATCH[4]}
        FEATURE=${BASH_REMATCH[6]}
    fi
    echo "${PREFIX} ${MAJOR} ${MINOR} ${PATCH} ${FEATURE}"
    
}

function get_branch_name(){
    PREFIX=$1
    MAJOR=$2
    MINOR=$3
    PATCH=$4
    FEATURE=$5
    if [[ "${FEATURE}" == "" ]];then
        echo "${PREFIX}-${MAJOR}.${MINOR}.${PATCH}"
    else
        echo "${PREFIX}-${MAJOR}.${MINOR}.${PATCH}-${FEATURE}"
    fi
}


## Prepare 
set_escape_sequence

SCRIPT_DIR=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
THIS_SCRIPT=$(basename ${BASH_SOURCE[0]})

proc_stop=8
## Parse Argument
while (( "$#" > 0 ));do
    arg=$1
    case ${arg} in
        --help)
            show_help
            exit 0
            ;;
        -p)
            shift
            proc_stop=$1
            ;;
    esac
    shift
done

## Main

# Inspect current state
rel_last=$(git branch -a | sed 's%\*%%;s%^ *%%;s%remotes/origin/%%;/rel-[0-9]*\.[0-9]*\.[0-9]*/!d'| sort |tail -n1)
rdf_curr=$(git rev-parse --abbrev-ref HEAD)
dirty_list=$(git status --porcelain 2>/dev/null )
if [[ -n ${dirty_list} ]];then
    is_clean=0
else
    is_clean=1
fi

read -ra rel_last_ary <<<$(parse_branch ${rel_last})
read -ra rdf_curr_ary <<<$(parse_branch ${rdf_curr})
echo is_clean=${is_clean}

## Decide git operation
next="$[rel_last_ary[1]].$[rel_last_ary[2]].$[rel_last_ary[3]+1]"
curr="$[rdf_curr_ary[1]].$[rdf_curr_ary[2]].$[rdf_curr_ary[3]]"

phase_id=9
case ${rdf_curr_ary[0]} in
    rel)
        if (( ${is_clean} == 1 ));then
            phase_id=9
        else
            phase_id=0
            rel="rel-${next}"
            dev="dev-${next}"
            f="f-${next}-verup"
        fi
    ;;
    dev)
        rel="rel-${curr}"
        dev=${rdf_curr}
        f="f-${curr}-verup"
        if (( ${is_clean} == 1 ));then
            phase_id=7
        else
            phase_id=1
        fi
    ;;
    f)
        rel="rel-${curr}"
        dev="dev-${curr}"
        f=${rdf_curr}
        if (( ${is_clean} == 1 ));then
            phase_id=4
        else
            phase_id=2
        fi
    ;;
esac

echo "phase_id=${phase_id}"
echo "proc_stop=${proc_stop}"

## Do git operation


if (( phase_id <= 0 && 0 <= proc_stop ));then
    git switch -c ${dev}
fi

if (( phase_id <= 1 && 1 <= proc_stop ));then
    git switch -c ${f}
fi

if (( phase_id <= 2 && 2 <= proc_stop ));then
    git add -A
fi

if (( phase_id <= 3 && 3 <= proc_stop ));then
    comment=$(printf "\n$(git status --porcelain 2>/dev/null)")
    git commit -m "Update:${comment}"
fi

if (( phase_id <= 4 && 4 <= proc_stop ));then
    git switch ${dev}
    err=$?
    if (( ${err} == 128 ));then
        git switch ${rel_last}
        git switch -c ${dev}
    fi
fi

if (( phase_id <= 5 && 5 <= proc_stop ));then
    git merge --no-ff --no-edit ${f}
fi
if (( phase_id <= 6 && 6 <= proc_stop ));then
    git switch ${rel_last}
fi
if (( phase_id <= 7 && 7 <= proc_stop ));then
    git switch -c ${rel}
fi
if (( phase_id <= 8 && 8 <= proc_stop ));then
    git merge --no-ff --no-edit ${dev}
fi
