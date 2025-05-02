#!/usr/bin/bash

ppm=$1
txt=${ppm%.ppm}.txt
echo $ppm $txt

chr=#

printf "\e[0;0H;\e[2J"
state=0
IFS_PUSH=$IFS
IFS=`printf '\n\r'`

#image=`printf "\e[0;0H"`
image=`printf "\n\r"`

x=0
y=0
c=0
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
	    pixel=''
	    pixel_f=''
	    pixel_b=''
	    IFS=`printf ' \n\r'`
	    for j in $i;do
		c=$[c+1]
		pixel=${pixel}';'$j
		pixel_f=${pixel_f}';'$[j>255?255:j]
		pixel_b=${pixel_b}';'$[j]
		if [ "${c}" == "3" ];then
		    #pixel=${pixel}
		    #image=${image}`printf '\e[38;2'$pixel'm''\e[48;2'$pixel'm'${chr}`
		    image=${image}`printf '\e[38;2'${pixel_f}'m''\e[48;2'${pixel_b}'m'${chr}`
		    #image=${image}`printf '\e[48;2'$pixel'm'${chr}`
		    #image=${image}`printf '\e[38;2'$pixel'm'${chr}`
		    pixel=''
		    pixel_f=''
		    pixel_b=''
		    c=0
		    x=$[x+1]
		    if [ "${x}" == "${width}" ];then
			x=0
			image=${image}`printf '\e[0m\n\r'`
		    fi
		fi
	    done
	    IFS=`printf '\n\r'`
	;;
    esac
done
    
IFS=$IFS_PUSH
echo "${image}" > ${txt}
cat ${txt}
#printf "\e[0;0H"

