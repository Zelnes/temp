#!/bin/bash

# while [ $# -gt 0 ]; do
# 	key=$1
# 	shift
# 	val=$1
# 	shift
# 	echo "$key : $val"
# done >/tmp/mon.log

readonly THUNDERBIRD=$(find "${HOME}" -maxdepth 3 -name ".thunderbird")

# Profile name
readonly PROF_NAME="$1"
shift
# Source folder as given with %folder by Alert Mail
readonly SRC_FOLDER="$(echo "$1" | sed 's|/$||')"
shift
# Subject of the mail given with %folde by Alert Mail
readonly SUBJECT="$1"
shift
readonly SIZE="$1"
shift

prof_name() {
  awk -v p="${PROF_NAME}" '
  BEGIN {
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

# Profile path
readonly PROF_PATH="${THUNDERBIRD}/$(prof_name)"
# Folders that may contains the mails
readonly FOLDERS="$(find ${PROF_PATH} -not -type d -name "${SRC_FOLDER}*" -not -name "*.msf")"

# echo "-${MAIL_FOLDER}-" >>/tmp/mon.log
# echo "-${FOLDERS}-" >>/tmp/mon.log
# i=1

# while [ $i -le $# ]; do
# 	eval echo "$((i+1)) \${$i} : \${$((i+1))}"
# 	i=$((i+2))
# done >>/tmp/mon.log

# for i in $@; do
# 	echo -n "$i - "
# done >>/tmp/mon.log
echo "$SUBJECT" >>/tmp/mon.log
echo "$SIZE" >>/tmp/mon.log
sed ':a s/\r//g; /=$/{N; s/=\n//; ta}' "${FOLDERS}" | awk -f mail.awk -v subject="${SUBJECT}" >>/tmp/mon.log
# echo "==========" >>/tmp/mon.log
i=0
sed ':a s/\r//g; /=$/{N; s/=\n//; ta}' "${FOLDERS}" | awk -f mail.awk -v subject="${SUBJECT}" | while read line; do
  if [ "$i" -eq 1 ]; then
    notify-send "$head" "$line"
    i=0
  else
    head="$line"
    i=1
  fi
done