#include <stdio.h>
#include <string>
#include "pico/stdlib.h"
#include "pico/time.h"
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

#define READ_STATUS_OP      1
#define READ_BYTES_OP       2
#define WRITE_BYTES_OP      4
#define WRITE_READ_BYTES_OP 6
#define RESET_OP            8

#define SPI_WIDTH 8
#define SPI_DEPTH 16
#define HOST_DEPTH 512

const uint LED_PIN = 25;

static inline void cs_select()
{
   gpio_put(PIN_CS, 0);
}

static inline void cs_deselect()
{
   gpio_put(PIN_CS, 1);
}

static void write_register(uint8_t reg, uint8_t *buf, uint16_t len)
{
   reg &= 0x7f;
   cs_select();
   spi_write_blocking(SPI_PORT, &reg, 1);
   spi_write_blocking(SPI_PORT, buf, len);
   cs_deselect();
}

static void read_register(uint8_t reg, uint8_t *buf, uint16_t len)
{
   reg |= 0x80;
   cs_select();
   spi_write_blocking(SPI_PORT, &reg, 1);
   spi_read_blocking(SPI_PORT, 0, buf, len);
   cs_deselect();
}

static void write_read_register(uint8_t reg, uint8_t *wbuf, uint8_t *rbuf, uint16_t len)
{
   reg |= 0x80;
   cs_select();
   spi_write_blocking(SPI_PORT, &reg, 1);
   spi_write_read_blocking(SPI_PORT, wbuf, rbuf, len);
   cs_deselect();
}

static void bi_directional()
{
   uint8_t buf[1];
   while (1) {
      uint8_t status[2];
      read_register(READ_STATUS_OP, status, 2);
      int16_t ch = getchar_timeout_us(1000);
      if (ch != PICO_ERROR_TIMEOUT) {
         buf[0] = (uint8_t)ch;
         write_register(WRITE_BYTES_OP, buf, 1);
      }
      sleep_ms(1000);
   }
}

static void passthrough()
{

   uint8_t from_fpga[SPI_DEPTH*2];
   uint8_t from_fpga_buf_len = 0;
   uint8_t from_fpga_transfer = 0;

   uint8_t to_fpga[SPI_DEPTH*2];
   uint8_t to_fpga_buf_len = 0;
   uint8_t to_fpga_transfer = 0;

   uint8_t status[2];
   uint8_t rw_len = 1;

   while (1) {
      // FPGA to HOST
      read_register(READ_STATUS_OP, status, 2);
      if (uart_is_writable(uart_default))
      {
         from_fpga_transfer = status[1];
         if (from_fpga_transfer > 0) {
            gpio_put(LED_PIN, 0);
            read_register(READ_BYTES_OP, from_fpga, from_fpga_transfer);
            uart_write_blocking(uart_default, from_fpga, from_fpga_transfer);
         }
      }

      // HOST to FPGA
      read_register(READ_STATUS_OP, status, 2);
      to_fpga_buf_len = uart_is_readable(uart_default);
      to_fpga_transfer = std::min(to_fpga_buf_len, status[0]);
      if (to_fpga_transfer > 0) {
         gpio_put(LED_PIN, 1);
         uart_read_blocking(uart_default, to_fpga, to_fpga_transfer);
         write_register(WRITE_BYTES_OP, to_fpga, to_fpga_transfer);
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

   // SPI initialisation. This example will use SPI at 3MHz.
   spi_init(SPI_PORT, 1000*1000*30);
   gpio_set_function(PIN_MISO, GPIO_FUNC_SPI);
   gpio_set_function(PIN_SCK,  GPIO_FUNC_SPI);
   gpio_set_function(PIN_MOSI, GPIO_FUNC_SPI);
   bi_decl(bi_3pins_with_func(PIN_MISO, PIN_MOSI, PIN_SCK, GPIO_FUNC_SPI));

   // Chip select is active-low, so we'll initialise it to a driven-high state
   gpio_init(PIN_CS);
   gpio_set_dir(PIN_CS, GPIO_OUT);
   bi_decl(bi_1pin_with_name(PIN_CS, "SPI CS"));
   cs_deselect();

   // Turn off LED
   gpio_put(LED_PIN, 0);

   sleep_ms(2000);

   passthrough();

}
