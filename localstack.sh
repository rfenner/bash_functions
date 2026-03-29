# Copyright (c) [2026] [Ronald Fenner Jr]
# Licensed under the MIT License.
# See LICENSE file in the project root for full license information.

##
# is_localstack_running
# checks to see if localstack is running or not
#
# $1 - the global to put he answer into as an int
##
function is_localstack_running() {
  local is_running
  is_running=$(docker ps -f name=localstack-main -q)
  if [[ -n "${is_running}" ]]; then
    return 0
  else
    echo "The core containers don't seem to be running make sure they are started."
    exit 1
  fi
}
