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
    GRAY=`printf "\e[38;2;128;128;128m"` # You can specify R,G,B
    DGRAY=`printf "\e[38;2;64;64;64m"` # You can specify R,G,B
    
    NORM=`printf "\e[0m"` # Return to default color
    
    CLS=`printf "\e[2J"` # CLear Screen
    CLL=`printf "\e[2K"` # CLear Line
    LOCATE_0_0=`printf "\e[0;0H"` # Locate cursor position to 0[raw],0[col]
}

function run_core(){
    local branch_rel=()
    local branch_dev=()
    local branch_f=()
    local branch=()
    
    branch_list=$(git branch -r --points-at ${commit_id}| grep -v HEAD | sed 's%  origin/\(.*\)%\1%')
    while IFS= read -r branch;do
	case ${branch} in
	    rel-*)
		branch_rel=${branch}
		;;
	    dev-*)
		branch_dev=${branch}
		;;
	    f-*)
		branch_f=${branch}
		;;
	esac
    done <<<${branch_list}


    printf "${GRAY}"
    if   [[ ! -z "${branch_rel}" ]];then
	cmd="git switch ${branch_rel}"
    elif [[ ! -z "${branch_dev}" ]];then
	cmd="git switch ${branch_dev}"
    elif [[ ! -z "${branch_f}" ]];then
	cmd="git switch ${branch_f}"
    else
	cmd=echo
	echo -e "${RED}No branch found:Detached HEAD${NORM}"
    fi
    while IFS= read -r message;do
	if [[ "${message}" ==  *'Switched to branch'* ]];then
	    printf "${CYAN}"
	elif [[ "${message}" ==  *'Switched to a new branch'* ]];then
	    printf "${GREEN}"
	elif [[ "${message}" ==  *'Already on'* ]];then
	    printf "${GRAY}"
	else
	    printf "${RED}"
	fi
	printf "${message}\n"
    done <<< $(${cmd} 2>&1 1>/dev/null )
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

declare -a commit_ids
declare -a stack_commit_ids
declare -a subdirs
declare -a stack_subdirs
declare -a branches
declare -a stack_branches
declare -a stack_index

stack_ptr=0
index=-1

printf "${GRAY}"
git submodule update
printf "${NORM}"

i=0
while read -r line ;do
    read -ra line_sep <<< ${line}
    commit_ids[${i}]=${line_sep[0]}
    subdirs[${i}]=${line_sep[1]}
    branches[${i}]=$(sed 's/(\(.*\)\/\(.*\))/\2/' <<<${line_sep[2]})
    i=$[i+1]
done <<< $(git submodule)
index=$[i-1]

stack_commit_ids[${stack_ptr}]=${commit_ids[@]}
stack_subdirs[${stack_ptr}]=${subdirs[@]}
stack_branches[${stack_ptr}]=${branches[@]}
stack_index[${stack_ptr}]=${index}

while true;do
    read -ra commit_ids <<< ${stack_commit_ids[${stack_ptr}]}
    read -ra subdirs  <<< ${stack_subdirs[${stack_ptr}]}
    read -ra branches <<< ${stack_branches[${stack_ptr}]}
    index=${stack_index[${stack_ptr}]}
    if (( ${index} >= 0 ));then
	commit_id=${commit_ids[$index]}
	subdir=${subdirs[$index]}
	branch=${branches[$index]}
	index=$[index-1]
	stack_index[${stack_ptr}]=$index
	#######################################
	pushd ${subdir} > /dev/null
	echo "Check: $(pwd)"
	run_core
	printf ${NORM}
	#######################################
	i=0
	while read -r line ;do
	    if [[ -z ${line} ]];then
		break
	    fi
	    read -ra line_sep <<< ${line}
	    commit_ids[${i}]=${line_sep[0]}
	    subdirs[${i}]=${line_sep[1]}
	    branches[${i}]=$(sed 's/(\(.*\)\/\(.*\))/\2/' <<<${line_sep[2]})
	    i=$[i+1]
	done <<< $(git submodule)
	popd > /dev/null
	#######################################
	
	if (( ${i} != 0 ));then
	    stack_ptr=$[stack_ptr+1]
	    index=$[i-1]
	    stack_commit_ids[${stack_ptr}]=${commit_ids[@]}
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
