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

function run_core(){
    echo ${subdir}
    git tag "${GIT_TAG}" -m "'${GIT_MESSAGE}'"
    git push origin "${GIT_TAG}"
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
	-t)
	    shift
	    GIT_TAG=$1
	    ;;
	-m)
	    shift
	    GIT_MESSAGE=$1
	    ;;
    esac
    shift
done

echo "${GIT_TAG} : ${GIT_MESSAGE}"

## Main

declare -a subdirs
declare -a stack_subdirs
declare -a branches
declare -a stack_branches
declare -a stack_index

stack_ptr=0
index=-1

GIT_TOP_LEVEL=$(git rev-parse --show-toplevel)

branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "${branch}" =~ ^rel-* ]];then
    printf "${CYAN}"
else
    printf "${YELLOW}"
fi
spaces=$(printf '%*s' $[2+stack_ptr*2] '')
dir_name=$(pwd|sed "s%${GIT_TOP_LEVEL}%%")
#printf  "%-50s %s${NORM}\n" "${spaces}${dir_name}" "${branch}"
printf  "%-50s %s${NORM}\n" "${GIT_TOP_LEVEL}" "${branch}"
run_core

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
stack_index[${stack_ptr}]=${index[@]}

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
	if [[ "${branch}" =~ ^rel-* ]];then
	    printf "${CYAN}"
	else
	    printf "${YELLOW}"
	fi
	spaces=$(printf '%*s' $[2+stack_ptr*2] '')
	dir_name=$(pwd|sed "s%${GIT_TOP_LEVEL}%%")
	printf  "%-50s %s${NORM}\n" "${spaces}${dir_name}" "${branch}" 
	run_core 
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
