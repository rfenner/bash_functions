# Copyright (c) [2026] [Ronald Fenner Jr]
# Licensed under the MIT License.
# See LICENSE file in the project root for full license information.

##
# These functions are ment to be used to setup the
# .ssh folder in a docker container or build so
# that we can deploy from github
#
##

##
# add_deploy_key
# Adds the ssh key to teh ssh config file specified. Useful to setup
# temporary deploy keys in the file for a repository
#
# $1 - sm secret name to pull key from
# $2 - the path to where to place the key and config file to modify
# $3 - path for the key in the config
##
function add_deploy_key() {
  if [[ -z "${1}" ]]; then
    echo "You must provide the secret manager secret name to pull the deploy key from"
    return 1
  fi

  if [[ -z "${2}" ]]; then
    echo "You must provide the path the directory to store the key and config file to modify"
    return 1
  fi

  local key_path
  key_path='~/.ssh/'
  if [[ -n "${3}" ]]; then
    key_path="${3}"
  fi


  SSH_DIR="${2}"
  SSH_CONFIG="${2}/config"
  KEY_FILE_NAME="${1//\//_}"

  if grep -q "${1}" "${SSH_CONFIG}" 2>/dev/null; then
    return 0
  fi

  if ! get_sm_secret DEPLOY_KEY "${1}"; then
    echo "Failed to get get the ${1} value"
    return 1
  fi

  if [[ -z "${DEPLOY_KEY}" ]]; then
    echo "Value returned from secrets manager was empty"
    return 1
  fi

  echo "${DEPLOY_KEY}" > "${SSH_DIR}/${KEY_FILE_NAME}"
  chmod 0600 "${SSH_DIR}/${KEY_FILE_NAME}"

  echo "## START ${KEY_FILE_NAME}" >> "${SSH_CONFIG}"
  echo "Host github.com" >> "${SSH_CONFIG}"
  echo "  HostName github.com" >> "${SSH_CONFIG}"
  echo "  User git" >> "${SSH_CONFIG}"
  echo "  IdentityFile "${key_path}"${KEY_FILE_NAME}" >> "${SSH_CONFIG}"
  echo "  IdentitiesOnly yes" >> "${SSH_CONFIG}"
  echo "## END OF DEPLOY KEY ${KEY_FILE_NAME}" >> "${SSH_CONFIG}"
}


##
# remove_deploy_key
# Removes the specified ssh key from ssh config file specified
#
# $1 - sm secret name to remove
# $2 - the path to where to place the key and config file to modify
##
function remove_deploy_key() {
  if [[ -z "${1}" ]]; then
    echo "You must provide the secret manager secret name to pull the deploy key from"
    return 1
  fi

  if [[ -z "${2}" ]]; then
    echo "You must provide the path the directory to remove the key and config file to modify"
    return 1
  fi

  SSH_DIR="${2}"
  SSH_CONFIG="${2}/config"

  KEY_FILE_NAME=${1//\//_}
  /bin/rm -f "${SSH_DIR}/${KEY_FILE_NAME}"

  if ! grep -q "${1}" "${SSH_CONFIG}"; then
    return 0
  fi


  sudo sed -i ".bak" "/## START ${KEY_FILE_NAME}/,/## END OF DEPLOY KEY ${KEY_FILE_NAME}\n/d" "${SSH_CONFIG}"
  sudo /bin/rm -f "${SSH_CONFIG}.bak"
  return 0
}

##
# add_github_to_known
# adds github to the known hosts so you skip the question about
# adding when running non interactive scripts
#
# $1 - the path to store the known hosts
##
function add_github_to_known() {
  if ! ssh-keyscan -H github.com > "${1}/known_hosts"; then
    echo "Failed to add github.com to known hosts"
    return 1
  fi
  return 0
}