#!/bin/bash
# ./terraform-deploy.sh prod global/test
# set -x

print_message (){
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =
  echo "+++> $1"
}

ROOT_DIR=$PWD
TF_PROJECT_ENV=$1
TF_WORKDIR=project/$TF_PROJECT_ENV/$2
TF_PROJECT_NAME=$(echo $TF_WORKDIR | awk -F "/" '{print $NF}')
TF_STATE_DIR=tf-state/$TF_PROJECT_ENV
TF_VARIABLES_PATH=variables/$TF_PROJECT_ENV.tfvars

[ ! $TF_WORKDIR ] && read -p "Enter the path: " TF_WORKDIR
[ ! -d "$ROOT_DIR/$TF_WORKDIR" ] && echo "EXIT: $TF_WORKDIR not found." && exit 1;
[ ! $TF_PROJECT_ENV ] && read -p "Enter the path: " TF_PROJECT_ENV


echo "Setting WORKING DIRECTORY..."
cd $TF_WORKDIR && pwd

print_message "clean old .terraform folder"
rm -rvf .terraform *.tfstate *.tfplan

# ------------------------------------------------------------------------------
# SET CONFIG

TERRAFORM_CONFIG=terraform.tf
cat > $TERRAFORM_CONFIG <<TERRAFORM
terraform {
  backend "local" {
    path = "${ROOT_DIR}/${TF_STATE_DIR}/${TF_PROJECT_NAME}/terraform.tfstate"
  }
}
TERRAFORM

# ------------------------------------------------------------------------------
# INIT

print_message "init"
terraform init

# ------------------------------------------------------------------------------
# PLAN

print_message "terraform plan..."
TF_STATUS=$(terraform plan -no-color -detailed-exitcode -var-file=${TF_VARIABLES_PATH} | grep "Plan" | awk -F "," '{print $NF}' | awk '{print $1}')

print_message "checking plan..."
# [ "$TF_STATUS" -gt "0" ] && echo "DESTROY FOUND"; terraform show the_plan.tfplan; #exit 1
# ------------------------------------------------------------------------------
# APPLY

if [ ! $TF_STATUS ]
then
  print_message "No Changes Found."
else
  print_message "apply"
  if [ "$TF_STATUS" -gt "0" ]
  then

    terraform apply -no-color -var-file=${TF_VARIABLES_PATH} #-auto-approve
  else
    terraform apply -no-color -var-file=${TF_VARIABLES_PATH} -auto-approve
  fi
fi
