#!/bin/sh

usage()
{
	echo "usage: setup.sh"
	echo "\t[-h | --help]"
	echo "\t[-a | --account ACCOUNT]"
	echo "\t[-k | --key KEY]"
}

install_git()
{
	echo "Installing git..."
	sudo apt update
	sudo apt -y install git || exit 1
}

install_python3()
{
	echo "Installing python3..."
	sudo apt update
	sudo apt -y install python3 || exit 1
}

install_pip3()
{
	echo "Installing pip3..."
	sudo apt update
	sudo apt -y install python3-pip || exit 1
}

install_azure()
{
	echo "Installing azure cli..."
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" | \
     sudo tee /etc/apt/sources.list.d/azure-cli.list
    sudo apt-key adv --keyserver packages.microsoft.com --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893
    sudo apt-get -y install apt-transport-https || exit 1
    sudo apt-get update && sudo apt-get -y install azure-cli || exit 1
}

blob_account=""
blob_key=""
container="alp"

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

export BLOB_ACCOUNT=$blob_account
export BLOB_KEY=$blob_key

echo "Bootstraping Active Learning Platform..."

echo "Checking requirements..."
command -v git >/dev/null 2>&1 || { echo "Missing git."; install_git; }
command -v python3 >/dev/null 2>&1 || { echo "Missing python."; install_python3; }
command -v pip3 >/dev/null 2>&1 || { echo "Missing pip."; install_pip3; }
command -v az >/dev/null 2>&1 || { echo "Missing azure cli."; install_azure; }

echo "Cloning WhiteboardLiveCoding/ActiveLearningPlatform..."
git clone --recursive https://github.com/WhiteboardLiveCoding/ActiveLearningPlatform.git alp

echo "Changing directories..."
cd alp
git checkout convert-images-to-dataset

echo "Installing project requirements..."
pip3 install -r requirements.txt
pip3 list

echo "Running [alp.py]..."
python3 alp.py -i pictures -a code

if [ $? -eq 69 ]; then
    exit 0
else
    exit 1
fi

echo "Downloading the base datasets..."
dataset_tar="datasets.tar.gz"
az storage blob download --container-name $container \
                         --file $dataset_tar \
                         --name $dataset_tar \
                         --account-key $blob_key \
                         --account-name $blob_account || { exit 1; }

tar xzvf $dataset_tar || { exit 1; }
mv dataset training

echo "Running the training on the generated dataset..."
cp artifacts/alp.mat training/dataset
cd training

# TODO: Get all the base datasets
python3 training.py \
    --datasets dataset/emnist.mat dataset/wlc.mat dataset/alp.mat \
    -m japanese \
    -o o_japanese \
    -g 4 -p -v 2 \
    2>&1 | tee training.txt

cp training.txt ../
cd ..

echo "Copying generated model to wlc for benchmarking..."
cp training/o_japanese/model.yaml wlc/WLC/ocr/model
cp training/o_japanese/model.h5 wlc/WLC/ocr/model

echo "Running benchmarks..."
cd wlc
python3 benchmark.py 2>&1 | tee benchmark.txt

cp benchmark.txt ../
cd ..

echo "Creating the tarball..."
mv training/o_japanese ./
timestamp=$(date -u +"%Y-%m-%d-%H-%M-%S")
filename="alp-$timestamp.tar"

tar cvf $filename o_japanese artifacts training.txt benchmark.txt \
    || { echo "Tarball couldn't be generated."; exit 1; }

echo "Create appropriate Azure Blob container..."
az storage container create --name $container \
                            --account-key $blob_key \
                            --account-name $blob_account

echo "Uploading the tarball to Azure Blob Storage..."
az storage blob upload --container-name $container \
                       --file $filename \
                       --name $filename \
                       --account-key $blob_account \
                       --account-name $blob_key || { exit 1; }

echo "Verifying uploaded blob..."
az storage blob exists --container-name $container \
                       --name $filename \
                       --account-key $blob_account \
                       --account-name $blob_key || { exit 1; }

echo "Process completed."
