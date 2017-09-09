#!/usr/bin/env bash

LG_ALL=C
LANG=C
set -eo pipefail

function main()
{
    readonly NAME=$(basename $0)

    ## existing monitor info
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
    local _REZ=${1}
    local _SIDE=${2}
    local _PORT=${3}
    local _OUTPUT=${4}

    if [[ ! -z ${_TBL_PASSWD// } ]]
    then
        local _PASSWD="-passwd ${_TBL_PASSWD}"
    fi

    _CLIP_TEST=()
    declare -r _CLIP_TEST=($(\
        xrandr \
        | awk '/VIRTUAL1.connected/ {print $3}' \
        | cut -d"x" -f1))

    if [[ "${_SIDE}" == "right" ]] && [[ "${_OUTPUT}" == "VIRTUAL1" ]]
    then
        _CLIP=${_EX_MNTR_HREZ}
    elif [[ ${#_CLIP_TEST[@]} -eq 1 ]]
    then
        _SCRP=${_CLIP_TEST[0]}
        _CLIP=$((_SCRP+_EX_MNTR_HREZ))
    else
        _CLIP=0
    fi

    #### modeline and name
    local _MD=$(cvt ${_REZ%%x*} ${_REZ##*x} \
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
        --addmode ${_OUTPUT} ${_MD_NAME}
    ## set the mode
    xrandr \
        --auto \
        --output ${_OUTPUT} \
        --mode ${_MD_NAME} \
        --${_SIDE}-of ${_EX_MNTR_NAME}
    ## _start x11vnc
    x11vnc \
        -display :0 \
        -clip ${_REZ}+${_CLIP}+0 \
        -rfbport ${_PORT} \
        -quiet \
        -viewonly \
        ${_PASSWD} \
        2>/dev/null 1>&2 &

    printf "%s\n" \
        "${_OUTPUT} configured ${_SIDE} of ${_EX_MNTR_NAME} on port ${3}"
}

function _stop()
{
    ## reset display
    xrandr \
        -s 0

    ## find and kill all instances of x11vnc
    _KILL=()
    declare -r _KILL=($(\
        ps -ef \
        | grep x11vnc \
        | grep -v grep \
        | awk '{print $2}'))

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
        | grep -E 'VIRTUAL[1-2].connected' -A 1 \
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

function usage()
{

    ## usage / description / help
    clear
    echo -e "
    NAME
        ${NAME} - enables tablets as external monitors

    SYNOPSIS
        ${NAME} [-1, -2, -h, -H, --help]
                [-p passwd ,-P passwd ,--password=<passwd>]
                [-l or -L <####x####>, --left=<####x####>]
                [-r or -R <####x####>, --right=<####x####>]
                [-m or -M <####x####>, --resolution=<####x####>]
                [-x,-X,-q,-Q,--exit,--quit,--stop]
                [-s <side>, -S <side>, --side=<side>]

    DESCRIPTION
        This script will convert either one or two devices into external
        monitors using xrandr, x11vnc, and a vnc client.

        This was tested with linux on a couple of different tablets (android)
        and cell phones (android also).

    OPTIONS
        -1
            This option specifies one tablet. Has to be used in conjunction
            with:
                [-m <####x####>, -M <####x####>, --resolution=<####x####>]
            and:
                [-s <side>, -S <side>, --side=<side>]

        -2
            This option specifies two tablets. Has to be used in conjunction
            with:
                [-l <####x####>, -L <####x####>, --left=<####x####>]
            and:
                [-r <####x####>, -R <####x####>, --right=<####x####>]

        -p <passwd>, -P <passwd>, --password=<passwd>
            This option sets a password to be used in the VNC client. Does
            not need to be used but should be so you don't get stray
            connections.

        -l <####x####>, -L <####x####>, --left=<####x####>
            This option sets the resolution for the left tablet in the format
            of \"####x####\". Needed when the [-2] option specified.

        -r <####x####>, -R <####x####>, --right=<####x####>
            This option sets the resolution for the right tablet in the format
            of \"####x####\". Needed when the [-2] option specified.

        -m <####x####>, -M <####x####>, --resolution=<####x####>
            This option sets the resolution for the tablet in the format
            of \"####x####\". Needed when the [-1] option specified.

        -s <side>, -S <side>, --side=<side>
            This option specifies which side the individual tablet will
            display on.
            This option is only used with [-1]

        -x, -X, -q, -Q, --exit --quit, --stop
            This option stops the running processes.
            They are all the same option.

        -h, -H, --help
            This help file.

    NOTES

    EXAMPLES



    "


}
#### input section from here on down ####
#### be weary, there be dragons...   ####

clear

## check if xrandr && x11vnc exists
declare -r _LIST=( xrandr x11vnc )
for ITER in "${_LIST[@]}"
do
    command -v ${ITER} >/dev/null 2>&1 \
        || { printf "%s\n" "${ITER} not found. . ." >&2; \
        exit 1; }
done

## check if there is input at runtime to start {non-,}interactive
if [[ $# -eq 0 ]]
then
    printf "%s\n" \
        "how many monitors [1-2] or exit running process by pressing [x]"
    read -p '[1-2, x]: ' _TBL_CNT

    printf "%s\n"  \
        "Tablet resolutions in format ####x####"

    if [[ ${_TBL_CNT// } -eq 2 ]]
    then
        read -p 'left resolution: ' _TBL_LEFT
        read -p 'right resolution: ' _TBL_RGHT
        printf "%s\n" \
            "Should we set a password (leave blank for none) ?"
        read -sp 'leave blank for none: ' _TBL_PASSWD
        printf "\n"
        main
        _start ${_TBL_LEFT// } left 5900 VIRTUAL1
        _start ${_TBL_RGHT// } right 5901 VIRTUAL2
    elif [[ ${_TBL_CNT// } -eq 1 ]]
    then
        read -p 'resoultion: ' _TBL_REZ
        read -p 'left or right of monitor [left or right]: ' _TBL_SIDE
        printf "%s\n" \
            "Should we set a password (leave blank for none) ?"
        read -sp 'leave blank for none: ' _TBL_PASSWD
        printf "\n"
        main
        _start ${_TBL_REZ// } ${_TBL_SIDE// } 5900 VIRTUAL1
    elif [[ "${_TBL_CNT// }" == "x" ]] || [[ "${_TBL_CNT// }" == "X" ]]
    then
        _stop
        exit 0
    else
        printf "%s\n" \
            "Invalid input"
        exit 1
    fi
else
    ## option selection
    OPTCHAR="12hHl:L:m:M:p:P:qQr:R:s:S:xX-:"
    while getopts "${OPTCHAR}" OPT
    do
        case "${OPT}" in
            '-')
                case "${OPTARG}" in
                    help=*)
                        usage \
                            | less
                        exit 0
                        ;;
                    left=*)
                        _VAL=${OPTARG#*=}
                        _TBL_LEFT=${_VAL}
                        ;;
                    password=*)
                        _VAL=${OPTARG#*=}
                        _TBL_PASSWD=${_VAL}
                        ;;
                    resolution=*)
                        _VAL=${OPTARG#*=}
                        _TBL_REZ=${_VAL}
                        ;;
                    right=*)
                        _VAL=${OPTARG#*=}
                        _TBL_RGHT=${_VAL}
                        ;;
                    side=*)
                        _VAL=${OPTARG#*=}
                        _TBL_SIDE=${_VAL}
                        ;;
                    'exit'|'quit'|'stop')
                        _stop
                        exit 0
                        ;;
                    *)
                        usage \
                            | less
                        exit 0
                        ;;
                esac
                ;;
            '1')
                _SCRPT_MODE=1
                ;;
            '2')
                _SCRPT_MODE=2
                ;;
            'h'|'H')
                usage \
                    | less
                exit 0
                ;;
            'l'|'L')
                _TBL_LEFT=${OPTARG}
                ;;
            'm'|'M')
                _TBL_REZ=${OPTARG}
                ;;
            'p'|'P')
                _TBL_PAWWD=${OPTARG}
                ;;
            'r'|'R')
                _TBL_RGHT=${OPTARG}
                ;;
            's'|'S')
                _TBL_SIDE=${OPTARG}
                ;;
            'x'|'X'|'q'|'Q')
                _stop
                exit 0
                ;;
            *)
                usage \
                    | less
                exit 0
                ;;
        esac
    done
    if [[ ${OPTIND} -eq 1 ]]
    then
        usage \
            | less
        exit 0
    fi
    shift $((OPTIND-1))
fi

if [[ ${_SCRPT_MODE} -eq 2 ]]
then
    if [[ -z ${_TBL_LEFT} ]] || [[ -z ${_TBL_RGHT} ]]
    then
        printf "%s\n" \
            "missing resolution(s)"
    else
        main
        _start ${_TBL_LEFT// } left 5900 VIRTUAL1
        _start ${_TBL_RGHT// } right 5901 VIRTUAL2
    fi
elif [[ ${_SCRPT_MODE} -eq 1 ]]
then
    if [[ -z ${_TBL_REZ} ]] || [[ -z ${_TBL_SIDE} ]]
    then
        printf "%s\n" \
            "Missing either [-m] or [-s]"
    else
        main
        _start ${_TBL_REZ// } ${_TBL_SIDE// } 5900 VIRTUAL1
    fi
else
    printf "%s\n" \
        "Option(s) not set"
fi
