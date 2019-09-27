#!/usr/bin/env python3
import binascii
import time
from serial import Serial
from test_func import *
import sys

with Serial('/dev/ttyUSB0', 3000000, timeout=0.33) as ser:
    data_in = open(sys.argv[1], 'rb').read()
    ser.write(data_in)
    get_resp_until_timeout(ser, 'out_py.bin')
