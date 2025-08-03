#!/bin/bash

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
    GLAY=`printf "\e[38;2;128;128;128m"` # You can specify R,G,B
    DGLAY=`printf "\e[38;2;64;64;64m"` # You can specify R,G,B
    
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

## Main

declare -a subdirs
declare -a stack_subdirs
declare -a branches
declare -a stack_branches
declare -a stack_index

stack_ptr=0
index=-1

git submodule update
i=0
while read -r line ;do
    read -ra line_sep <<< ${line}
    subdirs[${i}]=${line_sep[1]}
    branches[${i}]=$(sed 's/(\(.*\)\/\(.*\))/\2/' <<<${line_sep[2]})
    i=$[i+1]
done <<< $(git submodule)
index=$[i-1]

stack_subdirs[${stack_ptr}]=${subdirs[@]}
stack_branches[${stack_ptr}]=${branches[@]}
stack_index[${stack_ptr}]=${index}

while true;do
    read -ra subdirs  <<< ${stack_subdirs[${stack_ptr}]}
    read -ra branches <<< ${stack_branches[${stack_ptr}]}
    index=${stack_index[${stack_ptr}]}
    if (( ${index} >= 0 ));then
	subdir=${subdirs[$index]}
	branch=${branches[$index]}
	index=$[index-1]
	stack_index[${stack_ptr}]=$index
	#######################################
	pushd ${subdir} > /dev/null
	echo "Check: $(pwd) ${branch}"
	printf ${GLAY}
	branch_before=$(git rev-parse --abbrev-ref HEAD)
	if [[ "${branch_before}" != "${branch}" ]];then
	    git submodule update  > /dev/null
	    git switch ${branch} > /dev/null
	    branch_after=$(git branch | head -n 1 | sed 's/*//;s/ //g')
	    git pull > /dev/null
	    printf ${CYAN}
	    echo "change branch ${branch_before} to ${branch_after}"
	fi
	printf ${NORM}
	#######################################
	i=0
	while read -r line ;do
	    if [[ -z ${line} ]];then
		break
	    fi
	    read -ra line_sep <<< ${line}
	    subdirs[${i}]=${line_sep[1]}
	    branches[${i}]=$(sed 's/(\(.*\)\/\(.*\))/\2/' <<<${line_sep[2]})
	    i=$[i+1]
	done <<< $(git submodule)
	popd > /dev/null
	#######################################
	
	if (( ${i} != 0 ));then
	    stack_ptr=$[stack_ptr+1]
	    index=$[i-1]
	    stack_subdirs[${stack_ptr}]=${subdirs[@]}
	    stack_branches[${stack_ptr}]=${branches[@]}
	    stack_index[${stack_ptr}]=${index}
	    pushd ${subdir} > /dev/null
	fi
    else
	stack_ptr=$[stack_ptr-1]
	if (( ${stack_ptr} >= 0 )) ;then
	    popd > /dev/null
	else
	    break
	fi
    fi
done
