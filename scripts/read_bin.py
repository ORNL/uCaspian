#!/usr/bin/env python3
import sys

print("FILE: {}".format(sys.argv[1]))

class Ack:
    def __init__(self, ack_type, count):
        self.ack_type = ack_type
        self.count = count

    def __str__(self):
        return "{} Ack x {}".format(self.ack_type, self.count)

class Metric:
    def __init__(self, address, value):
        self.address = address
        self.value = value

    def __str__(self):
        return "Metric - Address {} = {}".format(self.address, self.value)

class TimeUpdate:
    def __init__(self, t):
        self.time = t

    def __str__(self):
        return "Time: {}".format(self.time)

class Fire:
    def __init__(self, neurons):
        self.neurons = sorted(neurons)

    def __str__(self):
        return "Fire at " + str(self.neurons)


packets = list()
neurons = list()
last_op = 0
op_cnt  = 0
done = False

# Do stuff
with open(sys.argv[1], 'rb') as f:

    while True:
        opcode = f.read(1)
        opcode = int.from_bytes(opcode, "little")

        if opcode != last_op or done:

            if last_op == (16+32+64):
                packets.append(Ack("Config", op_cnt))
            elif last_op == (4+8):
                packets.append(Ack("Clear", op_cnt))
            elif last_op == 2:
                # this is appended as it is read
                pass
            elif last_op == 1:
                # this appended as it is read
                pass
            elif last_op == 128:
                packets.append(Fire(neurons))
                pass

            neurons = list()
            op_cnt = 1
        else:
            op_cnt += 1
            
        last_op = opcode

        if done:
            print("Finished reading")
            break
        
        if opcode == (16+32+64) or opcode == (4+8):
            # do nothing here
            done = False
        elif opcode == 2:
            address = int.from_bytes(f.read(1), "little")
            value = int.from_bytes(f.read(1), "little")
            packets.append(Metric(address, value))
        elif opcode == 1:
            time = int.from_bytes(f.read(4), "big")
            packets.append(TimeUpdate(time))
        elif opcode == 128:
            address = int.from_bytes(f.read(1), "little")
            neurons.append(address)
        else:
            done = True

for pck in packets:
    print(pck)
