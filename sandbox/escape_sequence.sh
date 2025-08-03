#!/usr/bin/bash

echo "\en;mH = Jump to (n,m)"
echo "\e[2J = CLS all"

printf "\e[2J\e[0;0H"

i=ab/cd/ef
echo '$i= '$i
echo '${i#*/} = '${i#*/}
echo '${i##*/}= '${i##*/}
echo '${i%/*} = '${i%/*}
echo '${i%%/*}= '${i%%/*}

printf "\e[47m\e[30m"'\\e[30m'"\e[0m\n"
printf "\e[31m"'\\e[31m'"\e[0m\n"
printf "\e[32m"'\\e[32m'"\e[0m\n"
printf "\e[33m"'\\e[33m'"\e[0m\n"
printf "\e[34m"'\\e[34m'"\e[0m\n"
printf "\e[35m"'\\e[35m'"\e[0m\n"
printf "\e[36m"'\\e[36m'"\e[0m\n"
printf "\e[37m"'\\e[37m'"\e[0m\n"

printf "\e[40m"'\\e[40m'"\e[0m\n"
printf "\e[41m"'\\e[41m'"\e[0m\n"
printf "\e[42m"'\\e[42m'"\e[0m\n"
printf "\e[43m"'\\e[43m'"\e[0m\n"
printf "\e[44m"'\\e[44m'"\e[0m\n"
printf "\e[45m"'\\e[45m'"\e[0m\n"
printf "\e[46m"'\\e[46m'"\e[0m\n"
printf "\e[47m\e[30m"'\\e[47m'"\e[0m\n"

printf "\e[0m"'\\e[0m'"\e[0m\n"

printf "\e[1m"'\\e[1m(bold)'"\e[0m\n"
printf "\e[2m"'\\e[2m(thin)'"\e[0m\n"
printf "\e[3m"'\\e[3m(italic)'"\e[0m\n"
printf "\e[4m"'\\e[4m(under line)'"\e[0m\n"
printf "\e[5m"'\\e[5m(brink)'"\e[0m\n"
printf "\e[6m"'\\e[6m(brink fast)'"\e[0m\n"
printf "\e[7m"'\\e[7m(reverce)'"\e[0m\n"

printf "\e[38;2;128;255;128m hogehoge \e[0m\n"
printf "\e[48;2;128;255;128m hogehoge \e[0m\n"

