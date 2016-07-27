#!/bin/bash

set -x

echo ${1}

export PART_9_OFFSET=$(( 512 * $(sfdisk -l -uS ${1}-image.bin | grep bin9 | awk '{ print $2 }')))
export PART_3_OFFSET=$(( 512 * $(sfdisk -l -uS ${1}-image.bin | grep bin3 | awk '{ print $2 }')))
echo $PART_9_OFFSET
echo $PART_3_OFFSET

mkdir -p ${1}-rootfs

mount -o ro,loop,offset=${PART_9_OFFSET} -t auto ${1}-image.bin ${1}-rootfs
mount -o ro,loop,offset=${PART_3_OFFSET} -t auto ${1}-image.bin ${1}-rootfs/usr
