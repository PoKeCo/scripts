#!/usr/bin/bash

#############################################
# Backup Script
#############################################
# USAGE : ./bkup.sh [directory_name]
#
# This script creates (name)_(date).tar.gz file 
#


#If argument is specified, then set the src name
if [ ! -z $1 ];then
    src=$1
else
    echo "USAGE : bkup.sh dir sfx"
    return
fi

#Set suffix
src_dir=`readlink -f $src`
echo $src_dir
branch_name=''
if [ -d $src_dir ];then
    pushd $src_dir > /dev/null
    branch=`git branch --show-current`
    ret=$?
    if [ $ret == 0 ];then
	branch_name=_$branch
    fi
    echo $branch_name 
    popd > /dev/null
fi


sfx="m"

if [ ! -z $2 ];then
    sfx=$2
fi

echo $src, $branch_name

#CAUTION : Auto delete created file 
#for i in `find ./$src -name 'devel' -type d `;do
#    echo CAUTION:Remove ROS created file\(s\): $i
#    rm -r $i
#done
#for i in `find ./$src -name 'build' -type d `;do
#    echo CAUTION:Remove ROS created file\(s\): $i
#    rm -r $i
#done

#Create the .tar.gz file 
now=`date +%y%m%d_%H%M%S`

dst=${src}_${now}${branch_name}_${sfx}.tar.gz
cmd="tar zcvf $dst $src"
echo $cmd
$cmd

#Show tar file size
du -sm $dst
