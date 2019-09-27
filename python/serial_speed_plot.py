#!/usr/bin/env python3

import time
import random
import string
import serial

import matplotlib.pyplot as plt

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
        pass_or_fail = "PASS"
    else:
        pass_or_fail = "FAIL"
    
    print("{} -- Total Time: {:.6f} | Size: {:5} | Loopback Throughput: {:.3f} KB/s".format(pass_or_fail, total_time, msg_size, throughput))

    return total_time


with serial.Serial('/dev/ttyUSB0', 3000000, timeout=0.75) as ser:

    test_size = list()
    test_speed = list()

    n_tests = 20

    for i in range(1, 64, 4):
        result = 0
        for _ in range(n_tests):
            result += run_test(ser, i)
        result /= n_tests

        test_size.append(i)
        test_speed.append(result)

    for i in range(64, 1024, 64):
        result = 0
        for _ in range(n_tests):
            result += run_test(ser, i)
        result /= n_tests

        result = run_test(ser, i)
        test_size.append(i)
        test_speed.append(result)

    for i in range(1024, 4096+1, 128):
        result = 0
        for _ in range(n_tests):
            result += run_test(ser, i)
        result /= n_tests

        test_size.append(i)
        test_speed.append(result)

plt.plot(test_size, test_speed)
plt.show()

