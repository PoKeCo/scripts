#!/usr/bin/bash

img=$1
ppm=_${img%.*}_.ppm
mid=_${img%.*}_m_.ppm

size=`identify ${img} | awk '{print $3}' `
img_height=${size#*x}
img_width=${size%x*}

term_height=`tput lines`
term_width=`tput cols`

dst_height=${term_height}
dst_width=$[(dst_height*img_width)/img_height]
#dst_width=${term_width}
#dst_height=$[(dst_width*img_height)/(img_width*2)]

convert -resize "${dst_width}x${dst_height}!" -compress none ${img} ${mid}
python3 ppm_p6_to_p3.py ${mid} ${ppm}

./ppm2txt2.sh ${ppm}

