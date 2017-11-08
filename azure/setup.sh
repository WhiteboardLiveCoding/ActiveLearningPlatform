#!/bin/sh

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

echo "Bootstraping Active Learning Platform..."

echo "Checking requirements..."
command -v git >/dev/null 2>&1 || { echo "Missing git."; install_git; }
command -v python3 >/dev/null 2>&1 || { echo "Missing python."; install_python3; }
command -v pip3 >/dev/null 2>&1 || { echo "Missing pip."; install_pip3; }

echo "Cloning WhiteboardLiveCoding/ActiveLearningPlatform..."
git clone https://github.com/WhiteboardLiveCoding/ActiveLearningPlatform.git alp

echo "Changing directories..."
cd alp

echo "Installing project requirements..."
pip3 install -r requirements.txt

echo "Running [alp.py]..."
python3 alp.py
