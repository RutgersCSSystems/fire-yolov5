#!/bin/bash

dd iflag=fullblock if=/dev/urandom of=datafile bs=128M count=160
