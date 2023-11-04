#!/bin/sh

adb $@ forward tcp:7381 tcp:7381
adb $@ forward tcp:28891 tcp:28891

