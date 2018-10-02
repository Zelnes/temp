#!/usr/bin/env bash

parse_log() {
  [ "${PARSE_VERBOSE}" != "y" ] || echo "$@"
}

# $1 : option needed
# $2 : command line
parse_args_get_opt_val() {
  sed -nr "s/.*-${1:1}(=?([^[:blank:]]*)).*/$1 \2/p" <<<"$2"
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
  # cur & val : the option and its value
  #   --cur=val || --cur val
  local keep=0 cur val
  # Current Short option
  local cso
  # Set to the number of args consumed
  local toshift
  # Set to 1 if $1 needs to be saved in PA_R
  local save

  unset PA_AO PA_R
  declare -Ag PA_AO
  declare -g PA_R

  parse_log $options
  while [[ $# -ne 0 ]]; do
    save=0
    toshift=1
    [ "$keep" = "0" ] && {
      read cur val<<<$(echo "$1" | sed 's/=/ /')
      [ -z "$val" ] && {
        val="$2"
        toshift=2
      }
    }
    keep=0
    case "$cur" in
      --)
        parse_log "Option '--' found, saving all others into PA_R..."
        shift
        while [[ $# -ne 0 ]]; do
          PA_R+=" '$1'"; shift
        done
      ;;
      --* )
        # set -x
        read curO curV <<<$(parse_args_get_opt_val "$cur" "$options")
        if [[ -z "$curO" ]]; then
          cso="$1"
          parse_log "Long option '$cso' saved"
          save=1
        else
          parse_log -n "Long option '$cur' "
          if [[ -z "$curV" ]]; then
            PA_AO["$curO"]=1
            parse_log
            shift
          else
            parse_log "=> $curV='$val'"
            eval declare -g \"$curV="$val"\"
            shift $toshift
          fi
        fi
        # set +x
        ;;
      -* )
      # set -x
        cso="-${cur:1:1}"
        [ ${#cur} -ne 2 ] && {
          keep=1
          cur="-${cur:2}"
        }
        read curO curV <<<$(parse_args_get_opt_val "$cso" "$options")
        if [[ -z "$curO" ]]; then
          parse_log -en "Short option '$cso' saved"
          save=1
        else
          parse_log -n "Short option '$cur' "
          if [[ -z "$curV" ]]; then
            PA_AO["$curO"]=1
            parse_log
            [ "$keep" = 1 ] || shift
          else
            parse_log "=> $curV='$val'"
            eval declare -g \"$curV="$val"\"
            shift $toshift
          fi
        fi
        # set +x
        ;;
      * )
        cso="$1"
        parse_log "Value '$cso' saved"
        save=1
        shift
        ;;
    esac
    [ "$save" = "1" ] && PA_R+=" \"$cso\""
  done

  parse_log -e "\n=== Checking Global vars"
  parse_log "PA_AO : ${!PA_AO[@]}"
  parse_log "PA_R  : ${PA_R}"
}

echo_vars() {
  echo -e "\n=== Checking vars..."
  for i in $@; do
    eval echo \"$i = \'\${$i}\'\"
  done
}

test_func() {
  echo " -- Calling for '$@'"
  parse_args "-p=mon_option --autre=voyons une-autre --verbose=verbosity --alone -y" "$@"
  echo_vars mon_option voyons verbosity
}

call_func() {
   test_func -p porte -e quelquechose --verbose "Oui on peut" --autre="ca marche ca" --alone -y -e "Voila ce que je te dis"
}
