# Packet Specification for uCaspian

Each packet is variable length with each segment consisting of 1 or more bytes. This specification is designed for low bandwidth embedded interfaces like UART or SPI.

Note: Currently multi-byte values (e.g. 32 bit time) are represented in big endian byte order.

## Host -> uCaspian

Every operation begins with a 1 byte op code followed by a specified sequence of additional bytes. Each operation has a varible length. In the case of the configure synapse range command, the length of the command is encoded immediately following the op code.

### Input Fire
```
OPCODE: "1XXXXXXX" -- the Xs encode the input id
INPUT VALUE: 1 Byte
```
Total Size: 2 Bytes per Input Fire

This format allows for up to 127 input neurons.

### No Op 
```
OPCODE: "00000000"
```
Total Size: 1 Byte

### Simulate
```
OPCODE: "00000001"
NUMBER OF ADDITIONAL STEPS: 1 Byte
```
Total Size: 2 Bytes

### Get Metric
```
OPCODE: "00000010"
METRIC ADDRESS: 1 Byte
```
Total Size: 2 Bytes

The metric register is reset after reading.

Further details are discussed in the Caspian -> Host section. 

### Clear Activity
```
OPCODE: "00000100"
```
Total Size: 1 Byte

### Clear Configuration
```
OPCODE: "00001000"
```
Total Size: 1 Byte

### Configure Neuron
```
OPCODE: "00010000"
NEURON ADDRESS: 1 Byte
THRESHOLD: 1 Byte
OTHER CONFIG: 1 Byte
  DELAY: [7:4], axonal delay
  OUTPUT:  [3], active high for output enable
  LEAK:  [2:0], encoding of leak_value (-1, 0, 1, 2, 3, 4)
SYN START: 2 Bytes (12 bits)
SYN COUNT: 1 Byte
```
Total Size: 7 Bytes per Neuron

### Configure Synapse
```
OPCODE: "00100000"
SYN ADDRESS: 2 Bytes (12 bits)
SYN CONFIG: 
  WEIGHT: 1 Byte
  TARGET: 1 Byte
```
Total Size: 5 Bytes per Synapse

### Configure Synapses
```
OPCODE: "01000000"
SYN START: 2 Bytes (12 bits)
SYN END: 2 Bytes (12 bits)
SYN CONFIG: (repeat for [start, end])
  WEIGHT: 1 Byte
  TARGET: 1 Byte
```
Total Size: 5 Bytes + 2 Bytes per Synapse

This is a more efficient encoding when multiple synapses are being loaded.

## uCaspian -> Host

### Configuration Ack
```
OPCODE: "01110000"
```
Total Size: 1 Byte

An ack is issued 1:1 for each configuration packet. This means only a single ack is issued for the "Configure Synapses" command.

### Clear Ack
```
OPCODE: "00001100"
```
Total Size: 1 Byte

An ack is issued 1:1 for each clear packet.

### Get Metric
```
OPCODE: "00000010"
METRIC ADDRESS: 1 Byte
METRIC VALUE: 1 Bytes
```
Total Size: 3 Bytes

Example metrics include: number of synaptic operations, number of neuron fires, energy/power monitoring

One possible addition is to have outputs counted as a metric allowing the total number of fires to be fetched & output fire packets to be disabled.

### Time Update
```
OPCODE: "00000001"
TIME: 4 Bytes
```
Total Size: 5 Bytes

Time updates are sent when the current simulate call is complete or when new output fires are sent. This time is "absolute", but being only 32 bits, there is a chance of overflow during operation. The host should be mindful of this when interpreting outputs.

### Output Fire
```
OPCODE: "10000000"
NEURON ADDRESS: 1 Byte
```
Total Size: 2 Bytes

Each output fire corresponds to the last time update packet sent. Output fires have no value. The specified neuron address corresponds to the internal neuron index, not a specific output id.
