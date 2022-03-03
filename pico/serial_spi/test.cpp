#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware/gpio.h"
#include "hardware/spi.h"
#include "pico/binary_info.h"
#include "pico/multicore.h"

// SPI Defines
// We are going to use SPI 0, and allocate it to the following GPIO pins
// Pins can be changed, see the GPIO function select table in the datasheet for information on GPIO assignments
#define SPI_PORT spi0
#define PIN_MISO 16
#define PIN_CS   17
#define PIN_SCK  18
#define PIN_MOSI 19

const uint LED_PIN = 25;

static inline void cs_select()
{
   gpio_put(PIN_CS, 0);
}

static inline void cs_deselect()
{
   gpio_put(PIN_CS, 1);
}

void host_to_fpga() {
   uint8_t buf[1];
   uint8_t len;

   // while (true)
   // {
   //    printf("Hello, world from 1!\n");
   //    sleep_ms(1000);
   // }

   while (1) {
      int16_t ch = getchar_timeout_us(100);
      if (ch != PICO_ERROR_TIMEOUT) {
         buf[0] = (uint8_t)ch;
         gpio_put(LED_PIN, buf[0]&1);
         spi_write_blocking(SPI_PORT, buf, 1);
      }
   }
}

void fpga_to_host() {
   uint8_t buf[1024];
   uint8_t len;

   // while (true)
   // {
   //    printf("Hello, world from 2!\n");
   //    sleep_ms(2000);
   // }

   while (1) {
      len = spi_read_blocking(SPI_PORT, 0, buf, 1024);
      for (int i = 0; i < len; ++i) {
         printf("%c", buf[i]);
      }
   }
}

void loopback() {
   uint8_t buf[1024];
   uint8_t len;

   // while (true)
   // {
   //    printf("Hello, world from 2!\n");
   //    sleep_ms(2000);
   // }

   while (1) {
      int16_t ch = getchar_timeout_us(100);
      if (ch != PICO_ERROR_TIMEOUT) {
         buf[0] = (uint8_t)ch;
         printf("%c", buf[0]);
      }
   }
}

int main()
{
   bi_decl(bi_program_description("This is a test binary."));

   stdio_init_all();

   // Setup LED
   gpio_init(LED_PIN);
   gpio_set_dir(LED_PIN, GPIO_OUT);
   bi_decl(bi_1pin_with_name(LED_PIN, "On-board LED"));

   // SPI initialisation. This example will use SPI at 1MHz.
   spi_init(SPI_PORT, 1000*1000);
   gpio_set_function(PIN_MISO, GPIO_FUNC_SPI);
   gpio_set_function(PIN_SCK,  GPIO_FUNC_SPI);
   gpio_set_function(PIN_MOSI, GPIO_FUNC_SPI);
   bi_decl(bi_3pins_with_func(PIN_MISO, PIN_MOSI, PIN_SCK, GPIO_FUNC_SPI));

   // Chip select is active-low, so we'll initialise it to a driven-high state
   gpio_init(PIN_CS);
   gpio_set_dir(PIN_CS, GPIO_OUT);
   bi_decl(bi_1pin_with_name(PIN_CS, "SPI CS"));
   cs_deselect();

   // Force loopback for testing (I don't have an SPI device handy)
   // hw_set_bits(&spi_get_hw(spi_default)->cr1, SPI_SSPCR1_LBM_BITS);

   // Always select chip.
   cs_select();

   // Turn on LED
   gpio_put(LED_PIN, 1);

   printf("Starting Job\n");
   sleep_ms(2000);

   // Launch second core for writing
   // multicore_launch_core1(host_to_fpga);

   host_to_fpga();
   // fpga_to_host();

   // loopback();
}
