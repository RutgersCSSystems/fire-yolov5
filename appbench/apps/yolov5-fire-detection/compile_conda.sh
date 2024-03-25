#!/bin/bash

# Passing --force-base should force us to use the base env
should_force_base() {
	for arg in "$@"; do
		if [[ $arg == "--force-base" ]]; then
			return 0
		fi
	done
	return 1
}

# This assumes a conda environment
if [ -z "$CONDA_DEFAULT_ENV" ]; then
	echo "Not in a conda environment, exiting."
	echo "If not using conda, please use ./compile.sh"
	exit 1
fi

# We should make sure we're not in a base environment
echo "Conda environment: $CONDA_DEFAULT_ENV"
if [ "$CONDA_DEFAULT_ENV" = "base" ]; then
	if should_force_base "$@"; then
		echo "--force-base was passed, will install into base conda env"
	else
		echo "Error: Will not install into base conda environment"
		echo "Call ./compile_conda.sh --force-base to override"
		exit 1
	fi		
fi

# Bring in yolov5
echo "Compiling..."
git clone https://github.com/ultralytics/yolov5
if [ -z "yolov5" ]; then
	echo "git clone may have failed: yolov5 folder does not exist"
	exit 1
fi
cd yolov5

# Install the required packages
echo "Installing required packages..."
conda install pip -y
pip install -r requirements.txt

# Bring in the dataset
echo "Downloading dataset..."
cd ..
mkdir -p datasets
pip install gdown
gdown https://drive.google.com/uc?id=1TQKA9nzo0BVwtmojmSusDt5j02KWzIu9

# Make sure fire.zip exists and was successfully downloaded from google drive
if [ -f fire.zip ]; then
	echo "Unzipping fire.zip..."
	# Unzip fire.zip into the datasets directory
	unzip fire.zip -d datasets
else
	echo "Error: fire.zip does not exist, may have failed to download"
	exit 1
fi

#sudo apt update
#sudo apt-get install pip -y
#sudo apt-get update && sudo apt-get install libgl1

