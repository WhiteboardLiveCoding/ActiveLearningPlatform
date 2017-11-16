#!/bin/sh

usage()
{
	echo "usage: setup.sh"
	echo "\t[-h | --help]"
	echo "\t[-a | --account ACCOUNT]"
	echo "\t[-k | --key KEY]"
	echo "\t[-u | --cr-username ACCOUNT]"
	echo "\t[-p | --cr-password KEY]"
}

blob_account=""
blob_key=""
cr_username=""
cr_password=""

while [ "$1" != "" ]; do
	case $1 in
		-h | --help)
			usage
			exit
			;;
		-a | --account)
			shift
			blob_account=$1
			;;
		-k | --key)
			shift
			blob_key=$1
			;;
		-u | --cr-username)
			shift
			cr_username=$1
			;;
		-p | --cr-password)
			shift
			cr_password=$1
			;;
		*)
			echo "ERROR: unknown parameter \"$1\""
			usage
			exit 1
			;;
	esac
	shift
done

if [[ -z "$blob_account" ]]; then
    echo "Please provide the Azure Blob Account"
    exit 1
fi

if [[ -z "$blob_key" ]]; then
    echo "Please provide the Azure Blob Key"
    exit 1
fi

if [[ -z "$cr_username" ]]; then
    echo "Please provide the Container Registry username"
    exit 1
fi

if [[ -z "$cr_password" ]]; then
    echo "Please provide the Container Registry password"
    exit 1
fi

echo "Bootstraping Active Learning Platform..."

sudo nvidia-docker login whiteboardlivecoding.azurecr.io \
	-u ${cr_username} \
	-p ${cr_password}

sudo nvidia-docker pull whiteboardlivecoding.azurecr.io/alp

sudo nvidia-docker run \
    -e BLOB_ACCOUNT="$blob_account" \
    -e BLOB_KEY="$blob_key" \
    -e CR_USERNAME="$cr_username" \
    -e CR_PASSWORD="$cr_password" \
    whiteboardlivecoding.azurecr.io/alp
