#!/bin/bash
set -x
git pull https://github.com/RutgersCSSystems/ioopt refactor-sudarsun-perf-4
git commit -am "$1"
git push origin #https://github.com/RutgersCSSystems/ioopt refactor-sudarsun-perf-4
