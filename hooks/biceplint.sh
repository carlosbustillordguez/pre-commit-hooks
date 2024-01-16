#!/usr/bin/env bash
set -eo pipefail

# Run `az bicep lint` command on a given bicep file.

# globals variables
# shellcheck disable=SC2155 # No way to assign to readonly variable in separate lines
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=_common.sh
. "$SCRIPT_DIR/_common.sh"

#######################################################################
# Lint the given bicep files.
# Arguments:
#   args_array_length (integer) Count of arguments in args array
#   args (string with array) arguments that configure wrapped tool behavior
#   files (array) filenames to check
#######################################################################
function biceplint {
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

  if ! command -v az > /dev/null 2>&1; then
    echo "ERROR: az CLI is required by biceplint pre-commit hook but is not installed or in the system's PATH."
    echo 'See https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-cli'
    exit 1
  fi

  # consume modified bicep files passed from pre-commit so that
  # hook runs against only those relevant files
  for file_with_path in $(echo "${files[*]}" | tr ' ' '\n'); do
    # makes dirname and basename commands works properly when spaces are present in path
    file_with_path="${file_with_path// /__REPLACED__SPACE__}"

    dir_path=$(dirname "$file_with_path")
    file_name=$(basename "$file_with_path")
    dir_path="${dir_path//__REPLACED__SPACE__/ }"

    # move to the $dir_path
    pushd "$dir_path" > /dev/null || continue

    echo "#### Linting $file_with_path ####"
    az bicep lint --file "$file_name" "${args[@]}"
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
  biceplint "${#ARGS[@]}" "${ARGS[@]}" "${FILES[@]}"
}

[ "${BASH_SOURCE[0]}" != "$0" ] || main "$@"
