#!/usr/bin/env python3
import binascii
from serial import Serial

def make_clear_cfg():
    return bytes([8])


def make_clear_act():
    return bytes([4])


# open interval [syn_start, syn_end)
def make_ncfg(addr, threshold, leak=-1, delay=0, output_en=0, syn_start=0, syn_end=0):
    syn_cnt = syn_end - syn_start
    cfg_byte = (delay << 4) | (output_en << 3) | (leak+1)
    return bytes([16, addr, threshold, cfg_byte, (syn_start >> 8) & 255, syn_start & 255, syn_cnt])


def make_scfg(addr, weight, target):
    return bytes([32, (addr >> 8) & 255, addr & 255, weight, target])


def make_step(steps):
    return bytes([1, steps])


def make_null():
    return bytes([0])


def make_fire(input_id, value):
    return bytes([ (1 << 7) | input_id, value])


def make_metric(addr):
    return bytes([2, addr])


def send_clear_cfg(ser):
    cmd = make_clear_cfg()
    print('Send clear cfg: ', binascii.hexlify(cmd), ' ', end='')
    ser.write(cmd)
    get_resp(ser)


def send_clear_act(ser):
    cmd = make_clear_act()
    print('Send clear actvity: ', binascii.hexlify(cmd), ' ', end='')
    ser.write(cmd)
    get_resp(ser)


def send_ncfg(ser, addr, threshold, leak=-1, delay=0, output_en=0, ack=True, disp=True):
    cfg_cmd = make_ncfg(addr, threshold, leak, delay, output_en)
    ser.write(cfg_cmd)

    if ack is True:
        if disp:
            print('Send cfg: ', binascii.hexlify(cfg_cmd), ' ', end='')
        get_resp(ser, disp=disp)
    else:
        if disp:
            print('Send cfg: ', binascii.hexlify(cfg_cmd))

def send_scfg(ser, addr, weight, target, ack=True, disp=True):
    cfg_cmd = make_scfg(addr, weight, target)
    ser.write(cfg_cmd)

    if ack is True:
        if disp:
            print('Send cfg: ', binascii.hexlify(cfg_cmd), ' ', end='')
        get_resp(ser, disp=disp)
    else:
        if disp:
            print('Send cfg: ', binascii.hexlify(cfg_cmd))


def send_step(ser, steps):
    cmd = make_step(steps)
    print('Send step: ', binascii.hexlify(cmd))
    ser.write(cmd)


def send_fire(ser, input_id, value):
    cmd = make_fire(input_id, value)
    print('Send fire: ', binascii.hexlify(cmd))
    ser.write(cmd)


def get_metric(ser, addr):
    cmd = make_metric(addr)
    print('Get metric: ', binascii.hexlify(cmd))
    ser.write(cmd)
    return get_resp(ser, 3)


def get_resp(ser, length=1, disp=True):
    resp = ser.read(length)
    if disp:
        print('Response size: ', len(resp), ' Response: ', binascii.hexlify(resp))
    return (resp, len(resp) == length)


def get_resp_until_timeout(ser, to_file = False):
    n = 0
    chunk = 128
    not_timeout = True

    if to_file != False:
        f = open(to_file, 'wb')

    while not_timeout and n < 10:
        resp = ser.read(chunk)
        if to_file != False:
            f.write(resp)

        print('Data: ', binascii.hexlify(resp))
        n += 1
        if len(resp) != chunk:
            not_timeout = False


