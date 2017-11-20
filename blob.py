import os
import io
import numpy as np

from azure.storage.blob import BlockBlobService
from PIL import Image


def _get_block_blob_service():
    if 'BLOB_ACCOUNT' not in os.environ or 'BLOB_KEY' not in os.environ:
        raise ValueError('BLOB_ACCOUNT and BLOB_KEY environment variables need to be set.')

    account = os.environ.get('BLOB_ACCOUNT')
    key = os.environ.get('BLOB_KEY')

    return BlockBlobService(account_name=account, account_key=key)


def _get_image_from_blob(service, container, image_name):
    blob = service.get_blob_to_bytes(container_name=container, blob_name=image_name)
    img = Image.open(io.BytesIO(blob.content))

    return np.array(img)


def _get_annotations_from_blob(service, container):
    annotations = []
    blobs = service.list_blobs(container_name=container)

    for blob in blobs:
        annotation = service.get_blob_to_text(container_name=container, blob_name=blob.name)
        annotations.append(annotation)

    return annotations


def get_annotations_images(image_container, annotation_container):
    block_blob_service = _get_block_blob_service()

    annotation_blobs = _get_annotations_from_blob(block_blob_service, annotation_container)

    annotations = {annotation.name: annotation.content for annotation in annotation_blobs}

    return [(_get_image_from_blob(block_blob_service, image_container, key), value)
            for key, value in annotations.items()]


if __name__ == "__main__":
    print(get_annotations_images('pictures', 'code'))
