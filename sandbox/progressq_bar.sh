#!/bin/bash

function set_escape_sequence(){
    RED=`printf "\e[31m"`
    GREEN=`printf "\e[32m"`
    YELLOW=`printf "\e[33m"`
    BLUE=`printf "\e[34m"`
    CYAN=`printf "\e[36m"`
    MAGENTA=`printf "\e[35m"`
    GRAY=`printf "\e[38;2;128;128;128m"` # You can specify R,G,B
    NORM=`printf "\e[0m"` # Return to default color

    CLS=`printf "\e[2J"` # CLear Screen
    CLL=`printf "\e[2K"` # CLear Line
    LOCATE_0_0=`printf "\e[0;0H"` # Locate cursor position to 0[raw],0[col]
}

set_escape_sequence
