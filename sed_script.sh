#!/bin/bash

# set -x

# https://misc.flogisoft.com/bash/tip_colors_and_formatting
readonly COLOR_BLUE=31
readonly COLOR_MAGENTA=35
readonly COLOR_GREEN=34
readonly COLOR_ORANGE=208
readonly COLOR_RED=196
readonly C_MAKE=${COLOR_GREEN}

readonly COLOR_DEFAULT=${COLOR_GREEN}

# Format definitions
readonly FMT_NORMAL=0
readonly FMT_BOLD=1
readonly FMT_DIM=2
readonly FMT_UNDER=4
readonly FMT_BLINK=5
readonly FMT_INV=7

readonly FMT_DEFAULT=${FMT_NORMAL}
# $1 : color code
# $2 : text formatting
color() {
	local color=${1:-${COLOR_DEFAULT}}
	local fmt="${2:-${FMT_DEFAULT}}"
	printf "\\\\x1B[%s;38;5;%dm\\\\1\\\\x1B[m" "${fmt}" "${color}"
}

ERR_LIST="error;warning;"

init_lists() {
	local i list
	local ifs="$IFS"

	IFS=";"

	for i in ${ERR_LIST}; do
		list+="|$i"
	done
	ERR_LIST="(${list:1})"

	IFS=$ifs
}

init_lists
sed -r "
	# Highlights elements from ERR_LIST in red
	s/${ERR_LIST}/$(color $COLOR_RED)/gI
	# Highlights 'make[]' in blue
	s/^(make\[[0-9]*])/$(color $C_MAKE)/
	s/^(export.*)/$(color $COLOR_ORANGE $FMT_UNDER)/
" "$@"

# set +x
