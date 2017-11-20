#!/bin/sh

container="alp"
dataset_tar="datasets.tar.gz"

echo "[INFO] Running [alp.py]..."
python3 alp.py -i pictures -a code

if [ $? -eq 69 ]; then
    exit 0
fi

echo "[INFO] Downloading the base datasets..."
az storage blob download --container-name ${container} \
                         --file ${dataset_tar} \
                         --name ${dataset_tar} \
                         --account-key ${BLOB_KEY} \
                         --account-name ${BLOB_ACCOUNT} || { exit 1; }

tar xzvf ${dataset_tar} || { exit 1; }
mv dataset training

echo "[INFO] Running the training on the generated dataset..."
cp artifacts/alp.mat training/dataset
cd training

python3 training.py \
    --datasets dataset/emnist.mat dataset/wlc.mat dataset/alp.mat \
    -m japanese \
    -o o_japanese \
    -g 4 -p -v 2 \
    2>&1 | tee training.txt

cp training.txt ../
cp -r o_japanese/ ../
cd ..

echo "[INFO] Copying generated model to wlc for benchmarking..."
cp o_japanese/model.yaml wlc/WLC/ocr/model
cp o_japanese/model.h5 wlc/WLC/ocr/model

echo "[INFO] Running benchmarks..."
cd wlc
python3 -m WLC.benchmark 2>&1 | tee benchmark.txt

cp benchmark.txt ../
cd ..

echo "[INFO] Creating the tarball..."
timestamp=$(date -u +"%Y-%m-%d-%H-%M-%S")
filename="alp-$timestamp.tar"

tar cvf ${filename} artifacts o_japanese training.txt benchmark.txt \
    || { echo "Tarball couldn't be generated."; exit 1; }

echo "[INFO] Create appropriate Azure Blob container..."
az storage container create --name ${container} \
                            --account-key ${BLOB_KEY} \
                            --account-name ${BLOB_ACCOUNT}

echo "[INFO] Uploading the tarball to Azure Blob Storage..."
az storage blob upload --container-name ${container} \
                       --file ${filename} \
                       --name ${filename} \
                       --account-key ${BLOB_KEY} \
                       --account-name ${BLOB_ACCOUNT} || { exit 1; }

echo "[INFO] Verifying uploaded blob..."
az storage blob exists --container-name ${container} \
                       --name ${filename} \
                       --account-key ${BLOB_KEY} \
                       --account-name ${BLOB_ACCOUNT} || { exit 1; }

echo "[INFO] Process completed."
