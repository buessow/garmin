#!/bin/bash

xmlstarlet select --text --template \
  --match '//device[app_types/app[@id="background"][@memory_limit>30000]]' \
  --value-of "concat('\"', @part_number, '\" => \"', @id, '\",')" \
  -n \
  ~/Downloads/devices.xml | sort
