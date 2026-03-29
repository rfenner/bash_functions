# Copyright (c) [2026] [Ronald Fenner Jr]
# Licensed under the MIT License.
# See LICENSE file in the project root for full license information.

# shellcheck disable=SC2046
source $(dirname "${BASH_SOURCE[0]}")/questions.sh

##
# ask_set_aws_profile
# Asks for the aws profile name to export for aws cli. If the file
# .aws_profile exists in the passed in directory then that is used
# and asking for it's input is skipped
#
# $1 - the directory to search for the .aws_profile file in
##
function ask_set_aws_profile() {
  if [[ -n "$1" ]]; then
    if [[ -f "${1}/.aws_profile" ]]; then
      AWS_PROFILE=$(cat "${1}/.aws_profile")
    fi
  fi
  if [[ -z "${AWS_PROFILE}" ]]; then
    if ! ask_question AWS_PROFILE "Enter the aws profile for the aws cli (Hit enter for default): "; then
      echo "Failed to get an aws profile to use with the cli"
      return 1
    fi
  fi
  if [[ -z "${AWS_PROFILE}" ]]; then
    AWS_PROFILE="default"
  fi
  export AWS_PROFILE="${AWS_PROFILE}"
  return 0
}

##
# ask_aws_region
# Asks for the aws region to use with the aws cli
##
function ask_aws_region() {
  AWS_REGIONS=$(aws ec2 describe-regions --region us-east-1 --output text --query "Regions[*].RegionName" 2>/dev/null)
  if [[ -z "${AWS_REGIONS}" ]]; then
    echo "Failed to get any aws regions"
    return 1
  fi
  # shellcheck disable=SC2206
  AWS_REGIONS=(${AWS_REGIONS})
  if ! ask_from_list AWS_REGION AWS_REGIONS "Select aws region to use: "; then
    echo "Failed to get the aws region to use with the aws cli"
    return 1
  fi
  export AWS_REGION="${AWS_REGION}"
  return 0
}

##
# save_sm_secret
# Creates or updates a secrets manager secret
#
# $1 - secret name
# $2 - secret value
##
function save_sm_secret() {
  if [[ -z "$1" ]] || [[ -z "$2" ]]; then
    echo "You must specify the secret name and value"
    return 1
  fi
  # shellcheck disable=SC2140
  exists=$(aws secretsmanager list-secrets --filters Key="name",Values="$1" --output text)
  if [[ -z "$exists" ]]; then
    if ! aws secretsmanager create-secret --name "$1" --secret-string "$2"; then
      echo "Failed ot create the secret $1"
      return 1
    fi
  else
    if ! aws secretsmanager update-secret --secret-id "$1" --secret-string "$2"; then
      echo "Failed ot update the secret $1"
      return 1
    fi
  fi
  return 0
}

##
# get_sm_secret
# Gets the specified secret's value, if it doesn't exist returns an empty string
#
# $1 - var to place secret into
# $2 - secret name
##
function get_sm_secret() {
    if [[ -z "$1" ]] || [[ -z "$2" ]]; then
    echo "You must specify the variable name and secret name"
    return 1
  fi
  secret=$(aws secretsmanager get-secret-value --secret-id "$2" --query "SecretString" --output text 2>/dev/null)

  eval "$1='$secret'"
  return 0
}

##
# delete_sm_secret
# Deletes the specified secret using the default account policy on
# retention or if specified immediately deletes it
#
# $1 - secret name
# $2 - delete immediately, default is false use 1 or 0
##
function delete_sm_secret() {
  if [[ -z "$1" ]]; then
    echo "You must pass the secret name ot delete"
    return 1
  fi

  delete_immediately=""
  if [[ -n "$2" ]]; then
    if [[ "$2" != "0" ]] && [[ "$2" != "1" ]];then
      echo "You must use 0 or 1 for delete immediately"
      return 1
    fi
    if [[ "$2" == "1" ]]; then
        delete_immediately="--force-delete-without-recovery"
    fi
  fi

  if ! aws secretsmanager delete-secret --secret-id "$1" $delete_immediately; then
    echo "Failed to delete secret $1"
    return 1
  fi
  return 0
}


##
# save_ssm_param
# Creates or updates a ssm parameter
#
# $1 - parameter name
# $2 - parameter value
##
function save_ssm_param() {
  if [[ -z "$1" ]] || [[ -z "$2" ]]; then
    echo "You must specify the parameter name and value"
    return 1
  fi
  if ! aws ssm put-parameter --name "$1" --value "$2" --type String --overwrite; then
    echo "Failed ot create/update the parameter $1"
    return 1
  fi
  return 0
}

##
# get_ssm_param
# Gets the specified ssm parameter's value, if it doesn't exist returns an empty string
#
# $1 - var to place value into
# $2 - parameter name
##
function get_ssm_param() {
    if [[ -z "$1" ]] || [[ -z "$2" ]]; then
    echo "You must specify the variable name and parameter name"
    return 1
  fi
  secret=$(aws ssm get-parameter --name "$2" --query "Parameter.Value" --output text 2>/dev/null)

  eval "${1}='$secret'"
  return 0
}

##
# delete_ssm_param
# Deletes the specified ssm param
#
# $1 - secret name
##
function delete_ssm_param() {
  if [[ -z "$1" ]]; then
    echo "You must pass the ssm parameter name ot delete"
    return 1
  fi

  if ! aws ssm delete-parameter --name "$1"; then
    echo "Failed to delete ssm parameter $1"
    return 1
  fi
  return 0
}

##
# generate_ecr_tag
# Generates the ecr url for a ECR repository
#
# $1 - Var to set the tag to
# $2 - The account id
# $3 - The repository name with tag
##
function generate_ecr_tag() {
  if [[ -z "$1" ]]; then
    echo "You must pass an variable to set the tag to"
  fi

  if [[ -z "$2" ]]; then
    echo "You must pass the account id"
  fi

  eval "$1=\"${2}.dkr.ecr.${AWS_REGION}.amazonaws.com/${3}\""
}
