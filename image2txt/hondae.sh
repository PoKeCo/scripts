#!/usr/bin/bash

#ppm=hondae2.ppm
#ppm=hondae_s.ppm
#ppm=hondae3d.ppm
ppm=hondae_move_01_s.ppm
#ppm=RGB.ppm
#ppm=mura.ppm

printf "\e[0;0H;\e[2J"
state=0
IFS_PUSH=$IFS
IFS=`printf '\n\r'`

image=`printf "\e[0;0H"`
#image=''

for i in `cat ${ppm}`;do
    case ${state} in
	0)
	    if [ "${i}" == "P3" ];then
		state=1
	    fi
	;;
	1)
	    state=2
	;;
	2)
	    width=`echo $i | awk '{printf $1}'`
	    height=`echo $i | awk '{printf $2}'`
	    state=3
	;;
	3)
	    depth=$i
	    x=0
	    y=0
	    c=0
	    state=4
	;;
	*)
	    pixel=''
	    IFS=`printf ' \n\r'`
	    for j in $i;do
		c=$[c+1]
		pixel=${pixel}';'$j
		if [ "${c}" == "3" ];then
		    pixel=${pixel}
		    image=${image}`printf '\e[38;2'$pixel'm''\e[48;2'$pixel'm..'`
		    #printf '\e[38;2'$pixel'm''\e[48;2'$pixel'm..'
		    pixel=''
		    c=0
		    x=$[x+1]
		    if [ "${x}" == "${width}" ];then
			x=0
			#image=${image}`printf "\n"`
			#image=${image}`printf ' \n\r'`
			image=${image}`printf '\e[0m\n\r'`
			#printf "\n"
		    fi
		fi
	    done
	    IFS=`printf '\n\r'`
	;;
    esac
done
    
IFS=$IFS_PUSH
#printf "${image}" |tee hondae.txt
#printf ${image} 
echo "${image}" > hondae.txt
cat hondae.txt
#printf "\e[0;0H"

