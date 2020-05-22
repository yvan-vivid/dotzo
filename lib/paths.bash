# shellcheck shell=bash
: # noop

# shellcheck disable=SC2034
declare -g ___paths__loaded="true" ___paths__doc

# shellcheck disable=SC2034
{ read -r -d '' ___paths__doc || true; } <<- EOF
EOF

#% include "./message.bash" {
if [[ -z "$___messages__loaded" ]]; then
  # shellcheck source=./message.bash
  source "$(dirname "${BASH_SOURCE[0]}")/message.bash"
fi
#% }

################################################################################
## These functions are not used directly but test methods used inline.
## The reason that these are inlined is that they reference local variables
## and bash does not handle scope in a manner sophisticated enough to be
## entrusted with this kind of dereferencing.
################################################################################

# split_path_into <array_name> <path> => void
split_path_into() { IFS='/' read -ra "$1" <<< "$2/"; }

# split_path_into <sep> <array_name> <path> => void
split_into() { IFS="$1" read -ra "$2" <<< "$3$1"; }

# join_into_path <parts> ... => stdout: joined path
join_into_path() {
  local x
  IFS='/' x="$*" # inline macro
  echo "$x"
}

# join_into <sep> <parts> .. => stdout: joined path
join_into() {
  local x s
  s="$1"; shift
  IFS="$s" x="$*" # inline macro
  echo "$x"
}

################################################################################
## API
################################################################################

# normalize <path> => stdout: <normed_path> 
# Normalize a path to an absolute without dereferencing symlinks
# This removes extra '/', collapses '.' and '..' links
normalize() {
  local path pdir pbase normed
  path="$1"; shift 1
  
  if [[ -d $path ]]; then
    pdir=$path
  elif [[ -e $path ]]; then
    pdir=$(dirname "$path")
    pbase=$(basename "$path")
  else
    fail_with "Path $path does not exist"
  fi

  normed=$(cd "$pdir" || return 1; pwd -L)
  if [[ -n $pbase ]]; then
    normed=$normed/$pbase
  fi

  echo "$normed"
}


# factor_paths <a> <b> => stdout: "<common>:<a_suffix>:<b_suffix>"
# Get the glb of two paths <a> <b> and factor it out.
factor_paths() {
  local a b a_0 b_0 a_i b_i path
  a="$1"
  b="$2"

  # Break paths into arrays of parts
  typeset -a a_parts b_parts common
  IFS='/' read -ra a_parts <<< "$a/"
  IFS='/' read -ra b_parts <<< "$b/"

  typeset -i i an bn m
  an=${#a_parts[@]}
  bn=${#b_parts[@]}

  # m = min(an, bn)
  if (( an > bn )); then m=bn; else m=an; fi

  # first elements
  a_0="${a_parts[0]}"
  b_0="${b_parts[0]}"

  # one of the paths is empty
  if (( m <= 1 )); then
    if [[ -z "$a_0" ]] || [[ -z "$b_0" ]]; then
      echo ""
      return 0
    fi
  fi

  # no common root at all
  if [[ "$a_0" != "$b_0" ]]; then
    echo ""
    return 0
  fi

  # at least one component exists and matches
  common=("$a_0")
  for (( i=1 ; i < m ; i++ )); do
    a_i=${a_parts[i]}
    b_i=${b_parts[i]}
    if [[ "$a_i" == "$b_i" ]]; then
      common+=("$a_i")
    else break
    fi
  done

  # join prefix and return if no factor array
  IFS='/' path="${common[*]}"
  if [[ -z "$path" ]]; then path='/'; fi

  # join suffixes
  IFS='/' a_suffix="${a_parts[*]:i:an}"
  IFS='/' b_suffix="${b_parts[*]:i:bn}"
 
  # construct output string
  echo "$path:$a_suffix:$b_suffix"
}


# relativize <path> [<from>] => stdout: <relativized_path>
# Relativize a path from either a given path or from '.'
# Example:
#     <path> = /full/path/from/here/to/there
#     <from> = /full/path/from/this
#     <relativized_path> = ../here/to/there
relativize() {
  local path from path_fs from_fs factored
  path="$1"; shift 1

  if (( $# == 0 )); then
    from="."
  else
    from="$1"; shift 1
  fi

  # Gets normed and throws on non-existent paths
  path="$(normalize "$path")"
  from="$(normalize "$from")"

  # If <from> is not a directory get its directory
  if [[ ! -d "$from" ]]; then
    from=$(dirname "$from")
  fi

  # Get filesystems
  path_fs="$(stat -c %m "$path")"
  from_fs="$(stat -c %m "$from")"
  if [[ "$path_fs" != "$from_fs" ]]; then
    fail_with "$path is on different file system than $from."
  fi

  typeset -a factorize
  factored=$(factor_paths "$path" "$from")
  IFS=':' read -ra factorize <<< "$factored:"

  typeset -i factorize_n
  factorize_n="${#factorize[@]}"

  # Single entry in factorization
  if (( factorize_n < 3 )); then
    fail_with "$path cannot be relativized from $from."
  fi

  local common path_rel_common from_rel_common up_to_common
  common="${factorize[0]}"
  path_rel_common="${factorize[1]}"
  from_rel_common="${factorize[2]}"

  common_fs="$(stat -c %m "$common")"
  if [[ "$path_fs" != "$common_fs" ]]; then
    fail_with "$path and $from do not have a glb in the same file system."
  fi

  if [[ -z $from_rel_common ]]; then
    echo "$path_rel_common"
    return 0
  fi

  typeset -a from_parts
  IFS='/' read -ra from_parts <<< "$from_rel_common/"

  typeset -i from_parts_n
  from_parts_n=${#from_parts[@]}

  up_to_common=".."
  for (( k = 1 ; k < from_parts_n ; k++ )); do
    up_to_common="$up_to_common/.."
  done

  echo "$up_to_common/$path_rel_common"
}


# check_link <mode> <link> <dest>
# <mode> in {rel(ative), abs(olute), given}
declare -igrx \
  check_link__link_dne=1 \
  check_link__link_clob=2 \
  check_link__src_diff=3 \
  check_link__src_dne=4
check_link() {
  local mode src link
  mode="$1"; shift
  link="$1"; shift
  src="$1"; shift

  if [[ ! -h "$link" ]]; then
    if [[ ! -e "$link" ]]; then
      echo "$link does not exist"
      return $check_link__link_dne
    else
      echo "$link exist but is not a link"
      return $check_link__link_clob
    fi
  fi
 
  local link_dir src_from_link
  src_from_link="$(readlink "$link")"
  link_dir="$(dirname "$link")"

  if [[ ! -e "$link_dir/$src_from_link" ]]; then
    echo "$link is broken"
    return $check_link__src_diff
  fi

  case "$mode" in
    (given) ;;
    (abs*) src="$(normalize "$src")";;
    (rel*) src="$(relativize "$src" "$link_dir")";;
    (*) fail_with "<mode> must be rel(ative), abs(olute), or given"
  esac

  if [[ "$src_from_link" != "$src" ]]; then
    echo "$link points to $src_from_link instead of $src"
    return $check_link__src_diff
  fi

  pushd "$link_dir" > /dev/null || exit 120
  test -e "$src"
  declare -ir exists=$?
  popd > /dev/null || exit 120

  if (( exists != 0 )); then
    echo "$src does not exist"
    return $check_link__src_dne
  fi
  
  return 0
}


# make_link <mode> <link> <src>
# <mode> in {rel(ative), abs(olute), given}
make_link() {
  local src link mode link_dir
  mode="$1"; shift
  link="$1"; shift
  src="$1"; shift

  # location of link
  link_dir="$(dirname "$link")"

  # check directory for existance
  [[ -d "$link_dir" ]] || fail_with "$link_dir does not exist."

  # relativize if in relative mode
  case "$mode" in
    (rel*) src="$(relativize "$src" "$link_dir")";;
    (abs*) src="$(normalize "$src")";;
    (given) ;;
    (*) fail_with "<mode> must be rel(ative), abs(olute), or given"
  esac

  # check dest from directory
  local -i accessible
  pushd "$link_dir" > /dev/null || exit 2
  test -e "$src"
  accessible=$?
  popd > /dev/null || exit 2

  if (( accessible != 0 )); then
    fail_with "$src is not accessible from within $link_dir"
  fi

  # make link
  # shellcheck disable=2154
  if [[ -n "$___libzo__dry_run" ]]; then
    echo ln -snfT "$src" "$link"
  else
    ln -snfT "$src" "$link"
  fi
}


################################################################################
################################################################################
