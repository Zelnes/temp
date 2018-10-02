#!/usr/bin/env bash

parse_args_help() {
cat <<-EOF
  This bash function helps to parse cmd line arguments
  It takes a list of understood option (short/long), for which their values can
  be assigned to a specified variable.

  Usage : parse_args "list of options understood" "original command line"

  The list is space element separated. Each element must be an option, and can
  be followed by an equal sign, "=", and a bash-like variable name.

  If a variable is given, and the option associated is found, then the variable
  is filled with the corresponding value.

  Setting PARSE_VERBOSE to 'y' will cause the function to be verbose on what it
  does

  Extra functions :
    - parse_args_get_opt_val <option> <list_of_options>
      Outputs an option and the variable associated if presents
    - parse_args_echo_vars var1 var2 ...
      Outputs the variables given and their contents
    - parse_args_test_func <cmd_line>
      Simulates a call to a function that calls itself parse_args
    - parse_args_call_test_func
      Simulates the call to parse_args_test_func

  Example :

  my_func() {
    parse_args "-s=varS --long=varL --alone" "\$@"
  }

  $ PARSE_VERBOSE=y my_func -s "something" --alone --long="like that" -e "oh yeah"
  -s=varS --long=varL --alone
  Short option '-s' => varS='something'
  Long option '--alone'
  Long option '--long' => varL='like that'
  Value '-e' saved
  Value 'oh yeah' saved

  === Checking Global vars
  PA_AO : --alone
  PA_R  :  "-e" "oh yeah"

  $ parse_args_echo_vars varS varL
  === Checking vars...
  varS = 'something'
  varL = 'like that'
EOF
}

parse_args_logger() {
  [ "${PARSE_VERBOSE}" != "y" ] || echo "$@"
}

# $1 : option needed
# $2 : command line
parse_args_get_opt_val() {
  sed -nr "s/.*-${1:1}(=?([^[:blank:]]*)).*/$1 \2/p" <<<"$2"
}

# Arg 1 : option=var-name option
# PARSE_VERBOSE=y -> verbose
# PA_AO and PA_R : Output
# TODO Add possibility to give PA_R/PA_AO names
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

  parse_args_logger $options
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
        parse_args_logger "Option '--' found, saving all others into PA_R..."
        shift
        while [[ $# -ne 0 ]]; do
          PA_R+=" '$1'"; shift
        done
      ;;
      --* )
        read curO curV <<<$(parse_args_get_opt_val "$cur" "$options")
        if [[ -z "$curO" ]]; then
          cso="$1"
          parse_args_logger "Long option '$cso' saved"
          save=1
        else
          parse_args_logger -n "Long option '$cur' "
          if [[ -z "$curV" ]]; then
            PA_AO["$curO"]=1
            parse_args_logger
            shift
          else
            parse_args_logger "=> $curV='$val'"
            eval declare -g \"$curV="$val"\"
            shift $toshift
          fi
        fi
        ;;
      -* )
        cso="-${cur:1:1}"
        [ ${#cur} -ne 2 ] && {
          keep=1
          cur="-${cur:2}"
        }
        read curO curV <<<$(parse_args_get_opt_val "$cso" "$options")
        if [[ -z "$curO" ]]; then
          parse_args_logger -en "Short option '$cso' saved"
          save=1
        else
          parse_args_logger -n "Short option '$cur' "
          if [[ -z "$curV" ]]; then
            PA_AO["$curO"]=1
            parse_args_logger
            [ "$keep" = 1 ] || shift
          else
            parse_args_logger "=> $curV='$val'"
            eval declare -g \"$curV="$val"\"
            shift $toshift
          fi
        fi
        ;;
      * )
        cso="$1"
        parse_args_logger "Value '$cso' saved"
        save=1
        shift
        ;;
    esac
    [ "$save" = "1" ] && PA_R+=" \"$cso\""
  done

  parse_args_logger -e "\n=== Checking Global vars"
  parse_args_logger "PA_AO : ${!PA_AO[@]}"
  parse_args_logger "PA_R  : ${PA_R}"
}

parse_args_echo_vars() {
  echo "=== Checking vars..."
  for i in $@; do
    eval echo \"$i = \'\${$i}\'\"
  done
}

parse_args_test_func() {
  echo " -- Calling for '$@'"
  parse_args "-p=my_option --other=letssee --verbose=verbosity --alone -y" "$@"
  parse_args_echo_vars my_option letssee verbosity
}

parse_args_call_test_func() {
   parse_args_test_func -p door -e something --verbose "Yes we can" --other="it works also" --alone -y -e "This is what I say"
}
