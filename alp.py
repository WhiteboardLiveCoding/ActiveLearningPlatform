import argparse
import numpy as np
import sys

from blob import get_annotations_images
from dataset import Dataset
from annotation import Annotation
from image_segmentation.picture import Picture
from image_segmentation.preprocessor import Preprocessor


def get_image_chars(image):
    characters = []
    lines = image.get_segments()

    for line in lines:
        words = line.get_segments()
        for word in words:
            characters.extend(word.get_segments())

    return characters


def parse_arguments():
    parser = argparse.ArgumentParser(usage='Active Learning Platform to keep on learning')
    parser.add_argument('-i', '--image-container', type=str, help='azure blob image container', default='pictures')
    parser.add_argument('-a', '--annotation-container', type=str,
                        help='azure blob annotation container', default='code')

    return parser.parse_args()


if __name__ == '__main__':
    print("Welcome to the Active Learning Platform")

    args = parse_arguments()
    dataset = Dataset()

    # Get all the (annotation, image) pairs from Azure Blob Storage
    annotated_images = get_annotations_images(args.image_container, args.annotation_container)

    # Generate a dataset from the blob data
    #   - Segment images into characters
    #   - Match lines, words and character to the annotations
    #   - Add the images to the datatset
    for (pre_image, annotation) in annotated_images:
        height, width, _ = pre_image.shape
        picture = Picture(pre_image, 0, 0, width, height, None)
        image = Preprocessor().process(picture)
        code = Annotation(annotation)

        print(code._annotation)

        image_characters = get_image_chars(picture)

        if len(image_characters) != len(code):
            continue

        for idx, character in enumerate(image_characters):
            char = character.get_segments()
            label = code[idx]

            img = np.reshape(char, 28*28)
            img = img.astype('float32')

            dataset.add_image(img, label)

    dataset_name = dataset.save()

    if not dataset_name:
        print("No new additions to the dataset.")
        sys.exit(69)


    # Move the dataset to the training directory

    # Run training and collect the model yaml and weights

    # Benchmark the results and upload the artifacts to Azure Blob Storage with a summary

    # Wait for 10 secs and try a clean shutdown
