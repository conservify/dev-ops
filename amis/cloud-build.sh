#!/bin/bash

REMOTE=code

rsync -vua --exclude "build" . ${REMOTE}:ami

ssh ${REMOTE} "cd ami && make clean && make bare-ami -j4"
