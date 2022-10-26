#include "Vucaspian.h"
#include "verilated.h"
#include "verilated_fst_c.h"

#include "fifo.hpp"

#include <cstdlib>
#include <iostream>

int main(int argc, char **argv, char **env)
{
    std::string trace_name = "trace.fst";
    uint64_t max_steps = 8192;
    uint64_t steps = 0;
    int rand_io = 0;

    //Verilated::commandArgs(argc, argv);
    
    if(argc < 3)
    {
        std::cerr << "Usage: " << argv[0] << " input_file output_file (max_steps) (trace_file) (rand_io)" << std::endl;
        exit(1);
    }

    // input packets & output packets from cmd line arguments
    std::string input_file = argv[1];
    std::string output_file = argv[2];

    if(argc >= 4)
        max_steps = atoi(argv[3]);

    if(argc >= 5)
        trace_name = argv[4];

    if(argc >= 6)
        rand_io = atoi(argv[5]);

    if(rand_io > 0)
        srand(rand_io);

    Vucaspian top;

    ByteFifo fifo_in (&(top.sys_clk), &(top.read_rdy),  &(top.read_vld),  &(top.read_data),  true,  (rand_io != 0));
    ByteFifo fifo_out(&(top.sys_clk), &(top.write_rdy), &(top.write_vld), &(top.write_data), false, (rand_io != 0));

    // Load input
    fifo_in.push_from_file(input_file);

    // logging to fst file for viewing in GtkWave
    Verilated::traceEverOn(true);
    VerilatedFstC fst;
    top.trace(&fst, 99);
    fst.open(trace_name.c_str());

    // Initialize ports
    top.sys_clk = 1;
    top.reset = 1;
    
    while(!Verilated::gotFinish())
    {
        if(steps > 2) top.reset = 0;

        for(int c = 0; c < 2; ++c)
        {
            fst.dump(2*steps+c);

            top.sys_clk = !top.sys_clk;

            // update design
            top.eval();

            // update fifos on rising edge
            fifo_in.eval(top.sys_clk, top.reset);
            fifo_out.eval(top.sys_clk, top.reset);
        }

        if(steps > max_steps) break;

        steps++;
    }

    // write output
    fifo_out.pop_to_file(output_file);

    fst.close();

    return 0;
}
