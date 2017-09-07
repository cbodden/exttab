#!/usr/bin/env bash

LG_ALL=C
LANG=C

function main()
{
    set -eo pipefail
    readonly NAME=$(basename $0)

    TEN="2560x1600"
    SEVEN="1920x1200"
    MON_REZ="2560x1600"
    _MODELINE=$(cvt ${MON_REZ%%x*} ${MON_REZ##*x} \
        | tail -n1 \
        | tr -d "\"" \
        | sed -e 's/_60.00//' -e 's/Modeline //' -e 's/^ //')

    _SM_MODE=$(echo ${_MODELINE} \
        | cut -d" " -f1)

    _LG_MODE=$(echo ${_MODELINE} \
        | cut -d" " -f2-100)

    trap finish 1 2 3 9 15 SIGINT INT
}

function start_mon()
{
    xrandr --newmode \"${_SM_MODE}\" ${_LG_MODE}
    xrandr --addmode VIRTUAL1 ${_SM_MODE}
    xrandr --auto --output VIRTUAL1 --mode ${_SM_MODE} --left-of eDP1
    x11vnc -clip ${_SM_MODE}
}

function reset_mon()
{
    xrandr -s 0
    xrandr --output VIRTUAL1 --off
    xrandr --delmode VIRTUAL1 ${_SM_MODE}
    xrandr --rmmode ${_SM_MODE}
}

function clean()
{
    if ls /tmp/ext.sh_* 1> /dev/null 2>&1
    then
        for _FCL in $(cat /tmp/ext.sh_*)
        do
            kill -9 ${_FCL} 2> /dev/null \
                || true
        done
        rm /tmp/ext.sh_*
    fi

    xrandr -s 0
    xrandr --output VIRTUAL1 --off
    xrandr --delmode VIRTUAL1 ${_SM_MODE}
    xrandr --rmmode ${_SM_MODE}

    exit 0
}

function _10()
{
    local _TMP_10=$(mktemp --tmpdir ${NAME}_10_$$-XXXX.tmp)
    declare TMP_XVF_10=${_TMP_10}

    local export DISPLAY=:100

    Xvfb :100 -screen 0 ${TEN}x16 &
    echo $! >> ${TMP_XVF_10}

    xterm -display :100 -maximized -fa 9x15 -e glances &
    echo $! >> ${TMP_XVF_10}

    x11vnc -display :100 -noshm -nocursor  -ncache 10 -rfbport 5900
    echo $! >> ${TMP_XVF_10}
}

function _07()
{
    local _TMP_07=$(mktemp --tmpdir ${NAME}_07_$$-XXXX.tmp)
    declare TMP_XVF_07=${_TMP_07}

    local export DISPLAY=:200
    export NMON=mndck

    Xvfb :200 -screen 0 ${SEVEN}x16 &
    echo $! >> ${TMP_XVF_07}

    xterm -display :200 -geometry 80x54+0+0 -fa 4x6 -e nmon &
    echo $! >> ${TMP_XVF_07}

    xterm -display :200 -geometry 79x27-0+0 -fa 4x6 -e ttyload &
    echo $! >> ${TMP_XVF_07}

    xterm -display :200 -geometry 79x27-0-0 -fa 4x6 -e ttysys m &
    echo $! >> ${TMP_XVF_07}

    x11vnc -display :200 -noshm -nocursor  -ncache 10 -rfbport 5901
    echo $! >> ${TMP_XVF_07}
}

function finish()
{
    if ls /tmp/ext.sh_* 1> /dev/null 2>&1
    then
        for _CLEAN in $(cat ${TMP_XVF_10} ${TMP_XVF_07})
        do
            if ps -p ${_CLEAN} > /dev/null
            then
                kill -9 ${_CLEAN} 2> /dev/null \
                    || true
            fi
        done
        rm ${TMP_XVF_10} ${TMP_XVF_07}
    fi

    xrandr -s 0
    xrandr --output VIRTUAL1 --off
    xrandr --delmode VIRTUAL1 ${_SM_MODE}
    xrandr --rmmode ${_SM_MODE}

    exit 0
}


echo "how many monitors [1-2] or exit running process [0]"
read -p '[0-2]: ' _TBL_CNT

if [[ ${_TBL_CNT} -eq 2 ]]
then
    echo "Tablet resolutions in format ####x####:"
    read -p 'left resolution: ' _TBL_LEFT_REZ
    read -p 'right resolution: ' _TBL_RGHT_REZ
    main
    tablet 2 ${_TBL_LEFT_REZ} ${_TBL_RIGHT_REZ}
elif [[ ${_TBL_CNT} -eq 1 ]]
then
    echo "Tablet resolution in format #####x#####"
    read -p 'resoultion: ' _TBL_REZ
    read -p 'left or right of monitor [l or r]: ' _TBL_SIDE
    main
    tablet 1 ${_TBL_REZ} ${_TBL_SIDE}
elif [[ ${_TBL_CNT} -eq 0 ]]
then
    finish
else
    echo "Invalid input"
    exit 1
fi



main

if [[ "${_IN}" == "start_mon" || "${_IN}" == "reset_mon" ]]
then
    if declare -f ${_IN} > /dev/null
    then
        start_mon
        ${_IN}
    fi
else
    if declare -f ${_IN} > /dev/null
    then
        ${_IN}
    else
        echo "Wrong input"
    fi
fi
