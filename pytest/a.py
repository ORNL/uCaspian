#!/usr/bin/env python3
import neuro
import caspian

#p = caspian.Processor({})
p = caspian.Processor({"Backend": "uCaspian_Verilator", "Verilator": {"Trace_File": "a.fst"}})

net = neuro.Network()
net.set_properties(p.get_network_properties())

prefix = 0
a = prefix
b = prefix + 1

for i in range(prefix):
    net.add_node(i)
    net.get_node(i).set("Threshold", 0)
    net.get_node(i).set("Delay", 0)

net.add_node(a)
net.add_node(b)
net.add_edge(a, b)

net.get_node(a).set("Threshold", 10)
net.get_node(b).set("Threshold", 10)
net.get_edge(a, b).set("Weight", 11)

net.get_node(a).set("Delay", 15)
net.get_node(b).set("Delay", 0)

for i in range(prefix+2):
    net.set_input(i, i)
    net.set_output(i, i)

p.load_network(net)

for i in range(prefix+2):
    p.track_output_events(i)

# Fires
p.apply_spike(neuro.Spike(time=0, id=a, value=1))
p.apply_spike(neuro.Spike(time=5, id=a, value=1))
p.apply_spike(neuro.Spike(time=10, id=a, value=1))
p.apply_spike(neuro.Spike(time=20, id=a, value=1))

p.run(50)

for i in range(prefix, prefix+2):
    print(i, p.output_vector(i))
