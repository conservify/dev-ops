#!/bin/bash

REMOTE=code

rsync -vua --exclude "build" . ${REMOTE}:ami

ssh ${REMOTE} "cd ami && make clean && make ami -j4"
