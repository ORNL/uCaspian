#!/usr/bin/env python3
import binascii
import time
from serial import Serial
from test_func import *

with Serial('/dev/serial0', 115200, timeout=0.33) as ser:
    print('Clear Configuration')
    send_clear_cfg(ser)

    print('Configure')
    for n in range(7):
        send_ncfg(ser, n, 2*n, output_en=1)

    # basic fire test
    print('Fire value 100 to 0-6')
    for n in range(7):
        send_fire(ser, n, 100)
        send_step(ser, 2)
        get_resp(ser, 7) # time update & fire output

    send_step(ser, 63)
    get_resp(ser, 5)

    # clear activity
    print('Clear Activity')
    send_clear_act(ser)

    # this won't trigger a fire
    print('Send fire which does not cause output')
    send_fire(ser, 10, 19)
    send_step(ser, 2)
    get_resp(ser, 5)

    # this will then trigger the fire
    print('Send fire which _does_ cause output')
    send_fire(ser, 10, 2)
    send_step(ser, 2)
    get_resp(ser, 7)

    # Get a fake metric
    print('Get a fake metric (0x01)')
    get_metric(ser, 1)

    print('Clear configuration')
    send_clear_cfg(ser)
    send_clear_act(ser)

    print('Load new config')
    for n in range(12):
        send_ncfg(ser, n, 255 - n, output_en=1)

    print('Fire value 100 to 0-11')
    for n in range(12):
        send_fire(ser, n, 100)
    send_step(ser, 2)
    get_resp(ser, 5)

    print('Fire value 100 to 11 x 3 which will cause an output')
    send_fire(ser, 11, 100)
    send_fire(ser, 11, 100)
    send_fire(ser, 11, 100)
    send_step(ser, 2)

    get_resp(ser, 7)

    get_resp_until_timeout(ser)
