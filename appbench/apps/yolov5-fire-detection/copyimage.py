import os
import shutil
import random
import sys
import subprocess

# Get the value of the YOLO environment variable
yolo_path = os.environ.get('YOLO')

# If YOLO environment variable is not set, we'll use an empty string
if yolo_path is None:
    print("Warning: $YOLO environment variable is not set.")
    yolo_path = ""

# Update the directory paths
source_image_directory = os.path.join(yolo_path, "datasets/fire/train/images-orig")
source_label_directory = os.path.join(yolo_path, "datasets/fire/train/labels-orig")
destination_image_directory = os.path.join(yolo_path, "datasets/fire/train/images")
destination_label_directory = os.path.join(yolo_path, "datasets/fire/train/labels")



def make_directory(directory_path):
    try:
        # Create the directory
        os.makedirs(directory_path)
        print(f"Directory '{directory_path}' created successfully.")
    except OSError as e:
        print(f"Error creating directory '{directory_path}': {e}")

def copy_directory_contents(source_dir, destination_dir):
    try:
        # Construct the shell command to copy directory contents
        command = f"cp {source_dir}/* {destination_dir}"

        # Execute the shell command
        subprocess.run(command, shell=True, check=True)

        print("Directory contents copied successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Error copying directory contents: {e}")


def delete_directory_contents(directory):
    try:
        # Delete the contents of the directory
        shutil.rmtree(directory)
        print("Directory contents deleted successfully.")
    except OSError as e:
        print(f"Error deleting directory contents: {e}")

def copy_files_with_labels(source_image_dir, source_label_dir, destination_image_dir, destination_label_dir, num_copies):
# Create the destination directories if they don't exist
    os.makedirs(destination_image_dir, exist_ok=True)
    os.makedirs(destination_label_dir, exist_ok=True)

    # Get a list of files in the source image directory
    image_files = [f for f in os.listdir(source_image_dir) if os.path.isfile(os.path.join(source_image_dir, f))]
    label_files = [f for f in os.listdir(source_label_dir) if os.path.isfile(os.path.join(source_label_dir, f))]

    # Copy files with different and reasonably large ending numbers
    for i in range(num_copies):
        for image_file in image_files:
            image_base, image_extension = os.path.splitext(image_file)
            label_file = f"{image_base}.txt"
            if label_file in label_files:
                # Generate new image file name with a random ending number
                new_image_file = f"{image_base}{random.randint(1000, 9999)}{image_extension}"
                source_image_path = os.path.join(source_image_dir, image_file)
                destination_image_path = os.path.join(destination_image_dir, new_image_file)
                shutil.copyfile(source_image_path, destination_image_path)

                # Copy label file with the same name but .txt extension
                source_label_path = os.path.join(source_label_dir, label_file)
                destination_label_path = os.path.join(destination_label_dir, label_file)
                shutil.copyfile(source_label_path, destination_label_path)

# Example usage

num_copies_per_file = int(sys.argv[1])

delete_directory_contents(destination_image_directory)
delete_directory_contents(destination_label_directory)

make_directory(destination_image_directory)
make_directory(destination_label_directory)


copy_directory_contents(source_image_directory, destination_image_directory)
copy_directory_contents(source_label_directory, destination_label_directory)

copy_files_with_labels(source_image_directory, source_label_directory, destination_image_directory, destination_label_directory, num_copies_per_file)
