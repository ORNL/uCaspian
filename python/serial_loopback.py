#!/usr/bin/env python3

import time
import random
import string
import serial

def randomString(stringLength=10):
    """Generate a random string of fixed length """
    letters = string.ascii_lowercase
    return ''.join(random.choice(letters) for i in range(stringLength))

def run_test(ser, length):
    wr_msg = randomString(length)
    encoded = bytes(wr_msg, 'ascii')
    msg_size = len(encoded)

    t0 = time.perf_counter()
    ser.write(encoded)
    rd_msg = ser.read(msg_size)
    t2 = time.perf_counter()

    total_time = (t2-t0)
    throughput = (msg_size / total_time) / 1000

    if(rd_msg == encoded):
        print("PASS -- Total Time: {:.6f} | Size: {:5} | Loopback Throughput: {:.3f} KB/s".format(total_time, msg_size, throughput))
    else:
        pass_or_fail = "FAIL"
        print("FAIL -- Total Time: {:.6f} | Size: {:5}".format(total_time, msg_size))



with serial.Serial('/dev/ttyUSB0', 3000000, timeout=0.5) as ser:

    for i in range(1, 64, 1):
        run_test(ser, i)

    for i in range(64, 1024, 16):
        run_test(ser, i)

    for i in range(1024, 4096, 128):
        run_test(ser, i)

    for i in range(4096, 8193, 1024):
        run_test(ser, i)
