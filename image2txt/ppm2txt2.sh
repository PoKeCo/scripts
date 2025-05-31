#!/usr/bin/bash

ppm=$1
txt=${ppm%.ppm}.txt
echo $ppm $txt

chr="▀"

#printf "\e[0;0H;\e[2J"
state=0
IFS_PUSH=$IFS
IFS=`printf '\n\r'`

#image=`printf "\e[0;0H"`
image=`printf "\n\r"`

idx=0
declare -A data
for i in `cat ${ppm}`;do

    if [ "${i:0:1}" == "#" ];then
	continue
    fi
    case ${state} in
	0)
	    if [ "${i}" == "P3" ];then
		state=1
	    fi
	;;
	1)
	    width=`echo $i | awk '{printf $1}'`
	    height=`echo $i | awk '{printf $2}'`
	    state=2
	;;
	2)
	    depth=$i
	    state=3
	;;
	*)
	    IFS=`printf ' \n\r'`
	    for j in $i;do
		data[${idx}]=$j
		idx=$[idx+1]
	    done
	;;
    esac
done
echo $idx

IFS=$IFS_PUSH

if [ -f ${txt} ] ; then
    rm ${txt}
fi

for (( y=0; y<$[height-1] ; y+=2 ));do
    for (( x=0; x<${width} ; x++));do
	even_idx=$[3*(width*(y+0)+x)]
	odd_idx=$[3*(width*(y+1)+x)]
	re=${data[$[even_idx+0]]}
	ge=${data[$[even_idx+1]]}
	be=${data[$[even_idx+2]]}
	ro=${data[$[odd_idx+0]]}
	go=${data[$[odd_idx+1]]}
	bo=${data[$[odd_idx+2]]}
	printf '\e[38;2;'${re}';'${ge}';'${be}'m\e[48;2;'${ro}';'${go}';'${bo}'m'${chr} >> ${txt}
    done
    printf '\e[0m\n\r' >> ${txt}
done

#echo "${image}" > ${txt}
cat ${txt}

#printf "\e[0;0H"

