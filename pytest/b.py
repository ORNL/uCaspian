#!/usr/bin/env python3
import neuro
import caspian

def run(p, neurons, sim_time):
    net = neuro.Network()
    net.set_properties(p.get_properties())
    
    for n in range(neurons):
        net.add_node(n)
        net.set_input(n, n)
        net.set_output(n, n)
        net.get_node(n).set("Threshold", 10)
        net.get_node(n).set("Delay", int(n % 16))
    
    for pre, post in zip(range(neurons-1), range(1, neurons)):
        net.add_edge(pre, post)
        net.get_edge(pre, post).set("Weight", 11)

    net.add_edge(neurons-1, 0)
    net.get_edge(neurons-1, 0).set("Weight", 11)

    p.load_network(net)
    
    for i in range(neurons):
        p.track_output(i)
    
    # Fires
    p.apply_spike(neuro.Spike(time=0, id=0, value=1))
    
    p.run(sim_time)
    
    for i in range(neurons):
        print(i, p.output_vector(i))

def main():
    neurons = 254
    sim_time = 3100

    sim = caspian.Processor({})
    print("Simulator")
    run(sim, neurons, sim_time)
    print("")

    # hwsim = caspian.Processor({"Backend": "uCaspian_Verilator", "Verilator": {"Trace_File": "a.fst"}})
    hwsim = caspian.Processor({"Backend": "uCaspian_Verilator"})
    print("Verilator")
    run(hwsim, neurons, sim_time)
    print('')

    """
    hw = caspian.Processor({"Backend": "uCaspian_USB"})
    print("HW")
    run(hw, neurons, sim_time)
    """


if __name__ == "__main__":
    main()

