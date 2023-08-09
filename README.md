# µCaspian

**µCaspian code is confidential to ORNL. Do not share.**

"micro-caspian" can be thought of as a neuromorphic equivalent of a microcontroller. This is a small design with a minimal feature set and limited performance designed for low cost, low power embedded applications. The target FPGA is the Lattice ice40UP5k.

A few details:

- 256 neurons, 4096 synapses
- 8 bit unsigned neuron thresholds
- exponential charge leak (not yet implemented)
- 8 bit signed synaptic weights
- no connectivity restrictions
- variable length packets
- activity dependent evaluation

## Installing Open-Source Toolchain

You can either install the [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build) or use the experimental [Conda EDA](https://github.com/hdl/conda-eda) environment.

### Install OSS CAD Suite (Required)

  1. Navigate to project repository. <https://github.com/YosysHQ/oss-cad-suite-build>

  2. Download release and extract to home directory.
  3. Add or source toolchain. See [installation](https://github.com/YosysHQ/oss-cad-suite-build#installation).

      ```bash
      export PATH="<extracted_location>/oss-cad-suite/bin:$PATH"

      or

      source <extracted_location>/oss-cad-suite/environment
      ```

### Anaconda environment (Experimental)

As an alternative to the OSS CAD suite you can use the Conda EDA environment which includes Verible and many of the other open-source EDA tools used in the [ORNL NeuroHW](https://code.ornl.gov/neurohw) ecosystem.

```bash
conda env create -f environment.yml
conda activate ucaspian
```

### Install Verible (Optional)

If you did not use the experimental Anaconda environment you may also want to install [Verible](https://github.com/chipsalliance/verible). Verible has useful SystemVerilog linting and formatting tools.

  1. Navigate to project repository. <https://github.com/chipsalliance/verible>

  2. Download release and extract to home directory. The release has bin and share which are both extracted to `~/bin` and `~/share` respectively.

### Install libftdi

On Ubuntu:
```bash
sudo apt install libftdi-dev libftdi1-dev
```

### Setup upduino dev file and group permissions

Add [sw/upduinov3.rules](sw/upduinov3.rules) to /etc/udev/rules.d on Ubuntu to allow using the upduino without root.

You also need to be added to the `dialout` group.

## Building and running on UPduino

1. Clone the neuromorphic framework.

    ```bash
    git clone git@code.ornl.gov:neuromorphic-computing/framework.git
    cd framework
    ```
    or
    ```bash
    git clone git@bitbucket.org:neuromorphic-utk/framework.git
    cd framework
    ```

2. Clone Caspian to processors/caspian.

    ```bash
    git clone git@code.ornl.gov:neuromorphic-computing/caspian.git ./processors/caspian
    ```

3. Clone µCaspian to processors/caspian/ucaspian.

    ```bash
    git clone git@code.ornl.gov:neurohw/ucaspian.git ./processors/caspian/ucaspian
    ```

4. Build the framework environment.

    ```bash
    USB=true bash scripts/create_env.sh
    ```

5. Source the framework environment

    ```bash
    source pyframework/bin/activate
    ```

6. Plug in the UPduino and use dmesg to find the ftdi_sio device id

    ```bash
    $ dmesg
    ...
    [190067.797102] ftdi_sio 1-1.4:1.0: FTDI USB Serial Device converter detected
    ...

    ```
    Update the `USB_DEV` variable in the makefile with the device ID for your board. This allows the script to automatically bind the USB device driver to the FPGA device without requiring the device cable to be disconnected and reconnected.

7. Build and load ucaspian FPGA image on the [UPduino](https://tinyvision.ai/products/upduino-v3-1) board.

    ```bash
    # In framework/processors/caspian/ucaspian
    make upduino_uart_top.flash
    ```

    For additional designs see `make help`. Not all designs currently meet timing and will fail during place and route. These designs should not be used.

8. Run test python script to test connection to FPGA. You should see output data and see the LED on the FPGA blink.

    ```bash
    # In framework/processors/caspian/ucaspian

    pip install pyserial

    python scripts/basic_test.py
    ```

9. Run caspian passthrough test. You should see output which matches `./bin/pass_bench sim 5 5 10`.

    ```bash
    cd ..
    # In framework/processors/caspian
    make clean
    make utils
    ./bin/pass_bench ucaspian 5 5 10

    ```

11. To configure the caspian processor to run using hardware, add `{"Backend": "uCaspian_USB"}` to the caspian config.

## Notes on SPI Versions

spi.sv or spi_v4.sv should be used.

- spi.sv    - Working 3-bit sync, SPI implementation.
- spi_v2.sv - Non-working, SPI clock synchronous implementation.
- spi_v3.sv - Working 3-bit sync, with separate SPI communication and logic clocks.
- spi_v4.sv - Working async FIFO for clock sync.
