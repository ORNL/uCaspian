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

## Installing Open-Source Toolchain

### Install OSS CAD Suite (Required)

  1. Navigate to project repository. <https://github.com/YosysHQ/oss-cad-suite-build>

  2. Download release and extract to home directory.
  3. Add or source toolchain. See [installation](https://github.com/YosysHQ/oss-cad-suite-build#installation).

      ```bash
      export PATH="<extracted_location>/oss-cad-suite/bin:$PATH"

      or

      source <extracted_location>/oss-cad-suite/environment
      ```

### Setup upduino dev file and group permissions

Add [rules/upduinov3.rules](rules/upduinov3.rules) to /etc/udev/rules.d on Ubuntu to allow using the upduino without root.

You also need to be added to the `dialout` group.

### Install Verible (Optional)

Verible has useful system verilog linting and formating tools.

  1. Navigate to project repository. <https://github.com/chipsalliance/verible>

  2. Download release and extract to home directory. The release has bin and share which are both extracted to `~/bin` and `~/share` respectivly.

## Building and running on UPduino

1. Clone the neuromorphic framework.  
  
    ```bash
    git clone git@code.ornl.gov:neuromorphic-computing/framework.git
    ```

2. Build the framework environment.
  
    ```bash
    bash scripts/create_env.sh
    ```

3. Source the framework environment
  
    ```bash
    source pyframework/bin/activate
    ```

4. Clone µCaspian to processors/caspian.

    ```bash
    cd processors/caspian
    git clone git@code.ornl.gov:neurohw/ucaspian.git 
    ```

5. Checkout UPduino branches.

    ```bash
    git checkout 7ry/new_updruino
    cd ucaspian
    git checkout 7ry/new_updruino
    ```

6. Build and load ucaspian FPGA image.

    ```bash
    # In framework/processors/caspian/ucaspian
    make flash
    ```

7. Build Verilator software simulation source.

    ```bash
    # In framework/processors/caspian/ucaspian
    make test
    ```

8. Run test python script to test connection to FPGA. You should see output data and see the LED on the FPGA blink.

    ```bash
    # In framework/processors/caspian/ucaspian

    pip install pyserial

    python python/basic_test.py 
    ```

9. Run caspian passthrough test. You should see output which matches `./bin/pass_bench sim 5 5 10`.

    ```bash
    cd ..
    # In framework/processors/caspian
    make clean
    make utils
    ./bin/pass_bench ucaspian 5 5 10

    ```

10. To configure the caspian processor to run using hardware, add `{"Backend": "uCaspian_USB"}` to the caspian config.
