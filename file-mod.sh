# Copyright (c) [2026] [Ronald Fenner Jr]
# Licensed under the MIT License.
# See LICENSE file in the project root for full license information.

##
# file_is_modified
# checks to see if a file is more recent than last checked.
# The function check a file with the last timestamp that has the same
# name as the file being checked with the extension of .lcts. You should add
# this to your ignore file.
#
# Useful to check if a file was modified and trigger a rebuild of a docker image.
#
# $1 - global to store result
# $2 - file to check
# $3 - file where the last checked is stored, optional if not provided with use file name and new extension
##
function file_is_modified() {
  if [[ -z "$1" ]] || [[ -z "$2" ]]; then
    echo "Must provide 2 arguments to file_is_modified"
    return 1
  fi

  if [[ ! -e "$2" ]]; then
    echo "'$2' doesn't exist"
    return 1
  fi
  local last_checked
  last_checked="${2}.lcts"
  if [[ -n "$3" ]]; then
    if [[ "$2" == "$3" ]]; then
      last_checked="$2.lcts"
    else
      last_checked="$3"
    fi
  fi
  last_checked_ts=0
  if [[ -e "${last_checked}" ]]; then
    last_checked_ts=$(cat "${last_checked}")
  fi

  local file_mod_time
  file_mod_time=$(date -r "$2" +%s)

  local ret_value=0
  if [[ ${last_checked_ts} -lt ${file_mod_time} ]]; then
        ret_value=1
        echo "${file_mod_time}" > "${last_checked}"
  fi

  eval "$1=\"${ret_value}\""
  return 0
}