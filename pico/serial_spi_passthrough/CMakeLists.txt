cmake_minimum_required(VERSION 3.13)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# Pull in Raspberry Pi Pico SDK (must be before project)
include(pico_sdk_import.cmake)

project(serial_spi C CXX ASM)

# Initialise the Raspberry Pi Pico SDK
pico_sdk_init()

add_executable(test
  test.cpp
)

pico_set_program_name(test "test_gen")
pico_set_program_version(test "0.1")

pico_enable_stdio_usb(test 0)
pico_enable_stdio_uart(test 1)

pico_add_extra_outputs(test)

# Add the standard library to the build
target_link_libraries(test
   pico_stdlib
   pico_multicore
   hardware_spi
)
