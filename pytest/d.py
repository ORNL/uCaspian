#!/usr/bin/env python3
import neuro
import caspian

def run(p):
    net = neuro.Network()
    net.set_properties(p.get_properties())

    for n in range(7):
        net.add_node(n)
        net.set_output(n, n)
        net.get_node(n).set("Leak", -1)

    for n in range(4):
        net.set_input(n, n)

    net.get_node(0).set("Threshold", 10)
    net.get_node(1).set("Threshold", 11)
    net.get_node(2).set("Threshold", 12)
    net.get_node(3).set("Threshold", 13)
    net.get_node(4).set("Threshold", 210)
    net.get_node(5).set("Threshold", 211)
    net.get_node(6).set("Threshold", 212)

    net.get_node(0).set("Delay", 1)
    net.get_node(1).set("Delay", 2)
    net.get_node(2).set("Delay", 2)
    net.get_node(3).set("Delay", 0)
    net.get_node(4).set("Delay", 0)
    net.get_node(5).set("Delay", 0)
    net.get_node(6).set("Delay", 0)

    net.add_edge(0, 4)
    net.add_edge(1, 5)
    net.add_edge(2, 6)
    # net.add_edge(3, 6)

    net.get_edge(0, 4).set("Weight", 62)
    net.get_edge(1, 5).set("Weight", 63)
    net.get_edge(2, 6).set("Weight", 64)
    # net.get_edge(3, 6).set("Weight", 40)
    
    p.load_network(net)
    
    for i in range(7):
        p.track_output(i)
    
    # Fires
    for t in range(7):
        p.apply_spike(neuro.Spike(time=3*t, id=0, value=1))
        p.apply_spike(neuro.Spike(time=2*t, id=1, value=1))
        p.apply_spike(neuro.Spike(time=2*t, id=2, value=1))
    
    p.run(50)
    
    for i in range(7):
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

