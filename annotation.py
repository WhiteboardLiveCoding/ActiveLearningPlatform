

def _strip_annotation(annotation):
    return ''.join(annotation.split())


class Annotation:

    def __init__(self, annotation):
        self._annotation = _strip_annotation(annotation)

    def __len__(self):
        return len(self._annotation)

    def __getitem__(self, item):
        return self._annotation[item]
