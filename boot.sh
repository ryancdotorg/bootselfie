#!/bin/bash
set -uo pipefail
trap 's=$?; echo ": Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR
IFS=$'\n\t'


export KERNEL_OFFSET=${KERNEL_OFFSET-0x0}

# calculate start address from kernel offset and set up breakpoint
BREAKPOINT="0x1$(printf '%04x' $(($KERNEL_OFFSET)))"
sed -Ei "s/^b 0x1[0-9a-f]{4}\$/b $BREAKPOINT/" start.bochs
make clean && make KERNEL_OFFSET=$KERNEL_OFFSET floppy && \
bochs -q -rc start.bochs -f bochsrc
