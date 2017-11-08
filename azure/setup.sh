#!/bin/sh

echo "Bootstraping Active Learning Platform..."

echo "Checking requirements..."
command -v git >/dev/null 2>&1 || { echo >&2 "Missing Git. Aborting."; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo >&2 "Missing Python. Aborting."; exit 1; }
command -v pip3 >/dev/null 2>&1 || { echo >&2 "Missing Pip. Aborting."; exit 1; }

echo "Cloning WhiteboardLiveCoding/ActiveLearningPlatform..."
git clone https://github.com/WhiteboardLiveCoding/ActiveLearningPlatform.git alp

echo "Changing directories..."
cd alp

echo "Installing project requirements..."
pip3 install -r requirements.txt

echo "Running [alp.py]..."
python3 alp.py
