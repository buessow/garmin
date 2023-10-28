#!/bin/sh

manifest=$1

devices=$(xmlstarlet select --text --template \
  --match '/iq:manifest/iq:application/iq:products' \
  --value-of '//iq:product/@id' \
  -n "$1")

echo Devices: $devices
for d in $(echo $devices); do
  bazel run $(dirname $1) -c opt --cpu $d
done
