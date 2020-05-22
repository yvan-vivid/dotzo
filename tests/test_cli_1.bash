# shellcheck shell=bash
declare -gx ___test_cli_1__doc
{ read -r -d '' ___test_cli_1__doc || true; } <<- EOF
  This is a set of tests for the cli library.
  There are tests for most of the functions and errors.
EOF

# shellcheck disable=2034
define_cli_params() {
  typeset -g ___cli__help_title='test_cli_1 documentation (test)'
  typeset -g ___cli__command_name='test_cli_1'
  typeset -g ___cli__help_message="$___test_cli_1__doc"

  # arguments
  typeset -g __apple__n=0 __banana__n=1 __coffee__n=0
  typeset -g __long_name__n=1
  typeset -g __help__n=0

  # short
  typeset -g __apple__short='a' __banana__short='b' __coffee__short='c'
  
  # defaults
  typeset -g __apple='' __banana='' __coffee=''
  typeset -g __long_name='' __help=''
  
  # docs
  typeset -g __apple__doc='flag a'
  typeset -g __banana__doc='param b'
  typeset -g __coffee__doc='flag c'
  typeset -g __long_name__doc='param long_name'
  typeset -g __help__doc="show help documentation"
  
  # number of positionals
  typeset -g ___cli__pos__n=-1
  
  # positionals array
  typeset -ga ___cli__pos=()

  # parameters declaration
  typeset -ga ___cli__params=(__apple __banana __coffee __long_name __help)
}
define_cli_params

# shellcheck source=../lib/cli.bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/cli.bash"

# Run cli parsing
parse_cli "$@"

if (( __help == 1 )); then
  # Show cli help
  help_cli
else
  # Display test output encoding
  echo "$__apple:$__banana:$__coffee:$__long_name:${___cli__pos[*]}"
fi
