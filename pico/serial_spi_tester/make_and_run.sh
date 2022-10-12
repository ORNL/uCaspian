#!/bin/bash
pushd build
make && openocd -f interface/raspberrypi-swd.cfg -f target/rp2040.cfg -s ~/Data/pico/openocd/tcl/ -c "program test.elf verify reset exit"
popd
