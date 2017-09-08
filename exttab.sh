#!/usr/bin/env bash

LG_ALL=C
LANG=C

function main()
{
    set -eo pipefail
    readonly NAME=$(basename $0)

    #### existing monitor info
    readonly _EX_MNTR=$(xrandr \
        | grep "connected primary")

    if (( $(grep -c . <<<"${_EX_MNTR}") < 2 ))
    then
        readonly _EX_MNTR_NAME=$(echo ${_EX_MNTR} \
            | awk '{print $1}')
        readonly _EX_MNTR_REZ=$(echo ${_EX_MNTR} \
            | awk '{print $4}')
        readonly _EX_MNTR_HREZ=${_EX_MNTR_REZ%%x*}
    else
        printf "%s\n" "Check xrandr.. multiple existing displays"
        exit 1
    fi

    trap _stop 1 2 3 9 15 SIGINT INT
}

function _start()
{
    local _DSPL=${1}
    local _LREZ=${2}
    local _LHREZ=${_LREZ%%x*}
    local _1_OUTPUT=VIRTUAL1
    local _1_PORT=5900
    local _2_PORT=5901

    if [[ ! -z ${_TBL_PASSWD// } ]]
    then
        _PASSWD="-passwd ${_TBL_PASSWD}"
    fi

    if [[ ${_DSPL} -eq 2 ]]
    then
        local _RREZ=${3}
        local _RHREZ=${_RREZ%%x*}
        local _2_OUTPUT=VIRTUAL2
    else
        local _1_SIDE=${3}
    fi

    if [[ "${_1_SIDE}" == "right" ]]
    then
        _CLIP=${_EX_MNTR_HREZ}
    else
        _CLIP=0
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
    ## _start x11vnc
    x11vnc \
        -display :0 \
        -clip ${_LREZ}+${_CLIP}+0 \
        -rfbport ${_1_PORT} \
        -quiet \
        -viewonly \
        ${_PASSWD} \
        2>/dev/null 1>&2 &

    if [[ ${_DSPL} -eq 2 ]]
    then
        local _MD=$(cvt ${_RREZ%%x*} ${_RREZ##*x} \
            | tail -n 1 \
            | sed -e 's/Modeline //')
        local _MD_NAME=$(echo ${_MD} \
            | cut -d" " -f1)
        local _MD_MODE=$(echo ${_MD} \
            | cut -d" " -f2-100)
        xrandr \
            --newmode ${_MD_NAME} ${_MD_MODE}
        xrandr \
            --addmode ${_2_OUTPUT} ${_MD_NAME}
        xrandr \
            --auto \
            --output ${_2_OUTPUT} \
            --mode ${_MD_NAME} \
            --right-of ${_EX_MNTR_NAME}
        x11vnc \
            -display :0 \
            -clip ${_RREZ}+$((_LHREZ+_EX_MNTR_HREZ))+0 \
            -rfbport ${_2_PORT} \
            -quiet \
            -viewonly \
            ${_PASSWD} \
            2>/dev/null 1>&2 &
    fi

    ## show xrandr
    clear
    xrandr
}

function _stop()
{
    ## reset display
    xrandr \
        -s 0

    ## find and kill all instances of x11vnc
    declare -r _KILL=($(\
        ps -ef \
        | awk '/x11vnc/ {print $2}'))

    for ITER in "${_KILL[@]}"
    do
        kill -9 ${ITER} 2> /dev/null
    done

    ## find all output modes named 'VIRTUAK.*'
    _EX_OUT_OFF=()
    declare -r _EX_OUT_OFF=($(\
        xrandr \
        | grep -i 'VIRTUAL.* connected' \
        | awk '{print $1"-"$3}' \
        | tac \
        | cut -d"+" -f1))

    ## disable output
    for ITER in "${_EX_OUT_OFF[@]}"
    do
        xrandr \
            --output ${ITER%%-*} \
            --off
    done

    ## find non connected modes named 'VIRTUAL[1-2]'
    _EX_OUT_RM=()
    declare -r _EX_OUT_RM=($(\
        xrandr \
        | grep -i 'VIRTUAL[1-2]' -A 1 \
        | awk '{print $1}' \
        | sed 'N;s/\n/ /' \
        | tr " " "-" \
        | sed 's/"//g' \
        | tac ))

    ## delete mode and remove name
    for ITER in "${_EX_OUT_RM[@]}"
    do
        xrandr \
            --delmode ${ITER%%-*} \"${ITER##*-}\"
        xrandr \
            --rmmode \"${ITER##*-}\"
    done

    ## hack fix - when cleaning up, keyboard repaet fails
    xset r on
    reset

    xrandr
}

clear

printf "%s\n" \
    "how many monitors [1-2] or exit running process by pressing [x]"
read -p '[1-2, x]: ' _TBL_CNT

printf "%s\n"  \
    "Tablet resolutions in format ####x####"

if [[ ${_TBL_CNT// } -eq 2 ]]
then
    read -p 'left resolution: ' _TBL_LEFT_REZ
    read -p 'right resolution: ' _TBL_RGHT_REZ
    printf "%s\n" \
        "Should we set a password (leave blank for none) ?"
    read -sp 'leave blank for none: ' _TBL_PASSWD
    main
    _start 2 ${_TBL_LEFT_REZ// } ${_TBL_RGHT_REZ// }
elif [[ ${_TBL_CNT// } -eq 1 ]]
then
    read -p 'resoultion: ' _TBL_REZ
    read -p 'left or right of monitor [left or right]: ' _TBL_SIDE
    printf "%s\n" \
        "Should we set a password (leave blank for none) ?"
    read -sp 'leave blank for none: ' _TBL_PASSWD
    main
    _start 1 ${_TBL_REZ// } ${_TBL_SIDE// }
elif [[ "${_TBL_CNT// }" == "x" ]] || [[ "${_TBL_CNT// }" == "X" ]]
then
    _stop
    exit 0
else
    printf "%s\n" \
        "Invalid input"
    exit 1
fi
