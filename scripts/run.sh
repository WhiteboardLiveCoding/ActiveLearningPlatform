#!/bin/sh

RESOURCE_GROUP="ALP"
VM_NAME="alp-training"
PUBLIC="azure/public.json"
PRIVATE="azure/private.json"
START_VM=0

usage()
{
	echo "usage: deploy.sh"
	echo "\t[-h | --help]"
	echo "\t[--public PUBLIC]"
	echo "\t[--private PRIVATE]"
	echo "\t[-g | --resource-group RESOURCE_GROUP]"
	echo "\t[-n | --vm-name VM_NAME]"
	echo "\t[-st | --start-vm]"
}

while [ "$1" != "" ]; do
	case $1 in
		-h | --help)
			usage
			exit
			;;
		--public)
			shift
			PUBLIC=$1
			;;
		--private)
			shift
			PRIVATE=$1
			;;
		-g | --resource-group)
			shift
			RESOURCE_GROUP=$1
			;;
		-n | --vm-name)
			shift
			VM_NAME=$1
			;;
		-st | --start-vm)
			START_VM=1
			;;
		*)
			echo "ERROR: unknown parameter \"$1\""
			usage
			exit 1
			;;
	esac
	shift
done

echo "Deploying CustomScript to Azure Linux VM..."
echo "Checking requirements..."
command -v az >/dev/null 2>&1 || { echo >&2 "Missing Azure CLI. Aborting."; exit 1; }

# Exit if any step returns a non-zero exit code after this
set -e

echo "Please make sure that you have logged into the Azure CLI"

if [ $START_VM -eq 1 ]
then
	echo "Starting vm '$VM_NAME' in the '$RESOURCE_GROUP' resource group..."
	az vm start -g $RESOURCE_GROUP -n $VM_NAME
fi

echo "Creating CustomScript extension for the virtual machine..."
az vm extension set \
	--resource-group $RESOURCE_GROUP \
	--vm-name $VM_NAME \
	--name CustomScript \
	--publisher Microsoft.Azure.Extensions --version 2.0 \
	--settings $PUBLIC \
	--protected-settings $PRIVATE

echo "CustomScript deployed!"
