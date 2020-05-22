# shellcheck shell=bash
: # noop

# shellcheck disable=SC2034
declare -gx ___cli__loaded="true" ___cli__doc

# shellcheck disable=SC2034
{ read -r -d '' ___cli__doc || true; } <<- EOF
  The CLI library parses commands with positional and named params of the forms:
    (a) long named flags   : '--long-flag'
    (b) long named params  : '--long-param [arg]' or '--long-param=[arg]'
    (d) short named flags  : '-a' or multiple '-abc'
    (e) short named params : '-a [arg]' or with short flags '-bca [arg]'
    (f) positional params  : '[param]'

  Positional params are taken as they come as words that cannot be interpreted as
  the arguments of named params.

  The cli works by being passed the relevant arguments. For instance
    
    parse_cli "\$@"

  in a script. Preprocessing can be done before this consequently.


  SPECIFYING:

  The definition of what to parse is specified in global variables. Param names
  are given a variable prefix of the form

    __param_name --> --param-name

  Associated with each prefix <X> are the following suffixes:

    <X>__n = number of arguments
      This can either be set to 0 for a flag or >0 for a single arg 

    <X>__doc = help doc string associated with the param

    <X>__short = short form param
      i.e. "__verbose__short=v" allows "-v" to be used instead of "--verbose"

  To declare an argument with prefix <X>, <X>__n must be set as a global:

    typeset -g <X>__n=<M>

  where <M> is 0 for a flag and 1 for a parameter with an argument. Params
  with multiple arguments are not yet supported. To define a default value
  just set the prefix itself

    typeset -g <X>=<default>

  Using a bash checker, it may be worth defining
    
    typeset -g <X>=''

  regardless, since the variable will then be globally defined.

  In order to show variables in the 'help_cli' function, the params must
  be added to an array '___cli__params'

    typeset -ga ___cli__params=(<X_1> <X_2> ...)

  For positional params, the variable '___cli__pos__n' must be set to
    
     0 - for no positionals
     N - for N positionals
    -1 - for a variable number of parameters

  Further checking is relegated to the rest of the program.

  OUTPUTS:

  The outputs of the parser are put into global variables. For named
  parameters the value for <X> is simply put into global <X>. For
  positional params, the variable '___cli__pos' contains an array of
  these.

  EXAMPLE:
  
  Examples of this are shown in the tests.
EOF

#% include "./message.bash" {
if [[ -z "$___messages__loaded" ]]; then
  # shellcheck source=./message.bash
  source "$(dirname "${BASH_SOURCE[0]}")/message.bash"
fi
#% }

use_error_cli() {
  log_error "$1"
  echo ""
  help_cli
  echo ""
  exit 1
}

parse_cli() {
  local short shortR
  local remaining_pos=${___cli__pos__n:-0}
  local -a params=${___cli__params[*]:-}

  for param in $params; do
    shortR="${param}__short"
    short=${!shortR}
    if [[ -n "$short" ]]; then
      local "short__$short=$param"
    fi
  done

  # Cmd options parsing
  local option_flag option_name option_n args rest
  while [ "$#" -gt 0 ]; do case "$1" in
    # Long-form options
    (--*=*)
      option_flag=${1%%=*}
      explicit_arg=${1#*=}

      option_name=${option_flag//-/_}
      option_n="${option_name}__n"
      args=${!option_n}

      # unkown option
      if [[ -z "$args" ]];  then use_error_cli "unkown option: $option_flag"

      # args cases
      elif (( args > 0 )); then typeset -g "${option_name}=$explicit_arg"; shift 1

      # error cases
      elif (( args == 0 )); then use_error_cli "option $option_flag has no parameter"
      else use_error_cli "$option_flag requires $args arguments."
      fi
    ;;
    
    # Long-form options
    (--*)
      option_name=${1//-/_}
      option_n="${option_name}__n"
      args=${!option_n}
     
      # unkown option
      if [[ -z "$args" ]];  then use_error_cli "unkown option: $1"
      
      # flag cases
      elif (( args == 0 )); then typeset -g "${option_name}=1";  shift 1
      
      # args cases
      elif (( args < $# )); then typeset -g "${option_name}=$2"; shift 2

      # error cases
      else use_error_cli "$1 requires $args arguments."
      fi
    ;;
    
    # Options
    (-?*)
      # flag itself. -abc => a
      short_key="short__${1:1:1}"
      
      # rest of flags. i.e. -abc => bc
      rest="${1#-?}"

      # get option for short flag
      option_name=${!short_key}
      [[ -z "$option_name" ]] && use_error_cli "unkown option: $1"

      option_n="${option_name}__n"
      args=${!option_n}

      # unknown option
      if [[ -z "$args" ]]; then use_error_cli "unkown option: $1"

      # flag cases
      elif (( args == 0 )); then typeset -g "${option_name}=1"; shift 1
      
      # args cases
      elif (( args < $# )); then
        if [[ -z $rest ]]; then typeset -g "${option_name}=$2"; shift 2
        
        # use rest as argument
        else typeset -g "${option_name}=$rest"; shift 1
        fi
      
      # error cases
      else use_error_cli "$1 requires $args arguments."
      fi

      # if rest exists push rest into parser
      [[ -n $rest ]] && set -- "-$rest" "$@"
    ;;

    # Positionals
    (*)
      if (( remaining_pos == 0 )); then
        fail_with "extraneous positional given: $1"
      else
        ___cli__pos+=("$1")
        remaining_pos=$(( remaining_pos - 1 ))
      fi
      shift 1
    ;;
  esac done
}

help_cli() {
  local param_str docstr_var docstr option_n_var option_n
  local -a params=${___cli__params[*]:-}
  local command_name=${___cli__command_name:-$(basename "$0")}
  local help_title=${___cli__help_title:-"$command_name help"}
  local help_message=${___cli__help_message:-""}

  echo "$help_title"
  echo "$help_message"

  echo
  echo "USAGE:"
  echo "    $command_name [FLAGS]"
  
  echo
  echo "FLAGS:"
  for param in $params; do
    docstr_var="${param}__doc"
    docstr=${!docstr_var}
    option_n_var="${param}__n"
    option_n=${!option_n_var}
    param_str=${param//_/-}
    
    if   (( option_n >= 1 )); then param_str="$param_str ARG"
    elif (( option_n < 0  )); then param_str="$param_str ARG_1 .."
    fi

    printf "    %-25s -- %s\\n" "$param_str" "$docstr"
  done
}
