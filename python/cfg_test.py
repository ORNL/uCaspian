#!/usr/bin/env python3
import time
from serial import Serial
from test_func import *

def config_test(ser, n_neurons, n_synapses):
    ts = time.perf_counter()

    for n in range(n_neurons):
        send_ncfg(ser, n, 255-n, output_en=1, ack=False, disp=False)
    resp, resp_code = get_resp(ser, n_neurons, disp=False)

    if not resp_code:
        raise RuntimeError("Error with neuron config ack")
    
    for s in range(n_synapses):
        send_scfg(ser, s, s // 8, 255 - s // 8, ack=False, disp=False)
    resp, resp_code = get_resp(ser, n_synapses, disp=False)

    if not resp_code:
        raise RuntimeError("Error with synapse config ack")

    te = time.perf_counter()

    return te-ts


def run_multi(ser, n_runs, n_neurons, n_synapses):
    print('Neurons: {} Synapses: {}'.format(n_neurons, n_synapses))

    t_sum = 0
    for num in range(n_runs):
        elapsed_time = config_test(ser, n_neurons, n_synapses)
        t_sum += elapsed_time

    print('Average Time: {:.6f}'.format(t_sum / n_runs))

    return t_sum / n_runs


with Serial('/dev/ttyUSB0', 3000000, timeout=0.3) as ser:
    
    run_multi(ser, 25, 256, 2048)
    run_multi(ser, 50, 128, 1024)
    run_multi(ser, 50, 50, 350)
    run_multi(ser, 100, 20, 60)
    run_multi(ser, 100, 10, 25)
    run_multi(ser, 100, 5, 15)

    get_resp_until_timeout(ser)
