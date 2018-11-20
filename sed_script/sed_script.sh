#!/bin/bash

# set -x
readonly FMT_FILE=format_list.sh
source "${FMT_FILE}"

# This function generates the replacement string for sed, assuming it replaces
# one regex group '()'
# $1 : color code
# $2 : text formatting
color() {
	local color=${1:-${C_DEFAULT}}
	local fmt="${2:-${F_DEFAULT}}"
	printf "\\\\x1B[%s;38;5;%dm\\\\1\\\\x1B[m" "${fmt}" "${color}"
}

# Definition of all the lists and their format :
# LIST=
# *_L : list for * regex
# *_LF : list for * regex flags (see sed substitute flags)
# *_C : color for * list
# *_F : format for * list
# *_O : order for * list
load_cf() {
	LIST=""

	# ERROR list
	LIST+="ERR "; ERR_L="error|warning|No such file or directory"; ERR_C=C_RED; ERR_F=; ERR_LF="Ig"; ERR_O=99
	# COMMON list
	LIST+="CMN "; CMN_L="make\[[0-9]*]"; CMN_C=C_BLUE; CMN_F=F_BOLD
	# Test list
	LIST+="TST "; TST_L="jolitest"; TST_C=C_RED; TST_F=
	# Test list
	LIST+="TST2 "; TST2_L="jolitest2"; TST2_C=C_BLUE; TST2_F=F_BOLD

	LIST+="ERR2 "; ERR2_L="^.*([0-9]+:){2}[[:blank:]]*(error|warning):"; ERR2_C=C_RED; ERR2_F=F_BOLD; ERR2_LF="I"

	source $ADD_FILE
}


readonly SCRIPT_BASE=/tmp/sed_tail/scripts
readonly SCRIPT_FILE=$SCRIPT_BASE/script
readonly FMT_BASE=$SCRIPT_BASE/cf

sort_by_cf() {
	rm -rf ${FMT_BASE}
	local f l i c flags
	for i in $LIST; do
		eval l=\${${i}_L}
		eval c=\${${i}_C:-C_DEFAULT}
		eval f=\${${i}_O:-"00"}_\${${i}_F:-F_DEFAULT}
		eval flags=\${${i}_LF}
		mkdir -p $FMT_BASE/$c
		echo "$l" >>$FMT_BASE/$c/$f
		echo "$flags" >>$FMT_BASE/$c/$f.flags
	done
}

# This function will clean the file that contains the regexs, to create a single
# one, such as (regex1|regex2...)
# $1 : file to clean
clean_regex() {
	# Newline are converted to '|'
	# Sed : successives '|' are replaced by a single '|'
	# Leading and trailing '|' are deleted
	cat $1 | tr '\n' '|' | sed 's/|+/|/g; s/^|//; s/|$//'
}

# This function will clean the file that contains the flags given to the
# sed substitute command
# $1 : file for which the .flags will be treated
# ex : $1=F_DEFAULT -> cleans the F_DEFAULT.flags file
clean_flags() {
	local f=$1.flags
	cat $f | grep -o . | sort -u | tr -d '\n'
}

generate_script() {
	# set -x
	local c f file regex
	# Separator for the
	local sep s
	rm "$SCRIPT_FILE"
	find $FMT_BASE -type f -not -name "*.flags" | awk -F"/" '{print $0, $(NF-1), substr($NF,4)}' | \
	while read file c f; do
		# Search for an intelligent separator
		s=nothing
		for sep in "'" '"' "#" "," ":" "!" "$" "%" ";" "/"; do
			grep -q "$sep" $file || {
				s=$sep
				break
			}
		done
		if [ "$s" = "nothing" ]; then
			echo "Warning : there's no intelligent separator for the sed substitute."
			echo "Using '$s'"
		fi
		eval c=\$$c
		eval f=\$$f
		echo "s${s}($(clean_regex "$file"))${s}$(color $c $f)${s}$(clean_flags "$file")" >>"$SCRIPT_FILE"
	done
}

reload_engine() {
	local f
	load_cf
	sort_by_cf
	generate_script
	for f in "$@"; do
		[ -e "$f" ] || touch "$f"
	done
	tail -f "$@" | sed -rf "$SCRIPT_FILE"
}

reload_engine "$@"
set +x
