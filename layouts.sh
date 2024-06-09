#!/bin/sh

xmlstarlet select --text --template \
  --match '//device[app_types/app[@id="background"][@memory_limit>30000]]/datafieldlayouts/layout/field' \
  --value-of 'concat(../../../@id, " ", ../@name, " L", @width, "x", @height, "_", @obscurity)' -n \
  devices.xml
