### Compilation for changes made by Sudarsun for HazardMon project.
```
cd ioopt //source folder
source scripts/setvars.sh
cd appbench/apps/yolov5-fire-detection
./install_cuda.sh #only if you have and are running on GPU and installing CUDA
./compile.sh
sudo reboot  #only if you have and are running on GPU and installing CUDA
```

### Download the dataset
You can download the dataset and unzip it
```
cd $YOLO
cd datasets
Download from  https://drive.google.com/file/d/1TQKA9nzo0BVwtmojmSusDt5j02KWzIu9/view?usp=sharing
unzip -d ZIPFILENAME //You will see train and val folder
```

### Make the dataset larger to stress the system. Note this is only for the first time you are installing the application.
```
cd $BASE
source scripts/setvars.sh
cd $YOLO  //Navigate to the yolov5-fire-detection folder
./gendata.sh 20 //Scale the factor by 20 times
#mkdir datasets/fire/train/images-orig
#mkdir datasets/fire/train/labels-orig
#cp -r datasets/fire/train/images datasets/fire/train/images-orig
#cp -r datasets/fire/train/labels datasets/fire/train/labels-orig
#python copyimage.py 20 //Scale the factor by 20 times
```


### Running the training steps
```
./train-run-med.sh 20 //where 20 indicates the batch size
```
