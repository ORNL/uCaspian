#!/usr/bin/env bash

# This lowers the FTDI driver latency from ~16ms to ~2ms
#echo 2 > /sys/bus/usb-serial/devices/ttyUSB0/latency_timer

## This is another option to lower the latency -- it defaults to 1ms
setserial /dev/ttyUSB0 low_latency
