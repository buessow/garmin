#!/bin/sh

manifest=$1


  #--match '/iq:manifest/iq:application/iq:products' \
devices=$(xmlstarlet select --text --template \
  --value-of '//iq:product/@id' \
  -n "$1")

echo Devices: $devices
for d in $(echo $devices); do
  device=$d  make $(dirname $1)/run
done
