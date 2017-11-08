#!/bin/sh

RESOURCE_GROUP="ALP"
VM_NAME="alp-training"
SETTINGS="azure/public.json"

usage()
{
	echo "usage: deploy.sh"
	echo "\t[-h | --help]"
	echo "\t[-s | --settings SETTINGS]"
	echo "\t[-g | -resource-group RESOURCE_GROUP]"
	echo "\t[-n | --vm-name VM_NAME]"
}

while [ "$1" != "" ]; do
	case $1 in
		-h | --help)
			usage
			exit
			;;
		-s | --settings)
			shift
			SETTINGS=$1
			;;
		-g | --resource-group)
			shift
			RESOURCE_GROUP=$1
			;;
		-n | --vm-name)
			shift
			VM_NAME=$1
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

echo "Please make sure that you have logged into the Azure CLI"

echo "Starting vm '$VM_NAME' in the '$RESOURCE_GROUP' resource group..."
az vm start -g $RESOURCE_GROUP -n $VM_NAME || { exit 1; }

echo "Creating CustomScript extension for the virtual machine..."
az vm extension set \
	--resource-group $RESOURCE_GROUP \
	--vm-name $VM_NAME \
	--name CustomScript \
	--publisher Microsoft.Azure.Extensions --version 2.0 \
	--settings $SETTINGS \
	|| { exit 1; }

echo "CustomScript deployed!"
