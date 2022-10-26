# SRAM Specification for uCaspian

**This is currently a bit of out of date. It will be updated after some major changes are complete.**

## System I/O

The system will buffer all I/O whether it is over UART, SPI, or another interface.

### SRAMs

**Rx FIFO** - 8x512

All incoming data can be buffered into a 1 byte wide FIFO implemented as a single EBR. Optionally, the read and write ports can be in separate clock domains.

**Tx FIFO** - 8x512

All outgoing data can be buffered into a 1 byte wide FIFO implemented as a single EBR. Optionally, the read and write ports can be in separate clock domains.

## Neurons

### Properties

 * Threshold = 8 bits
 * Leak value = 3 bits
 * First Synapse Index = 11 bits
 * Synapse Count = 8 bits

The outgoing synapses for each neuron _must_ have contiguous indicies. The first outgoing synapse is stored as its full index. The neuron then stores the number of synapses -- up to 256.

### State

 * Charge = 16 bits
 * Last Fire Time = up to 16 bits

### SRAMs

**Neuron Configuration RAM** - (2) 16x256

This RAM is effectively 32x256 across two parallel 16x256 BRAMs. The RAM contains all of the neuron properties. None of these values are mutable during evaluation. Modification must occur through configuration packets.

**Neuron Charge** - 16x256

Each neuron may store up to 16 bits of charge. The memory address corresponds to the neuron index.

**Neuron Leak Status** - 16x256

Caspian must store the time of the last (incoming) fire in order to calculate the LIF leak. After an extended period without firing, this may be reset, and the neuron charge can be assumed to return to zero.

## Dendrites

### SRAMs

**Dendrite Charge RAM** - 16x256

Intermediate storage for charge accumulated in a given cycle. The dendrite index corresponds with the neuron index.

## Synapses

### Properties

 * Weight = 8 bits
 * Delay = 4 bits

### State

 * Activity = 1 bit
 * Delay Shift Register = 2^4 = 16 bits

### SRAMs

**Synapse Weights & Targets** - (8) 16x256

This stores the synaptic weight (8 bits) and the target neuron (8 bits) in a single 16-bit RAM line.

The implemention currently intended to use two separate synapse processing pipelines, so each will have 4 of these RAMs.

Note: This could possibly be moved over to SPRAMs rather than EBRs.

**Synapse Delays** - (2) 4x1024

This stores the synaptic delay configuration. Each synapse pipeline will have one of these.

**Synapse Delay Virtual Shift Registers** - (8) 16x256

This stores the 16 bit status of the synaptic delay virtual shift register. 

**Synapse Activity** - (2) 16x256

Bit field of activity to determine which synapses should be processed.
