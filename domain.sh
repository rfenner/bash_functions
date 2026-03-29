# Copyright (c) [2026] [Ronald Fenner Jr]
# Licensed under the MIT License.
# See LICENSE file in the project root for full license information.

##
# add_host_domain
# add a host name to the /etc/hosts file pointing to 127.0.0.1
# if not already in the hosts file
#
# $1 - domain
##
function add_host_domain() {
  if [[ -z "$1" ]]; then
    echo "Need 1 arguments for add_host_domain"
    return 1
  fi

  if grep -q "$1" /etc/hosts; then
    return 0
  fi

  echo "You may be asked for you password to modify the /etc/hosts file for the domain"
  sudo env -i bash -c "echo -e \"###### $1 Added by add_domain_host DO NOT MODIFY #######\n127.0.0.1\t$1\n############## $1 End of add_domain_host ###############\n\" >> /etc/hosts"
  return 0
}

##
# remove_host_domain
# Removes a domain form the /etc/hosts if in it's there
#
# $1 - the domain
##
function remove_host_domain() {
    if [[ -z "$1" ]]; then
    echo "Need 1 arguments for remove_host_domain"
    return 1
  fi

  if ! grep -q "$1" /etc/hosts; then
    return 0
  fi
  echo "You may be asked for you password to modify the /etc/hosts file for the domain"
  sudo sed -i ".bak" "/###### $1 Added by add_domain_host DO NOT MODIFY #######/,/############## $1 End of add_domain_host ###############\n/d" /etc/hosts
  sudo /bin/rm -f /etc/hosts.bak
  return 0
}
