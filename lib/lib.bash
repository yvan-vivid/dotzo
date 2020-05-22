# shellcheck shell=bash
# Loading library components
declare -g ___lib__loaded="true"
read -r -d '' ___lib__doc <<- EOF
  This is the loading file for the "libzo" library.
  It can be included by defining a variable 'libzo' with a path to the
  library directory. The following two lines can be then dropped in
  verbatim (without escapes):

    typeset -g ___libzo=\$(cd "\$(dirname "\$0")/\$libzo" || exit 1; pwd -L)
    source "\${___libzo}/lib.bash"

  If some other variable is used for the path, the one 'libzo' reference in
  the first line can be changed appropriately. The first line sets a global
  variable '___libzo' to the absolute path of the library (using 'libzo'
  which may be relative). The second line uses this variable to include
  this file, which then pulls in all the others.

  Each component in

    ___libzo/<component>.bash

  defines a global namespace with the prefix

    ___<component>

  Parameters for the component and products of the component use these
  namespaces. Each component has, for instance, a documentation string in

    ___<component>__doc

  In the future, this library may be compiled into a single file.

  There are a couple global variables that are used under the namespace

    ___libzo

  These are

    ___libzo__dry_run

  which if set to anything but empty will run effectful computations as
  a dry run, printing the effects to stdout.
EOF
export ___lib__doc ___lib__loaded

#% ignore {
typeset -g ___libzo
if [[ -z "${___libzo}" ]]; then
  echo "Could not load libzo. No location given." >&2
fi
#% }

#% include "./message.bash" {
if [[ -z "$___messages__loaded" ]]; then
  # shellcheck source=./message.bash
  source "${___libzo}/message.bash"
fi
#% }

#% include "./cli.bash" {
if [[ -z "$___cli__loaded" ]]; then
  # shellcheck source=./cli.bash
  source "${___libzo}/cli.bash"
fi
#% }

#% include "./paths.bash" {
if [[ -z "$___paths__loaded" ]]; then
  # shellcheck source=./paths.bash
  source "${___libzo}/paths.bash"
fi
#% }

#% include "./ops.bash" {
if [[ -z "$___ops__loaded" ]]; then
  # shellcheck source=./ops.bash
  source "${___libzo}/ops.bash"
fi
#% }

#% include "./parser.bash" {
if [[ -z "$___parser__loaded" ]]; then
  # shellcheck source=./parser.bash
  source "${___libzo}/parser.bash"
fi
#% }
