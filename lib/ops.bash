# shellcheck shell=bash
: # noop

# shellcheck disable=SC2034
declare -g ___ops__loaded="true" ___ops__doc

# shellcheck disable=SC2034
read -r -d '' ___ops__doc <<- EOF
EOF

#% include "./message.bash" {
if [[ -z "$___messages__loaded" ]]; then
  # shellcheck source=./message.bash
  source "$(dirname "${BASH_SOURCE[0]}")/message.bash"
fi
#% }

################################################################################
## Utilities
################################################################################

# Set the library dry run flag with some parameter. Dry on -n
set_dry() {
  if [[ -n "$1" ]]; then
    ___libzo__dry_run="true"
    log_info "Doing a dry run!"
  else
    ___libzo__dry_run=""
  fi
}

# Check either a given parameter for dry or for auto and the library flag
is_dry() {
  # shellcheck disable=2034
  [[ "$1" == "dry" || ( "$1" != "wet" && -n "$___libzo__dry_run" ) ]]
}

################################################################################
## API Standards
################################################################################

dz_cd() {
  local mode; mode="$1"; shift
  if is_dry "$mode"
  then echo cd "$@"
  else cd "$@" || exit 250
  fi
}

dz_mkdir() {
  local mode; mode="$1"; shift
  if is_dry "$mode"
  then echo mkdir "$@"
  else mkdir "$@"
  fi
}

dz_pushd() {
  local mode; mode="$1"; shift
  if is_dry "$mode"
  then echo pushd "$@"
  else pushd "$@" > /dev/null || exit 250
  fi
}

dz_popd() {
  local mode; mode="$1"; shift
  if is_dry "$mode"
  then echo popd "$@"
  else popd "$@" > /dev/null || exit 250
  fi
}

################################################################################
## Special Functions
################################################################################

dz_git() {
  local mode; mode="$1"; shift
  local -i git_rc
  if is_dry "$mode"
  then echo git "$@"
  else
    git "$@"
    git_rc=$?
    if (( git_rc != 0 )); then
      message_exed "Git operation failed with exit code: $git_rc"
      fail_with "Failed on git command."
    fi
  fi
}

dz_rsync() {
  local mode; mode="$1"; shift
  local -i rsync_rc
  if is_dry "$mode"
  then rsync -avu "$@" --dry-run
  else
    rsync -avu "$@"
    rsync_rc=$?
    if (( rsync_rc != 0 )); then
      message_exed "Rsync operation failed with exit code: $rsync_rc"
      fail_with "Failed on rsync command."
    fi
  fi
}

# dz_clobber mode stash clobbered
# Takes file [clobbered] and moves it into the [stash]
# Assumes that [stash] is inside a directory from which a path to
# [clobbered] can be constructed. Otherwise, the mimicry of the path
# structure within the [stash] directory would not make sense
dz_clobber() {
  local mode stash clobbered
  mode="$1"; shift
  stash="$1"; shift
  clobbered="$1"; shift

  local clob_dir stash_root stash_dir clob_from
  stash_root="$(dirname "$stash")"
  clob_dir="$(dirname "$clobbered")"
  clob_from="$(relativize "$clob_dir" "$stash_root")"

  if [[ ( "$clob_from" =~ ^\.\. ) || ( "$clob_from" =~ ^/ ) ]]; then
    log_error "[$clobbered] must be under the root of [$stash]"
    return 1
  fi

  stash_dir="$stash/$clob_from"

  if is_dry "$mode"
  then
    echo mkdir -p "$stash_dir" 
    echo mv "$clobbered" "$stash_dir/"
  else
    if [[ ! -d "$stash" ]]; then
      log_error "[$stash] does not exist."
      return 1
    fi
    mkdir -p "$stash_dir" 
    mv "$clobbered" "$stash_dir/"
  fi
}

################################################################################
################################################################################
