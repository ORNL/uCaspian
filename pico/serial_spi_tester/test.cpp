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
      printf("Status avail: %d count: %d\n", status[0], status[1]);
      int16_t ch = getchar_timeout_us(1000);
      if (ch != PICO_ERROR_TIMEOUT) {
         buf[0] = (uint8_t)ch;
         write_register(WRITE_BYTES_OP, buf, 1);
      }
      sleep_ms(1000);
   }
}

static int verify_status(std::string msg, uint8_t count, uint8_t avail)
{
   uint8_t status[2];
   read_register(READ_STATUS_OP, status, 2);
   if (status[0] == count && status[1] == avail) {
      printf("      %s Passed.\n", msg.c_str());
      return 0;
   }
   else {
      printf("******%s Failed %d != %d, %d != %d\n", msg, count, status[0], avail, status[1]);
      return 1;
   }
}

static int verify_buf(uint8_t *ebuf, uint8_t *abuf, uint16_t len)
{
   bool passed = 0;

   for (uint8_t i = 0; i < len; i++)
   {
      if (ebuf[i] != abuf[i]) {
         passed = 1;
         printf("******Failed [%d] %d == %d\n", i, ebuf[i], abuf[i]);
      }
      else {
         // printf("      Passed [%d] %d == %d\n", i, ebuf[i], abuf[i]);
      }
      abuf[i] = 0;
   }

   if (passed == 0) {
      printf("      Passed verify buf\n");
   }

   return passed;
}

static void automated_tests()
{
   uint8_t passed = 0;
   uint8_t failed = 0;
   uint8_t rbuf[SPI_DEPTH*2];
   uint8_t wbuf[SPI_DEPTH*2];
   uint8_t status[2];

   for(int i = 0; i < 32; ++i) wbuf[i] = 'a'+i;

   printf("\n\nStarting Automated Tests\n\n");

   // Clear out previous values
   printf("Sending Reset......\n");
   write_register(RESET_OP, wbuf, 0);
   sleep_ms(5000);
   verify_status("Reset", SPI_DEPTH, 0) ? failed++ : passed++;

   printf("1 Value Test.......\n");
   write_register(WRITE_BYTES_OP, wbuf, 1);
   verify_status("Status check", SPI_DEPTH, 1) ? failed++ : passed++;
   read_register(READ_BYTES_OP, rbuf, 1);
   verify_buf(wbuf, rbuf, 1) ? failed++ : passed++;

   printf("%d Value Test.......\n", SPI_DEPTH);
   write_register(WRITE_BYTES_OP, wbuf, SPI_DEPTH);
   verify_status("Status check", SPI_DEPTH, SPI_DEPTH) ? failed++ : passed++;
   read_register(READ_BYTES_OP, rbuf, SPI_DEPTH);
   verify_buf(wbuf, rbuf, SPI_DEPTH) ? failed++ : passed++;

   printf("%d Value Test.......\n", SPI_DEPTH);
   for (uint8_t i = 0; i < SPI_DEPTH; ++i){
      write_register(WRITE_BYTES_OP, &wbuf[i], 1);
   }
   verify_status("Status check", SPI_DEPTH, SPI_DEPTH) ? failed++ : passed++;
   read_register(READ_BYTES_OP, rbuf, SPI_DEPTH);
   verify_buf(wbuf, rbuf, SPI_DEPTH) ? failed++ : passed++;

   printf("%d Value Test.......\n", SPI_DEPTH);
   write_register(WRITE_BYTES_OP, wbuf, SPI_DEPTH);
   verify_status("Status check", SPI_DEPTH, SPI_DEPTH) ? failed++ : passed++;
   for (int i = 0; i < SPI_DEPTH; ++i){
      read_register(READ_BYTES_OP, &rbuf[i], 1);
   }
   verify_buf(wbuf, rbuf, SPI_DEPTH) ? failed++ : passed++;

   printf("%d Value Test.......\n", SPI_DEPTH-1);
   write_register(WRITE_BYTES_OP, wbuf, SPI_DEPTH-1);
   verify_status("Status check", SPI_DEPTH, SPI_DEPTH-1) ? failed++ : passed++;
   read_register(READ_BYTES_OP, rbuf, SPI_DEPTH-1);
   verify_buf(wbuf, rbuf, SPI_DEPTH-1) ? failed++ : passed++;

   printf("%d Value Test.......\n", SPI_DEPTH-1);
   for (int i = 0; i < SPI_DEPTH-1; ++i){
      write_register(WRITE_BYTES_OP, &wbuf[i], 1);
   }
   verify_status("Status check", SPI_DEPTH, SPI_DEPTH-1) ? failed++ : passed++;
   read_register(READ_BYTES_OP, rbuf, SPI_DEPTH-1);
   verify_buf(wbuf, rbuf, SPI_DEPTH-1) ? failed++ : passed++;

   printf("%d Value Test.......\n", SPI_DEPTH-1);
   write_register(WRITE_BYTES_OP, wbuf, SPI_DEPTH-1);
   verify_status("Status check", SPI_DEPTH, SPI_DEPTH-1) ? failed++ : passed++;
   for (int i = 0; i < SPI_DEPTH-1; ++i){
      read_register(READ_BYTES_OP, &rbuf[i], 1);
   }
   verify_buf(wbuf, rbuf, SPI_DEPTH-1) ? failed++ : passed++;

   printf("%d Value Test.......\n", SPI_DEPTH*2);
   write_register(WRITE_BYTES_OP, wbuf, SPI_DEPTH);
   verify_status("Status check", SPI_DEPTH, SPI_DEPTH) ? failed++ : passed++;
   write_register(WRITE_BYTES_OP, wbuf, SPI_DEPTH);
   verify_status("Status check", 0, SPI_DEPTH) ? failed++ : passed++;
   read_register(READ_BYTES_OP, rbuf, SPI_DEPTH);
   verify_buf(wbuf, rbuf, SPI_DEPTH) ? failed++ : passed++;
   read_register(READ_BYTES_OP, rbuf, SPI_DEPTH);
   verify_buf(wbuf, rbuf, SPI_DEPTH) ? failed++ : passed++;

   printf("%d Value Test.......\n", SPI_DEPTH*2);
   write_register(WRITE_BYTES_OP, wbuf, SPI_DEPTH);
   verify_status("Status check", SPI_DEPTH, SPI_DEPTH) ? failed++ : passed++;
   write_read_register(WRITE_READ_BYTES_OP, wbuf, rbuf, SPI_DEPTH);
   verify_buf(wbuf, rbuf, SPI_DEPTH) ? failed++ : passed++;
   verify_status("Status check", SPI_DEPTH, SPI_DEPTH) ? failed++ : passed++;
   write_read_register(WRITE_READ_BYTES_OP, wbuf, rbuf, SPI_DEPTH);
   verify_buf(wbuf, rbuf, SPI_DEPTH) ? failed++ : passed++;
   verify_status("Status check", SPI_DEPTH, SPI_DEPTH) ? failed++ : passed++;
   read_register(READ_BYTES_OP, rbuf, SPI_DEPTH);
   verify_buf(wbuf, rbuf, SPI_DEPTH) ? failed++ : passed++;
   verify_status("Status check", SPI_DEPTH, 0) ? failed++ : passed++;

   printf("Finished Automated Tests Passed: %d, Failed: %d, Total: %d\n", passed, failed, passed+failed);
}

static void speed_test()
{
   uint8_t rbuf[SPI_DEPTH*2];
   uint8_t wbuf[SPI_DEPTH*2];
   uint64_t bytes = 1048576;
   uint8_t status[2];
   read_register(READ_STATUS_OP, status, 2);

   // Reset and pre-add data.
   printf("Sending Reset\n");
   write_register(RESET_OP, wbuf, 0);
   sleep_ms(5000);
   verify_status("Reset", SPI_DEPTH, 0);
   write_register(WRITE_BYTES_OP, wbuf, SPI_DEPTH);
   verify_status("pre-add", SPI_DEPTH, SPI_DEPTH);

   printf("Running Speed Test\n");
   absolute_time_t tick = get_absolute_time();

   // Time transfer of data.
   for(int i = 0; i < bytes/SPI_DEPTH; ++i) {
      do {
         read_register(READ_STATUS_OP, status, 2);
      } while (status[0] != SPI_DEPTH);
      write_read_register(WRITE_READ_BYTES_OP, wbuf, rbuf, SPI_DEPTH);
   }

   verify_status("after-test", SPI_DEPTH, SPI_DEPTH);

   absolute_time_t tock = get_absolute_time();

   int64_t time_delta_us = absolute_time_diff_us(tick, tock);

   printf("Times %lld %lld us\n", tick, tock);

   printf("Time difference %lld us\n", time_delta_us);

   printf("Amount Transferred %lld bytes\n", bytes);

   printf("Transfer Speed %llf MBps = %llf Mbps\n", (double)bytes/time_delta_us, ((double)bytes/time_delta_us)*8);

   // Read out the last transfer
   read_register(READ_BYTES_OP, rbuf, SPI_DEPTH);
}

static void speed_test_noflow()
{
   uint8_t rbuf[SPI_DEPTH*2];
   uint8_t wbuf[SPI_DEPTH*2];
   uint64_t bytes = 1048576;

   // Reset and pre-add data.
   printf("Sending Reset\n");
   write_register(RESET_OP, wbuf, 0);
   sleep_ms(5000);
   verify_status("Reset", SPI_DEPTH, 0);
   write_register(WRITE_BYTES_OP, wbuf, SPI_DEPTH);
   verify_status("pre-add", SPI_DEPTH, SPI_DEPTH);

   printf("Running No Flow Control Speed Test\n");
   absolute_time_t tick = get_absolute_time();

   // Time transfer of data.
   for(int i = 0; i < bytes/SPI_DEPTH; ++i) {

      write_read_register(WRITE_READ_BYTES_OP, wbuf, rbuf, SPI_DEPTH);
   }

   verify_status("after-test", SPI_DEPTH, SPI_DEPTH);

   absolute_time_t tock = get_absolute_time();

   int64_t time_delta_us = absolute_time_diff_us(tick, tock);

   printf("Times %lld %lld us\n", tick, tock);

   printf("Time difference %lld us\n", time_delta_us);

   printf("Amount Transferred %lld bytes\n", bytes);

   printf("Transfer Speed %llf MBps = %llf Mbps\n", (double)bytes/time_delta_us, ((double)bytes/time_delta_us)*8);

   // Read out the last transfer
   read_register(READ_BYTES_OP, rbuf, SPI_DEPTH);
}

static void manual_test()
{
   uint8_t rbuf[SPI_DEPTH*2];
   uint8_t wbuf[SPI_DEPTH*2];
   uint8_t status[2];
   uint8_t rw_len = 1;
   bool pause = true;

   printf("\n\n\nWelcome to SPI test. Press '?' for help.\n\n");

   while (1) {

      // Get uCaspian status
      if (!pause) {
         read_register(READ_STATUS_OP, status, 2);
         printf("Status avail: %d count: %d\n", status[0], status[1]);
      }

      // Get command char
      int16_t ch = getchar_timeout_us(1000000);
      if (ch != PICO_ERROR_TIMEOUT) {
         switch ((char)ch)
         {
         case '1':
         case '2':
         case '3':
         case '4':
         case '5':
         case '6':
         case '7':
         case '8':
            rw_len = ch - '0';
            printf("Write Length = %d\n", rw_len);
            break;
         case '9':
            rw_len = SPI_DEPTH-1;
            printf("Write Length = %d\n", rw_len);
            break;
         case '0':
            rw_len = SPI_DEPTH;
            printf("Write Length = %d\n", rw_len);
            break;
         case 'q':
            read_register(READ_STATUS_OP, status, 2);
            printf("Status avail: %d count: %d\n", status[0], status[1]);
            break;
         case 'r':
            read_register(READ_BYTES_OP, rbuf, rw_len);
            printf("READ: ");
            for (int i = 0; i < rw_len; ++i) {
               printf("%c", rbuf[i]);
            }
            printf("\n");
            break;
         case 'R':
            printf("Sending Reset\n");
            write_register(RESET_OP, wbuf, 0);
            break;
         case 'e':
            for (int i = 0; i < rw_len; ++i) {
               wbuf[i] = 'e'+i;
            }
            write_read_register(WRITE_READ_BYTES_OP, wbuf, rbuf, rw_len);
            printf("Sending: ");
            for (int i = 0; i < rw_len; ++i) {
               printf("%c", wbuf[i]);
            }
            printf("\n");
            printf("READ: ");
            for (int i = 0; i < rw_len; ++i) {
               printf("%c", rbuf[i]);
            }
            printf("\n");
            break;
         case 't':
            automated_tests();
            break;
         case 'w':
            speed_test();
            break;
         case 'W':
            speed_test_noflow();
            break;
         case '?':
            printf("\nCommands:\n");
            printf("  1-8   - Set rw_len to value.\n");
            printf("  9     - Set rw_len to SPI_DEPTH-1.\n");
            printf("  0     - Set rw_len to SPI_DEPTH.\n");
            printf("  p     - Resume/Pause automatic status query.\n");
            printf("  q     - Query status.\n");
            printf("  r     - Read rw_len values.\n");
            printf("  e     - Read and write rw_len values.\n");
            printf("  t     - Run automated tests.\n");
            printf("  w     - Run speed test.\n");
            printf("  W     - Rune speed test (No flow control).\n");
            printf("  R     - Send reset to FPGA over SPI.\n");
            printf("  ?     - Show help.\n");
            printf("  other - Write rw_len of 'other'\n");
            printf("\n");
            break;
         case 'p':
            pause = !pause;
            break;
         default:
            printf("Sending: ");
            for (int i = 0; i < rw_len; ++i) {
               wbuf[i] = ch+i;
               printf("%c", wbuf[i]);
            }
            printf("\n");
            write_register(WRITE_BYTES_OP, wbuf, rw_len);
            break;
         }
      }
   }
}

static void host_to_fpga() {
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

static void fpga_to_host() {
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

static void loopback() {
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

   // Force loopback for testing (I don't have an SPI device handy)
   // hw_set_bits(&spi_get_hw(spi_default)->cr1, SPI_SSPCR1_LBM_BITS);

   // Always select chip.
   // cs_select();

   // Turn off LED
   gpio_put(LED_PIN, 0);

   printf("Starting Job\n");
   sleep_ms(2000);

   // Launch second core for writing
   // multicore_launch_core1(host_to_fpga);

   // bi_directional();

   manual_test();

   // host_to_fpga();
   // fpga_to_host();

   // loopback();
}
