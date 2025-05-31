#!/bin/bash

function show_help(){
    echo Usage: ${THIS_SCRIPT} [OPTION]
    echo This is template for generalized multi boot system
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
    # Usage: $(RGB <R> <G> <B>)
    printf "\e[38;2;%d;%d;%dm" $1 $2 $3
}

function BK_RGB(){
    # Usage: $(BK_RGB <R> <G> <B>)
    printf "\e[48;2;%d;%d;%dm" $1 $2 $3
}

function LOCATE(){
    # Usage: $(LOCATE <X> <Y>)
    printf "\e[%d;%dH" $1 $2
}

is_number() {
    local value="$1"
    if [[ "$value" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
	return 0 # 数値
    else
	return 1 # 数値ではない
    fi
}

function uuid_gen(){
    echo $(cat /proc/sys/kernel/random/uuid)
}

function prepare_ssh(){
    # Usage : prepare_ssh <ADDR>
    ADDR=$1
    ssh-keygen -f "/home/${USER}/.ssh/known_hosts" -R "${ADDR}" 
}

function ssh_exec(){
    # Usage : ssh_exec <ADDR> <USR> <PASS> <COMMAND>
    ADDR=$1
    USR=$2
    PASS=$3
    COMMAND=$4
    echo "${GREEN}${USR}@${ADDR}: ${CYAN}${COMMAND}${NORM}"
    sshpass -p ${PASS} ssh -o "StrictHostKeyChecking=no" -t ${USR}@${ADDR} -- "${COMMAND}"
}

function ssh_rsync(){
    # Usage : ssh_rsync <PASS> <SRC> <DST>
    PASS=$1
    SRC=$2
    DST=$3
    sshpass -p ${PASS} rsync -e "ssh -o StrictHostKeyChecking=no" -avzP ${SRC} ${DST}
}

function rexec(){
    # Usage : rexec <ADDR[@USR[@PASS]]> <COMMAND> 
    ADDR_USR_PASS="$1"    
    COMMAND="$2"
    IFS="@" read -ra ADDR_USR_PASS_ARRAY <<< "${ADDR_USR_PASS}"
    ADDR="${ADDR_USR_PASS_ARRAY[0]}"
    USR="${ADDR_USR_PASS_ARRAY[1]}"
    PASS="${ADDR_USR_PASS_ARRAY[2]}"
    if [ -z "${ADDR}" ] ; then
	read -p "${GREEN}target address:${NORM}" ADDR
    fi
    if [ -z "${USR}" ] ; then
	read -p "${GREEN}${ADDR}'s user:${NORM}" USR
    fi
    if [ -z "${PASS}" ] ; then
	read -sp "${GREEN}${USR}@${ADDR}'s password:${NORM}" PASS
	echo 
    fi
    echo "${GREEN}${USR}@${ADDR}: ${CYAN}${COMMAND}${NORM}"
    sshpass -p ${PASS} ssh \
	    -n \
	    -o "StrictHostKeyChecking=no" \
	    -t ${USR}@${ADDR} \
	    -- "${COMMAND}" 2> /dev/null
}

function lexec(){
    # Usage : lexec <WAIT_OPT> <COMMAND> 
    WAIT_OPT="$1"
    COMMAND="$2"
    ID=$(uuid_gen)
    DONE_FILE="/tmp/gnome_terminal_done_${ID}"
    RETURN_VALUE_FILE="/tmp/gnome_terminal_return_${ID}"
    WAIT_ICON=""
    if [ "${WAIT_OPT}" == "w" ];then
	WAIT_ICON="(w)"
    fi
    echo "${GLAY}[.]${GREEN}localhost${WAIT_ICON}: ${CYAN}${COMMAND}${NORM}"
    ${COMMAND}
    echo $? > ${RETURN_VALUE_FILE}
    touch ${DONE_FILE}
    while [[ (! -f "${DONE_FILE}") && ("${WAIT_OPT}" == "w")  ]]; do
	sleep 1
    done
    rm -f "${DONE_FILE}"
}

function setup_window_mode(){
    window_mode_="$1"
    case ${window_mode_} in
        "k")
            err_bash="bash"
            suc_bash="bash"
            ;;
        "e")
            err_bash="bash"
            suc_bash="exit"
            ;;
        "f")
            err_bash="exit"
            suc_bash="exit"
            ;;
        *)
            err_bash="bash"
            suc_bash="bash"
            ;;
    esac
}

function setup_wait_icon(){
    wait_opt_="$1"
    if [ "${wait_opt_}" == "w" ];then
	WAIT_ICON="(w)"
    fi
}

function gnome_terminal_rexec(){
    # Usage : gnome_terminal_rexec <WINDOW_MODE> <WAIT_OPT> <ADDR[@USR[@PASS]]> <COMMAND> [OPTION]
    WINDOW_MODE="$1"
    WAIT_OPT="$2"
    ADDR_USR_PASS="$3"
    COMMAND="$4"

    IFS="@" read -ra ADDR_USR_PASS_ARRAY <<< "${ADDR_USR_PASS}"
    ADDR="${ADDR_USR_PASS_ARRAY[0]}"
    USR="${ADDR_USR_PASS_ARRAY[1]}"
    PASS="${ADDR_USR_PASS_ARRAY[2]}"
    if [ -z "${ADDR}" ] ; then
	read -p "${GREEN}target address:${NORM}" ADDR
    fi
    if [ -z "${USR}" ] ; then
	read -p "${GREEN}${ADDR}'s user:${NORM}" USR
    fi
    if [ -z "${PASS}" ] ; then
	read -sp "${GREEN}${USR}@${ADDR}'s password:${NORM}" PASS
	echo 
    fi

    setup_window_mode ${WINDOW_MODE}
    setup_wait_icon ${WAIT_OPT}
    echo "${GLAY}[gnome_terminal]${GREEN}${USR}@${ADDR}${WAIT_ICON}: ${CYAN}${COMMAND}${NORM}"

    ID=$(uuid_gen)
    DONE_FILE="/tmp/gnome_terminal_done_${ID}"
    RETURN_VALUE_FILE="/tmp/gnome_terminal_return_${ID}"
    gnome-terminal --tab --title="${host_cmd}" -- bash -c "\
echo \"${GLAY}[gnome_terminal/tab]${GREEN}${USR}@${ADDR}${WAIT_ICON}: ${CYAN}${COMMAND}${NORM}\";\
sshpass -p ${PASS} ssh -o \"StrictHostKeyChecking=no\" -t ${USR}@${ADDR} -- '\
    echo \"${GLAY}[gnome_terminal/tab/ssh]: ${CYAN}${COMMAND}${NORM}\";\
        ${COMMAND};\
    BOOT_GENERAL_SUB_SHELL_ERR=\$?;\
    echo \"${GLAY}[gnome_terminal/tab/ssh]:DONE(error=\${BOOT_GENERAL_SUB_SHELL_ERR}) ${COMMAND}${NORM}\";\
    exit \${BOOT_GENERAL_SUB_SHELL_ERR};\
' 2> /dev/null;\
BOOT_GENERAL_SUB_SHELL_ERR=\$?;\
echo \${BOOT_GENERAL_SUB_SHELL_ERR} > ${RETURN_VALUE_FILE}
touch ${DONE_FILE};\
if [ \"\${BOOT_GENERAL_SUB_SHELL_ERR}\" -ne 0 ];then
    echo \"${RED}[gnome_terminal/tab]:ERROR(=\${BOOT_GENERAL_SUB_SHELL_ERR}) ${COMMAND}${NORM}\";\
    ${err_bash};\
else\
    echo \"${GLAY}[gnome_terminal/tab]:Succeed ${COMMAND}${NORM}\";\
fi;\
${suc_bash}"

    while [[ (! -f "${DONE_FILE}") && ("${WAIT_OPT}" == "w")  ]]; do
	sleep 1
    done
    rm -f "${DONE_FILE}"
}

function gnome_terminal_lexec(){
    # Usage : gnome_terminal_rexec <WINDOW_MODE> <WAIT_OPT> <COMMAND> [OPTION]
    WINDOW_MODE="$1"
    WAIT_OPT="$2"
    COMMAND="$3"
    
    setup_window_mode ${WINDOW_MODE}
    setup_wait_icon ${WAIT_OPT}
    echo "${GLAY}[gnome_terminal]${GREEN}localhost${WAIT_ICON}: ${CYAN}${COMMAND}${NORM}"

    ID=$(uuid_gen)
    DONE_FILE="/tmp/gnome_terminal_done_${ID}"
    RETURN_VALUE_FILE="/tmp/gnome_terminal_return_${ID}"
    gnome-terminal --tab --title="${host_cmd}" -- bash -c "\
echo \"${GLAY}[gnome_terminal/tab]${GREEN}${ADDR}${WAIT_ICON}: ${CYAN}${COMMAND}${NORM}\";\
${COMMAND};\
BOOT_GENERAL_SUB_SHELL_ERR=\$?;\
echo \${BOOT_GENERAL_SUB_SHELL_ERR} > ${RETURN_VALUE_FILE}
echo \"${GLAY}[gnome_terminal/tab]:DONE(error=\${BOOT_GENERAL_SUB_SHELL_ERR}) ${COMMAND}${NORM}\";\
touch ${DONE_FILE}
if [ \"\${BOOT_GENERAL_SUB_SHELL_ERR}\" -ne 0 ];then
    echo \"${RED}[gnome_terminal/tab]:ERROR(=\${BOOT_GENERAL_SUB_SHELL_ERR}) ${COMMAND}${NORM}\";\
    ${err_bash}
else
    echo \"${GLAY}[gnome_terminal/tab]:Succeed ${COMMAND}${NORM}\";\
fi;\
${suc_bash}"    
    while [[ (! -f "${DONE_FILE}") && ("${WAIT_OPT}" == "w")  ]]; do
	sleep 1
    done
    rm -f "${DONE_FILE}"
}

function show_finished_message(){
    printf '┌─────────────────────┐\n'
    printf '│                     │\n'
    printf '│ Recording completed │\n'
    printf '│                     │\n'
    printf '└─────────────────────┘\n'
}



## Prepare 
set_escape_sequence

SCRIPT_DIR=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
THIS_SCRIPT=$(basename ${BASH_SOURCE[0]})

IS_MASTER=1

## Parse Argument

while (( "$#" > 0 ));do
    arg=$1
    case ${arg} in
	--help)
	    show_help
	    exit 0
	    ;;
	--sub)
	    IS_MASTER=0
	    ;;
    esac
    shift
done

## Main

SEQUENCE_LIST=$(cat <<EOF
192.168.1.1@hoge@hoge;echo process 1;sleep 3:k:0
192.168.1.2@hoge@hoge;echo process 2;sleep 3:k:w
192.168.1.3@hoge@hoge;echo process 3;sleep 3:e:0
192.168.1.4@hoge@hoge;echo process 4;sleep 3:f:0
localhost;echo process 5;sleep 3:f:0
EOF
)

if [ "${IS_MASTER}" == "1" ];then
    gnome-terminal \
	--zoom=0.75 \
	--geometry=236x23-26+4 \
	--title="1st TAB" \
	-- bash -c "\
            ./${THIS_SCRIPT} --sub;\
            bash" 
       #--window-with-profile=boot_terminal \
else

    declare -A sequences
    declare -A hosts
    declare -A commands
    declare -A window_modes
    declare -A wait_opts
    seq_count=0
    while IFS= read -r sequence;do
	# Rid comment out
	sequence=${sequence%#*} 

	# Parse sequence
	IFS=":" read -ra host_command_wait_array <<< "${sequence}"
	host="${host_command_wait_array[0]}"
	command="${host_command_wait_array[1]}"
	window_mode="${host_command_wait_array[2]}"
	wait_opt="${host_command_wait_array[3]}"
	if [ -z "${command}" ];then
	    continue  # Skip invalid command
	fi
	sequences[$seq_count]="${sequence}"
	hosts[$seq_count]="${host}"
	commands[$seq_count]="${command}"
	window_modes[$seq_count]="${window_mode}"
	wait_opts[$seq_count]="${wait_opt}"
	seq_count=$[seq_count+1]
    done <<< "${SEQUENCE_LIST}"

    declare -A return_value_files
    for (( i=0; i<${seq_count}; i++ ));do

	host="${hosts[$i]}"
	command="${commands[$i]}"
	window_mode="${window_modes[$i]}"
	wait_opt="${wait_opts[$i]}"

	# Parse host
	IFS="@" read -ra addr_usr_pass_array <<< "${host}"
	addr="${addr_usr_pass_array[0]}"
	usr="${addr_usr_pass_array[1]}"
	pass="${addr_usr_pass_array[2]}"

	# Execute SSH Terminal
	prepare_ssh "${addr}" 1>/dev/null 2> /dev/null
	if [ "${addr}" == "." ];then
	    lexec "${wait_opt}" "${command}"
	    return_value_files[$i]=${RETURN_VALUE_FILE}
	elif [ "${addr}" == "localhost" ];then
	    gnome_terminal_lexec "${window_mode}" "${wait_opt}" "${command}" 
	    return_value_files[$i]=${RETURN_VALUE_FILE}
	else
	    gnome_terminal_rexec "${window_mode}" "${wait_opt}" "${host}" "${command}"
	    return_value_files[$i]=${RETURN_VALUE_FILE}
	fi

	# Wait 
	if is_number "${wait_opt}" ;then
	    if [[ "${wait_opt}"  != "0" ]];then
		echo "${GLAY}[.] Wait for ${wait_opt} sec ${NORM}"
		sleep ${wait_opt}
	    fi
	fi
    done

    ## SUMMARY #############################################################################
    sum_return_value=0
    summaly=""
    echo
    printf "${BLACK}$(BK_RGB 255 255 255) Summary ${NORM}\n"
    echo 
    echo " Err.: Sequence "
    for (( i=0; i<${seq_count}; i++ ));do
	while [ ! -f ${return_value_files[$i]} ];do
	    :
	done
	return_value=$(cat ${return_value_files[$i]})
	rm ${return_value_files[$i]}
	if (( return_value == 0 ));then
	    col=${GREEN}
	else
	    col=${RED}
	fi
	printf "${col}%4d : '${sequences[$i]}'${NORM}\n" "${return_value}"
	sum_return_value=$[sum_return_value+return_value]
    done
    
    if (( sum_return_value == 0 ));then
	gnome_terminal_lexec "k" "0" "./complete_bagrec.sh -d" 
    else
	gnome_terminal_lexec "k" "0" "./complete_bagrec.sh -e"
    fi
    
    
fi
