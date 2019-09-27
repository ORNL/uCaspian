# uCaspian
"micro-caspian" can be thought of as a neuromorphic equivalent of a microcontroller. This is a small design with a minimal feature set and limited performance designed for low cost, low power embedded applications. The target FPGA is the Lattice ice40UP5k.

A few details:
  - 256 neurons, 4096 synapses
  - 8 bit unsigned neuron thresholds
  - exponential charge leak
  - 8 bit signed synaptic weights
  - no connectivity restrictions
  - variable length packets
  - activity dependent evaluation
