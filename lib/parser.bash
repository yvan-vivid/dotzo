# shellcheck shell=bash
: # noop

# shellcheck disable=SC2034
declare -g ___parser__loaded="true" ___parser__doc

# shellcheck disable=SC2034
{ read -r -d '' ___parser__doc || true; } <<- EOF
  This module contains a parser that parses options from a toml-like format
  into global variables.

  The format of the config file consists of sections with assignments

    [section.x.y]
    parameter_a = value_a 
    parameter_b = value_b
    ...

  which will be assigned as though

    params__section__x__y__parameter_a=value_a
    params__section__x__y__parameter_b=value_b

  to the named globals.

  The special format

    [section.x.list:]
    value_a 
    value_b
    ...

  ending in a ':' will construct an array

    params__section__x__list=(value_a value_b)

  values are either quoted with single or double quotes and stripped
  of surrounding spaces.
EOF

#% include "./message.bash" {
if [[ -z "$___messages__loaded" ]]; then
  # shellcheck source=./message.bash
  source "$(dirname "${BASH_SOURCE[0]}")/message.bash"
fi
#% }

################################################################################
# Matching regexes
################################################################################

# Fragments
rpre_sp='^[[:space:]]*'
rasg='([A-Za-z0-9_]+)[[:space:]]*=[[:space:]]*'
rend_idq='"(.*)"[[:space:]]*$'
rend_isq="'"'(.*)'"'"'[[:space:]]*$'
rend_iun='([A-Za-z0-9_./]+)[[:space:]]*$'

# Line matches
regex_whitespace="$rpre_sp"'$'
regex_section="$rpre_sp"'\[[[:space:]]*([A-Za-z0-9_:.]+)[[:space:]]*\]'
regex_assign_dq="$rpre_sp$rasg$rend_idq"
regex_assign_sq="$rpre_sp$rasg$rend_isq"
regex_assign_un="$rpre_sp$rasg$rend_iun"
regex_item_dq="$rpre_sp$rend_idq"
regex_item_sq="$rpre_sp$rend_isq"
regex_item_un="$rpre_sp$rend_iun"

################################################################################
# Config Parser
################################################################################

config_parser() {
  local prefix mode section setting_var listoid
  local -a list_register
  prefix="${1}"; shift

  mode=''
  section=''
  while IFS= read -r cline; do
    # remove comments
    cline=${cline%%\#*}

    # skip empty lines
    [[ "$cline" =~ $regex_whitespace ]] && continue

    # check for section switch
    if [[ "$cline" =~ $regex_section ]]; then

      # ending
      if [[ "$mode" == "list" ]]; then
        setting_var="${prefix}__${section//./__}"
        IFS='|' listoid="${list_register[*]}"
        declare -g "$setting_var=$listoid"
      fi

      # switch section
      section="${BASH_REMATCH[1]}"
      case "$section" in
        (*::) # list sections
          mode="list"
          section="${section%%::}"
          list_register=()
          ;;
        (*) # regular sections
          mode="assign"
          ;;
      esac
      continue
    fi

    # handle section lines
    local setting value
    case "$mode" in
      (list)
        if [[ "$cline" =~ $regex_item_dq ]] \
        || [[ "$cline" =~ $regex_item_sq ]] \
        || [[ "$cline" =~ $regex_item_un ]]
        then list_register+=("${BASH_REMATCH[1]}")
        fi
        ;;

      (assign)
        if [[ "$cline" =~ $regex_assign_dq ]] \
        || [[ "$cline" =~ $regex_assign_sq ]] \
        || [[ "$cline" =~ $regex_assign_un ]]
        then
          setting=${BASH_REMATCH[1]}
          value=${BASH_REMATCH[2]}
          setting_var="${prefix}__${section//./__}__${setting}"
          declare -g "$setting_var=$value"
        fi
        ;;

      ('') ;;
      (*) ;;
    esac
  done
  
  # ending tail
  if [[ "$mode" == "list" ]]; then
    setting_var="${prefix}__${section//./__}"
    IFS='|' listoid="${list_register[*]}"
    declare -g "$setting_var=$listoid"
  fi
}

################################################################################
# ".dot" Parser
################################################################################

# global registers for parser output
typeset -ga dot_parser__mapping

# parser cannot be called in a recursive context without saving what is
# in the above register local to the calling frame
dot_parser() {
  local infile mode section
  infile="$1"; shift
  [[ -f "$infile" ]] || fail_with "File '$infile' does not exist."
  
  # clear registers
  dot_parser__mapping=()

  mode=''
  section=''
  while IFS= read -r cline; do
    # remove comments and skip empty lines
    cline=${cline%%\#*}
    [[ "$cline" =~ $regex_whitespace ]] && continue

    # check for section switch
    if [[ "$cline" =~ $regex_section ]]; then
      section="${BASH_REMATCH[1]}"
      case "$section" in
        (*) mode="mappings" ;;
      esac
      continue
    fi

    case "$mode" in
      (mappings)
        if [[ "$cline" =~ $regex_assign_dq ]] \
        || [[ "$cline" =~ $regex_assign_sq ]] \
        || [[ "$cline" =~ $regex_assign_un ]]
        then
          dot_parser__mapping+=("${section}:${BASH_REMATCH[1]}:${BASH_REMATCH[2]}")
        elif [[ "$cline" =~ $regex_item_dq ]] \
        ||   [[ "$cline" =~ $regex_item_sq ]] \
        ||   [[ "$cline" =~ $regex_item_un ]]
        then
          dot_parser__mapping+=("${section}:${BASH_REMATCH[1]}:")
        fi
        ;;

      ('') ;;
      (*) ;;
    esac
  done < "$infile"
}

################################################################################
################################################################################
