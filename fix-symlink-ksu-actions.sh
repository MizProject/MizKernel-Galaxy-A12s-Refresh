#!/bin/bash

ROOT="$(pwd)"

case "$1" in
    "rKSU")
        ln -sf "$ROOT/root/rKSU/kernel" "$ROOT/drivers/kernelsu"
        exit
        ;;
    "nxtKSU")
        ln -sf "$ROOT/root/nxtKSU/kernel" "$ROOT/drivers/kernelsu"
        exit
        ;;
esac