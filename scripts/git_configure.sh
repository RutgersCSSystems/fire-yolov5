#!/bin/bash
"Configure scripts to repo"
git config credential.helper store
git config --global user.name "sudarsun"
git commit -am "test"
git push origin cleaned
