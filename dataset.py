import os
import numpy as np

from datetime import datetime
from scipy.io import loadmat, savemat


def check_output_dir_exists(dir_name):
    bin_dir = os.path.dirname(os.path.realpath(__file__)) + "/{}".format(dir_name)
    if not os.path.exists(bin_dir):
        os.makedirs(bin_dir)


class Dataset:

    def __init__(self, batch_size=32):
        self._changed = False

        self._train_images = list()
        self._train_labels = list()

        self._test_images = list()
        self._test_labels = list()

        self.batch_size = batch_size
        self._load_dataset()

    def _load_dataset(self):
        self._data = loadmat('assets/template-dataset.mat')

    def _append_to_dataset(self, test_data=False):
        if test_data:
            test_data = self._data['dataset'][0][0][1][0][0]
            self._data['dataset'][0][0][1][0][0][0] = np.append(test_data[0], self._test_images, axis=0)
            self._data['dataset'][0][0][1][0][0][1] = np.append(test_data[1], self._test_labels, axis=0)

            self._test_labels = list()
            self._test_images = list()
        else:
            train_data = self._data['dataset'][0][0][0][0][0]
            self._data['dataset'][0][0][0][0][0][0] = np.append(train_data[0], self._train_images, axis=0)
            self._data['dataset'][0][0][0][0][0][1] = np.append(train_data[1], self._train_labels, axis=0)

            self._train_labels = list()
            self._train_images = list()

    def add_image(self, image, label, test_data=False):
        if len(image) != len(self._data['dataset'][0][0][0][0][0][0][0]):
            raise Exception("Image data should be an array of length 784")

        reverse_mapping = {kv[1:][0]:kv[0] for kv in self._data['dataset'][0][0][2]}
        m_label = reverse_mapping.get(ord(label))

        if m_label is None:
            raise Exception("The dataset doesn't have a mapping for {}".format(label))

        if test_data:
            self._test_images.append(image)
            self._test_labels.append([m_label])
        else:
            self._train_images.append(image)
            self._train_labels.append([m_label])

        if len(self._test_images) >= self.batch_size or len(self._train_images) >= self.batch_size:
            self._append_to_dataset(test_data)

        if not self._changed:
            self._changed = True

    def save(self, do_compression=True):
        if not self._changed:
            return ""

        if len(self._test_images) > 0:
            self._append_to_dataset(test_data=True)

        if len(self._train_images) > 0:
            self._append_to_dataset()

        check_output_dir_exists("artifacts")
        file_name = "artifacts/alp.mat"

        savemat(file_name=file_name, mdict=self._data, do_compression=do_compression)

        return file_name
