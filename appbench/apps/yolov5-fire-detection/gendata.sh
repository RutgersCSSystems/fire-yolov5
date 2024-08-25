#!/bin/bash
set -x 
cd $BASE
source scripts/setvars.sh
cd $YOLO  
cd datasets
rm -rf fire
unzip datasets.zip
mkdir $YOLO/datasets/fire/train/images-orig
mkdir $YOLO/datasets/fire/train/labels-orig
cp $YOLO/datasets/fire/train/images/* $YOLO/datasets/fire/train/images-orig
rm -rf $YOLO/datasets/fire/train/images
cp $YOLO/datasets/fire/train/labels/* $YOLO/datasets/fire/train/labels-orig
rm -rf $YOLO/datasets/fire/train/labels
cd $YOLO
python copyimage.py 20 
