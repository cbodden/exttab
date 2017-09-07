#!/usr/bin/env bash

LG_ALL=C
LANG=C

function main()
{
    set -eo pipefail
    readonly NAME=$(basename $0)

    #### existing monitor info
    _EX_MNTR=$(xrandr \
        | grep "connected primary")

    if (( $(grep -c . <<<"${_EX_MNTR}") < 2 ))
    then
        _EX_MNTR_NAME=$(echo ${_EX_MNTR} \
            | awk '{print $1}')
        _EX_MNTR_REZ=$(echo ${_EX_MNTR} \
            | awk '{print $4}')
        _EX_MNTR_HREZ=${_EX_MNTR_REZ%%x*}
    else
        echo "Check xrandr.. multiple existing displays"
        exit 1
    fi

    trap finish 1 2 3 9 15 SIGINT INT
}

function start()
{
    local _DSPL=${1}
    local _LREZ=${2}
    local _LHREZ=${_LREZ%%x*}
    local _1_OUTPUT=VIRTUAL1
    local _1_PORT=5900
    local _2_PORT=5901

    if [[ ${_DSPL} -eq 2 ]]
    then
        local _RREZ=${3}
        local _RHREZ=${_RREZ%%x*}
    else
        local _1_SIDE=${3}
        local _2_OUTPUT=VIRTUAL2
    fi

    #### modeline and name
    local _MD=$(cvt ${_LREZ%%x*} ${_LREZ##*x} \
        | tail -n 1 \
        | sed -e 's/Modeline //')
    local _MD_NAME=$(echo ${_MD} \
        | cut -d" " -f1)
    local _MD_MODE=$(echo ${_MD} \
        | cut -d" " -f2-100)

    ## create the new mode
    xrandr \
        --newmode ${_MD_NAME} ${_MD_MODE}
    ## add mode to display
    xrandr \
        --addmode ${_1_OUTPUT} ${_MD_NAME}
    ## set the mode
    xrandr \
        --auto \
        --output ${_1_OUTPUT} \
        --mode ${_MD_NAME} \
        --${_1_SIDE-left}-of ${_EX_MNTR_NAME}
    ## start x11vnc
    x11vnc \
        -display :0 \
        -clip ${_LREZ}+0+0 \
        -rfbport ${_1_PORT} \
        -quiet \
        2>/dev/null 1>&2 &

    if [[ ${_DSPL} -eq 2 ]]
    then
        local _MD=$(cvt ${_RREZ%%x*} ${_RREZ##*x} \
            | tail -n 1 \
            | sed -e 's/Modeline //')
        local _MD_NAME=$(echo ${_MD_2} \
            | cut -d" " -f1)
        local _MD_MODE=$(echo ${_MD_2} \
            | cut -d" " -f2-100)
        xrandr \
            --newmode ${_MD_NAME} ${_MD_MODE}
        xrandr \
            --addmode ${_2_OUTPUT} ${_MD_NAME}
        xrandr \
            --auto \
            --output ${_2_OUTPUT} \
            --mode ${_MD_NAME} \
            --right-of ${EX_MNTR_NAME}
        x11vnc \
            -display :0 \
            -clip ${_RREZ}+$((_LHREZ+_EX_MNTR_HREZ))+0 \
            -rfbport ${_2_PORT} \
            -quiet \
            2>/dev/null 1>&2 &
    fi

    ## show xrandr
    clear
    xrandr
}

function stop()
{
    ## reset display
    xrandr \
        -s 0

    ## kill x11vnc
    for _KILL in $(ps -ef | grep x11vnc | awk '{print $2}')
    do
        kill -9 ${_KILL} 2> /dev/null
    done

    ## disable output
    xrandr \
        --output ${_TB_1_OUTPUT} \
        --off
    xrandr \
        --output ${_TB_2_OUTPUT} \
        --off

    ## delete mode
    xrandr \
        --delmode ${_TB_1_OUTPUT} ${_MD_1_NAME}
    xrandr \
        --delmode ${_TB_2_OUTPUT} ${_MD_2_NAME}

    ## remove name
    xrandr \
        --rmmode ${_MD_1_NAME}
    xrandr \
        --rmmode ${_MD_2_NAME}

    ## weird hack fix - sometimes when cleaning up, keyboard repaet
    ## fails so needed this until i debug
    xset r on

    ## show xrandr
    clear
    xrandr
}

clear

echo "how many monitors [1-2] or exit running process [0]"
read -p '[0-2]: ' _TBL_CNT

if [[ ${_TBL_CNT} -eq 2 ]]
then
    echo "Tablet resolutions in format ####x####:"
    read -p 'left resolution: ' _TBL_LEFT_REZ
    read -p 'right resolution: ' _TBL_RGHT_REZ
    main
    start 2 ${_TBL_LEFT_REZ} ${_TBL_RIGHT_REZ}
elif [[ ${_TBL_CNT} -eq 1 ]]
then
    echo "Tablet resolution in format #####x#####"
    read -p 'resoultion: ' _TBL_REZ
    read -p 'left or right of monitor [l or r]: ' _TBL_SIDE
    main
    start 1 ${_TBL_REZ} ${_TBL_SIDE}
elif [[ ${_TBL_CNT} -eq 0 ]]
then
    stop
    exit 0
else
    echo "Invalid input"
    exit 1
fi


### save for later
##function _10()
##{
##    local _TMP_10=$(mktemp --tmpdir ${NAME}_10_$$-XXXX.tmp)
##    declare TMP_XVF_10=${_TMP_10}
##
##    local export DISPLAY=:100
##
##    Xvfb :100 -screen 0 ${TEN}x16 &
##    echo $! >> ${TMP_XVF_10}
##
##    xterm -display :100 -maximized -fa 9x15 -e glances &
##    echo $! >> ${TMP_XVF_10}
##
##    x11vnc -display :100 -noshm -nocursor  -ncache 10 -rfbport 5900
##    echo $! >> ${TMP_XVF_10}
##}
##
##function _07()
##{
##    local _TMP_07=$(mktemp --tmpdir ${NAME}_07_$$-XXXX.tmp)
##    declare TMP_XVF_07=${_TMP_07}
##
##    local export DISPLAY=:200
##    export NMON=mndck
##
##    Xvfb :200 -screen 0 ${SEVEN}x16 &
##    echo $! >> ${TMP_XVF_07}
##
##    xterm -display :200 -geometry 80x54+0+0 -fa 4x6 -e nmon &
##    echo $! >> ${TMP_XVF_07}
##
##    xterm -display :200 -geometry 79x27-0+0 -fa 4x6 -e ttyload &
##    echo $! >> ${TMP_XVF_07}
##
##    xterm -display :200 -geometry 79x27-0-0 -fa 4x6 -e ttysys m &
##    echo $! >> ${TMP_XVF_07}
##
##    x11vnc -display :200 -noshm -nocursor  -ncache 10 -rfbport 5901
##    echo $! >> ${TMP_XVF_07}
##}
