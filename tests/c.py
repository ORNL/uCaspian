#!/usr/bin/env python3
import neuro
import caspian

def run(p):
    net = neuro.Network()
    net.set_properties(p.get_properties())

    neurons = 100
    sim_time = 10
    
    for n in range(neurons):
        net.add_node(n)
        net.set_input(n, n)
        net.set_output(n, n)
        net.get_node(n).set("Threshold", 10)
        net.get_node(n).set("Delay", 0)
        net.get_node(n).set("Leak", -1)

    net.get_node(0).set("Delay", 1)
    net.get_node(neurons-1).set("Threshold", 0)

    for post in range(1, neurons-1):
        if post % 2 == 0: 
            w = 11
        else:
            w = 9

        net.add_edge(0, post)
        net.get_edge(0, post).set("Weight", w)

    for pre in range(1, neurons-1):
        if pre % 2 == 0:
            w = -2
        else:
            w = 5

        net.add_edge(pre, neurons-1)
        net.get_edge(pre, neurons-1).set("Weight", w)
    
    p.load_network(net)
    
    for i in range(neurons):
        p.track_output(i)
    
    # Fires
    p.apply_spike(neuro.Spike(time=0, id=0, value=1))
    p.apply_spike(neuro.Spike(time=1, id=0, value=1))
    
    p.run(sim_time)
    
    for i in range(neurons):
        print(i, p.output_vector(i))

def main():
    sim = caspian.Processor({})
    print("Simulator")
    run(sim)
    print("")

    hwsim = caspian.Processor({"Backend": "uCaspian_Verilator", "Verilator": {"Trace_File": "a.fst"}})
    # hwsim = caspian.Processor({"Backend": "uCaspian_Verilator"})
    print("Verilator")
    run(hwsim)
    print('')

    """
    hw = caspian.Processor({"Backend": "uCaspian_USB"})
    print("HW")
    run(hw)
    """


if __name__ == "__main__":
    main()

