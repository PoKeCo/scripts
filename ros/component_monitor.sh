#!/bin/bash
printf "\e[2J;\e[0;0H"
while true;do
    ros2 component list
    printf "\e[2K\e[0;0H"
done
