#!/bin/bash

# while [ $# -gt 0 ]; do
# 	key=$1
# 	shift
# 	val=$1
# 	shift
# 	echo "$key : $val"
# done >/tmp/mon.log

readonly 
readonly THUNDERBIRD=$(find "${HOME}" -name ".thunderbird")

readonly PROF_NAME=$1
shift

prof_name() {
	awk -v p="${PROF_NAME}"
	'BEGIN {
		RS="\n\n"
		FS="[\n=]"
	}
	$0 ~ "Name=" p {
		for (i = 1; i <= NF; i++)
			if ($i == "Path") {
				print $(i+1)
				exit
			}
		}
	' "${THUNDERBIRD}/profiles.ini"
}

readonly PROF_PATH="${THUNDERBIRD}/$(prof_name)"

i=1

while [ $i -le $# ]; do
	eval echo "$((i+1)) \${$i} : \${$((i+1))}"
	i=$((i+2))
done >>/tmp/mon.log

for i in $@; do
	echo -n "$i - "
done >>/tmp/mon.log

echo "==========" >>/tmp/mon.log

# sed ':a s/\r//g; /=$/{N; s/=\n//; ta}' test-mail | awk -f mail.awk