import caspian
import serial


class HardwareNeuron:

    def __init__(self, nid, threshold, leak=-1, is_output=False):
        self.nid = nid
        self.threshold = threshold
        self.leak = leak
        self.is_output = is_output

    def to_config_packet(self, first_syn, syn_cnt):
        pck = bytearray(7)

        encoded_leak = 7 if self.leak == -1 else self.leak

        # Operation Code
        pck[0] = (1 << 4)

        # Neuron Address
        pck[1] = self.nid

        # Neuron Configuration
        pck[2] = self.threshold
        pck[3] = (self.is_output << 3) | encoded_leak

        # Synapse stuff
        pck[4] = first_syn >> 8
        pck[5] = first_syn & 255
        pck[6] = syn_cnt

        return pck


class HardwareSynapse:

    def __init__(self, syn_id, from_nid, to_nid, weight, delay):
        self.syn_id = syn_id
        self.from_nid = from_nid
        self.to_nid = to_nid
        self.weight = weight
        self.dealy = delay

    def to_config_packet(self):
        pck = bytearray(6)

        # Operation Code
        pck[0] = 1 << 5

        # Synapse Address
        pck[1] = self.syn_id >> 8
        pck[2] = self.syn_id & 255

        # Synapse Configuration
        pck[3] = self.weight
        pck[4] = self.to_nid
        pck[5] = self.delay

        return pck


class HardwareNetwork:

    def __init__(self, network):
        self.clear()
        self.convert(network)
        self.cur_time = 0
        self.target_time = 0

    def clear(self):
        self.neurons = list()
        self.synapses = list()
        self.nid_map = dict()
        self.cur_time = 0
        self.target_time = 0

    def convert(self, network):
        next_nid = 0

        for nid, n in network:
            is_output = (n.output_id >= 0)
            neuron = HardwareNeuron(next_nid, n.threshold, n.leak, is_output)

            self.neurons.append(neuron)
            self.nid_map[nid] = next_nid
            next_nid += 1

        # TODO: Synapses

    def send_config(self, ser):
        # INTENTIALLY SLOW AND NON-OPTIMAL FOR DEVELOPEMENT
        # WILL FIX LATER

        # Configure all neurons
        for neuron in self.neurons:
            packet = neuron.to_config_packet()  # todo
            ser.write(packet)
            resp = ser.read(1)

            if resp != bytes([112]):
                print('Error configuring neuron {}'.format(neuron.nid))
            else:
                print('Configured neuron {}'.format(neuron.nid))

        # Configure all synapses separately
        for synapse in self.synapses:
            packet = synapse.to_config_packet()
            ser.write(packet)
            resp = ser.read(1)

            if resp != bytes([112]):
                print('Error configuring synapse {}'.format(synapse.syn_id))
            else:
                print('Configured synapse {}'.format(synapse.syn_id))


class uCaspian:

    def _init__(self, port="/dev/ttyUSB0", buad=3000000):
        self.ser = serial.Serial(port, buad, timeout=0.5)

    def configure(self, net):
        self.net = HardwareNetwork(net)
        self.net.send_config(self.ser)

    def send_clear_activity(self):
        pck = bytes([4])
        self.ser.write(pck)
        resp = self.ser.read(1)

        if resp != bytes([12]):
            print("Error clearing activity")

    def send_clear_config(self):
        pck = bytes([8])
        self.ser.write(pck)
        resp = self.ser.read(1)

        if resp != bytes([12]):
            print("Error clearing network configuration")

    def get_metric(self, metric):
        pck = bytearray(2)

        pck[0] = 2
        pck[1] = metric

        self.ser.write(pck)
        resp = self.ser.read(4)

        if resp[0] != bytes([2]) or resp[1] != bytes([metric]):
            print("Error getting metric '{}'".format(metric))

        metric_val = pck[3]

        return metric_val

    def send_simulate(self, sim_time):
        pass

    def send_fire(self, input_id, value, time):
        pass
