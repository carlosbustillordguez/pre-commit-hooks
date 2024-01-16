#!/usr/bin/env bash
set -eo pipefail

# Run `helmfile lint` command on a given helmfile file.

# globals variables
# shellcheck disable=SC2155 # No way to assign to readonly variable in separate lines
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=_common.sh
. "$SCRIPT_DIR/_common.sh"

#######################################################################
# Get the helmfile files that match (.*helmfile.d\/.*\.(ya?ml))|(.*helmfile\.yaml)
# and custom helmfile files (don't match the previous condition)
# Arguments:
#   files (array) detected by pre-commit
# Globals:
#   CUSTOM_FILES (array) custom files to check that don't match with (.*helmfile.d\/.*\.(ya?ml))|(.*helmfile\.yaml)
#######################################################################
function get_helmfile_files {
  local -a -r files=("$@")

  re="(.*helmfile.d\/.*\.(ya?ml))|(.*helmfile\.yaml)"
  local -a helmfile_files=()

  # get only the files that match (.*helmfile.d\/.*\.(ya?ml))|(.*helmfile\.yaml)
  for file_with_path in "${files[@]}"; do
    if [[ $file_with_path =~ $re ]] || [[ "${CUSTOM_FILES[*]}" =~ $file_with_path ]]; then
      helmfile_files+=("$file_with_path")
    fi
  done

  echo "${helmfile_files[@]}"
}

#######################################################################
# Lint the given helmfile files.
# Arguments:
#   args_array_length (integer) Count of arguments in args array
#   args (string with array) arguments that configure wrapped tool behavior
#   files (array) filenames to check
#######################################################################
function helmfilelint {
  local -i args_array_length=$1
  shift 1
  local -a args=()
  # Expand args to a true array.
  # Based on https://stackoverflow.com/a/10953834
  while ((args_array_length-- > 0)); do
    args+=("$1")
    shift
  done
  # assign rest of function's positional ARGS into `files` array,
  # despite there's only one positional ARG left
  local -a -r files=("$@")

  if ! command -v helmfile > /dev/null 2>&1; then
    echo "ERROR: helmfile is required by helmfilelint pre-commit hook but is not installed or in the system's PATH."
    echo 'See https://helmfile.readthedocs.io/en/latest/#installation'
    exit 1
  fi

  # consume modified helmfile files passed from pre-commit so that
  # hook runs against only those relevant files
  for file_with_path in $(echo "${files[*]}" | tr ' ' '\n'); do
    # makes dirname and basename commands works properly when spaces are present in path
    file_with_path="${file_with_path// /__REPLACED__SPACE__}"

    dir_path=$(dirname "$file_with_path")
    file_name=$(basename "$file_with_path")
    dir_path="${dir_path//__REPLACED__SPACE__/ }"

    # move to the $dir_path
    pushd "$dir_path" > /dev/null || continue

    if [ -f linter_values.yaml ]; then
      args+=("--state-values-file=linter_values.yaml")
    fi

    echo "#### Linting $file_with_path ####"
    helmfile lint --quiet --file "$file_name" "${args[@]}"
    echo ""

    # get back the previous directory
    popd > /dev/null
  done
}

function main {
  common::initialize "$SCRIPT_DIR"
  common::parse_cmdline "$@"
  common::export_provided_env_vars "${ENV_VARS[@]}"
  common::parse_and_export_env_vars

  # shellcheck disable=SC2153 # ARGS and FILES are correctly assigned
  helmfilelint "${#ARGS[@]}" "${ARGS[@]}" "$(get_helmfile_files "${FILES[@]}")"
}

[ "${BASH_SOURCE[0]}" != "$0" ] || main "$@"
