#!/bin/bash
set -x
git pull
git commit -am "$1"
git push origin https://github.com/RutgersCSSystems/ioopt refactor-sudarsun-perf-4
