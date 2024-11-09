#!/bin/bash -e

#d=$(dirname "$(which monkeyc)")/../..
#echo $d

    f="$@" 
    deviceId=`jq -r .deviceId "$f"`
    displayName=`jq -r .displayName "$f"`
    deviceGroup=`jq -r .deviceGroup "$f"`
    hardwarePartNumber=`jq -r .hardwarePartNumber "$f"`
    width=`jq -r .resolution.width "$f"`
    height=`jq -r .resolution.height "$f"`
    bitsPerPixel=`jq -r .bitsPerPixel "$f"`
    connectIQVersion=`jq -r .partNumbers[0].connectIQVersion "$f"`
    watchFaceMem=`jq -r '.appTypes[] | select(.type == "watchFace") | .memoryLimit' "$f"`
    watchApp=`jq -r '.appTypes[] | select(.type == "watchApp") | .memoryLimit' "$f"`
    glance=`jq -r '.appTypes[] | select(.type == "glance") | .memoryLimit' "$f"`
    datafield=`jq -r '.appTypes[] | select(.type == "datafield") | .memoryLimit' "$f"`
    background=`jq -r '.appTypes[] | select(.type == "background") | .memoryLimit' "$f"`

    echo $deviceId,,N,N,N,$displayName,\"$deviceGroup\",$hardwarePartNumber,$[width]x$height,$bitsPerPixel,$connectIQVersion,TRUE,$watchFaceMem,$watchApp,$glance,$datafield,$background


