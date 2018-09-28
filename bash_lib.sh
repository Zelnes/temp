#!/usr/bin/env bash

# alias parse_log="eval \$verbosity echo"
alias parse_log="echo"

# $1 : option needed
# $2 : command line
parse_args_get_opt_val() {
  echo "$2" | grep -Eo "[-]${1:1}[^[:blank:]]*" | sed 's/=/ /'
}

# PA_AO
# PA_R
# Arg 1 : option=var-name option var-name
# Add possibility to give PA_R/PA_AO names
# And if not present, use local losts variables
# It may override otherwise
# PARSE_VERBOSE=y -> verbose
parse_args() {
  local options="$(printf "%s\n" "$1")"; shift
  local cmdl="$@"
  local curO curV
  # If set, do not update the current read value
  local keep=0 cur

  local verbosity
  [ "${PARSE_VERBOSE}" != "y" ] && verbosity='&>/dev/null'

  unset PA_AO PA_R
  declare -Ag PA_AO PA_R

  echo $options
  while [[ $# -ne 0 ]]; do
    [ "$keep" = "0" ] && cur="$1"
    keep=0
    case "$cur" in
      --* )
        set -x
        read curO curV <<<$(parse_args_get_opt_val "$cur" "$options")
        parse_log "long option $cur : needed by $curO $curV"
        if [[ -z "$curV" ]]; then
          PA_AO["$curO"]=1
          parse_log "empty"
          shift
        else
          parse_log "filled"
          declare -g $curV
          eval $curV="$2"
          shift 2
        fi
        set +x
        ;;
      -* )
        # Current Short option
        local cso="-${cur:1:1}"
        [ "$cur" = "-p" ] && cur="-c"
        parse_log "short option $cur $2"
        shift 2
        ;;
      * )
        parse_log "value $cur"
        shift
        ;;
    esac
  done
}

test_func() {
  echo " -- Calling for '$@'"
  parse_args "-p=mon-option une-autre --verbose=verbosity --alone" "$@"
}

call_func() {
   test_func -p porte  quelquechose --verbose Oui --alone
}
