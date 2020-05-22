# shellcheck shell=bash
: # noop

# shellcheck disable=SC2034
declare -g ___messages__loaded="true" ___messages__doc

# shellcheck disable=SC2034
{ read -r -d '' ___messages__doc || true; } <<- EOF
  This library implements several messaging and logging functions.
  It has two modes set by the functions 'set_color_mode' and 'set_log_mode'.
  The 'color_mode' has ansi coloring while then 'log_mode' strips out these
  colors for use text logs.

  Message functions beginning in 'log_' send messages to stderr, while other
  functions send messages to stdout.

  Examples are shown in 'example_*'.
EOF

################################################################################
# Constants
################################################################################

# Basic styles
declare -gx _text_normal _text_bold _text_invert

# Basic colors 
declare -gx _text_red _text_green _text_blue _text_yellow \
  _text_teal _text_purple _text_white

# Logging styles
declare -gx _text_error _text_warn _text_info _text_debug

# Messaging styles
declare -gx _text_success _text_prompt _text_notify 

# Marks
declare -gx _text__check_m _text__ex_m _text__prompt_m _text__notify_m

# Logging levels
declare -grix \
  _text__level_debug=4 \
  _text__level_info=3 \
  _text__level_warn=2 \
  _text__level_error=1 \
  _text__level_silent=0

# Logging flags
declare -gix \
  _text__show_debug=0 \
  _text__show_info=0 \
  _text__show_warn=0 \
  _text__show_error=0

################################################################################
# Config functions
################################################################################

set_ascii_marks() {
  _text__check_m="+"
  _text__ex_m="X"
  _text__prompt_m="?"
  _text__notify_m="-"
}

set_uni_marks() {
  _text__check_m="✔"
  _text__ex_m="✗"
  _text__prompt_m="?"
  _text__notify_m="-"
}

set_color_mode() {
  _text_normal="\\e[0m"
  _text_red="\\e[31m"
  _text_green="\\e[32m"
  _text_yellow="\\e[33m"
  _text_blue="\\e[34m"
  _text_purple="\\e[35m"
  _text_teal="\\e[36m"
  _text_white="\\e[37m"
  _text_bold="\\e[1m"
  _text_invert="\\e[7m"
  _text_error="${_text_bold}${_text_red}"
  _text_warn="${_text_bold}${_text_yellow}"
  _text_info="${_text_bold}${_text_white}"
  _text_debug="${_text_bold}${_text_teal}"
  _text_notify="${_text_bold}${_text_teal}"
  _text_prompt="${_text_bold}${_text_blue}"
  _text_success="${_text_bold}${_text_green}"
}

set_log_mode() {
  _text_normal=""
  _text_red=""
  _text_yellow=""
  _text_green=""
  _text_white=""
  _text_purple=""
  _text_teal=""
  _text_bold=""
  _text_invert=""
  _text_error=""
  _text_warn=""
  _text_info=""
  _text_debug=""
  _text_notify=""
  _text_prompt=""
  _text_success=""
}

set_log_level() {
  local level named_levelR named_level
  level="$1"; shift

  # try reference if param is string
  named_levelR="_text__level_${level}"
  named_level="${!named_levelR}"
  [[ -n "$named_level" ]] && level="$named_level"
  
  # set flags
  _text__show_debug=0
  _text__show_info=0
  _text__show_warn=0
  _text__show_error=0
  (( level >= _text__level_error )) && _text__show_error=1
  (( level >= _text__level_warn  )) && _text__show_warn=1
  (( level >= _text__level_info  )) && _text__show_info=1
  (( level >= _text__level_debug )) && _text__show_debug=1
  return 0
}

################################################################################
# Logging
################################################################################

log_fmt() { echo -e "$1: $2${_text_normal}" >&2; }

log_error() {
  (( _text__show_error > 0 )) && log_fmt "${_text_error}ERROR" "$1"
}

log_warn() {
  (( _text__show_warn > 0 )) && log_fmt "${_text_warn}WARN" "$1"
}

log_info() {
  (( _text__show_info > 0 )) && log_fmt "${_text_info}INFO" "$1"
}

log_debug() {
  (( _text__show_debug > 0 )) && log_fmt "${_text_debug}DEBUG" "$1"
}

################################################################################
# Messages
################################################################################

message_checked() {
  echo -e "${_text_success}[${_text__check_m}] $1${_text_normal}"
}

message_exed() {
  echo -e "${_text_error}[${_text__ex_m}] $1${_text_normal}"
}

message_notify() {
  echo -e "${_text_notify}[${_text__notify_m}] $1${_text_normal}"
}

prompt_confirm() {
  local confirm; confirm=''
  local -i rc; rc=0

  echo -en "${_text_prompt}[${_text__prompt_m}] $1 (y/Y/n/N/q/Q) "
  while true; do
    read -rs -n 1 confirm
    case "$confirm" in
      (y|Y) rc=0; echo -en "${_text_green}(${_text__check_m})";;
      (n|N) rc=1; echo -en "${_text_red}(${_text__ex_m})";;
      (q|Q) rc=-1;;
      (*) continue;;
    esac
    break
  done
  echo -e "${_text_normal}"
  
  (( rc < 0 )) && fail_with "Aborting..."
  return $rc
}

################################################################################
# Failure
################################################################################

fail_with() { log_error "$1"; exit 1; }

################################################################################
# Defaults
################################################################################

set_color_mode
set_log_level 0

# if lofi tty use ascii marks
if [[ "$TERM" == "linux" ]]
then set_ascii_marks
else set_uni_marks
fi

################################################################################
################################################################################
