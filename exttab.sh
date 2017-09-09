#!/usr/bin/env bash

LG_ALL=C
LANG=C
set -eo pipefail
readonly NAME=$(basename $0)

source shlib/main.shlib
source shlib/start.shlib
source shlib/stop.shlib
source shlib/usage.shlib
source shlib/selection.shlib
