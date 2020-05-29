# Numato Mimas A7 revision 2
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

####################################################################################################################
#                                               CLOCK 100MHz                                                       #
####################################################################################################################
set_property -dict { PACKAGE_PIN "H4"    IOSTANDARD LVCMOS33       SLEW FAST} [get_ports { clk1 }]     ;                # IO_L12P_T1_MRCC_35            Sch = CLK1
create_clock -period 10.000 -name clk1 -waveform {0.000 5.000} [get_ports -filter { NAME =~  "*clk*" && DIRECTION == "IN" }]

####################################################################################################################
#                                                   RESET - S3                                                     #
####################################################################################################################
#set_property -dict { PACKAGE_PIN "M2"    IOSTANDARD LVCMOS33   SLEW FAST   } [get_ports { RESET }]    ;                 # IO_L16N_T2_35                 Sch = RESET

####################################################################################################################
#                                               FT2232H Signals                                                    #
####################################################################################################################
set_property -dict { PACKAGE_PIN "Y22"    IOSTANDARD LVCMOS33       SLEW FAST} [get_ports { data[0] }]  ;               # IO_L9N_T1_DQS_D13_14          Sch = FTDI-D0
set_property -dict { PACKAGE_PIN "Y21"    IOSTANDARD LVCMOS33       SLEW FAST} [get_ports { data[1] }]  ;               # IO_L9P_T1_DQS_14              Sch = FTDI-D1
set_property -dict { PACKAGE_PIN "AB22"   IOSTANDARD LVCMOS33       SLEW FAST} [get_ports { data[2] }]  ;               # IO_L10N_T1_D15_14             Sch = FTDI-D2
set_property -dict { PACKAGE_PIN "AA21"   IOSTANDARD LVCMOS33       SLEW FAST} [get_ports { data[3] }]  ;               # IO_L8N_T1_D12_14              Sch = FTDI-D3
set_property -dict { PACKAGE_PIN "AB21"   IOSTANDARD LVCMOS33       SLEW FAST} [get_ports { data[4] }]  ;               # IO_L10P_T1_D14_14             Sch = FTDI-D4
set_property -dict { PACKAGE_PIN "AA20"   IOSTANDARD LVCMOS33       SLEW FAST} [get_ports { data[5] }]  ;               # IO_L8P_T1_D11_14              Sch = FTDI-D5
set_property -dict { PACKAGE_PIN "AB20"   IOSTANDARD LVCMOS33       SLEW FAST} [get_ports { data[6] }]  ;               # IO_L15N_T2_DQS_DOUT_CSO_B_14  Sch = FTDI-D6
set_property -dict { PACKAGE_PIN "AA18"   IOSTANDARD LVCMOS33       SLEW FAST} [get_ports { data[7] }]  ;               # IO_L17P_T2_A14_D30_14         Sch = FTDI-D7

set_property -dict { PACKAGE_PIN "V22"    IOSTANDARD LVCMOS33       SLEW FAST} [get_ports { txe_n }]    ;               # IO_L3N_T0_DQS_EMCCLK_14       Sch = FTDI-TXE#
set_property -dict { PACKAGE_PIN "W21"    IOSTANDARD LVCMOS33       SLEW FAST} [get_ports { rxf_n }]    ;               # IO_L7P_T1_D09_14              Sch = FTDI-RXF#
set_property -dict { PACKAGE_PIN "W22"    IOSTANDARD LVCMOS33       SLEW FAST} [get_ports { wr_n  }]    ;               # IO_L7N_T1_D10_14              Sch = FTDI-WR#
set_property -dict { PACKAGE_PIN "AA19"   IOSTANDARD LVCMOS33       SLEW FAST} [get_ports { rd_n  }]    ;               # IO_L15P_T2_DQS_RDWR_B_14      Sch = FTDI-RD#
#set_property -dict { PACKAGE_PIN "Y18"    IOSTANDARD LVCMOS33       SLEW FAST} [get_ports { CLKOUT}]    ;               # IO_L13P_T2_MRCC_14            Sch = FTDI-CLKOUT
set_property -dict { PACKAGE_PIN "T21"    IOSTANDARD LVCMOS33       SLEW FAST} [get_ports { oe_n  }]    ;               # IO_L4P_T0_D04_14              Sch = FTDI-OE#
set_property -dict { PACKAGE_PIN "U21"    IOSTANDARD LVCMOS33       SLEW FAST} [get_ports { siwua }]    ;               # IO_L4N_T0_D05_14              Sch = FTDI-SIWUA

####################################################################################################################
#                                        DDR3       : MT41J128M16XX-125                                            #
#                                        Frequency  : 400 MHz                                                      #
#                                        Data Width : 16                                                           #
####################################################################################################################
#set_property -dict { PACKAGE_PIN "Y8"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_dq[0]}]     ;               # IO_L23P_T3_34                 Sch = DDR3-DQ0
#set_property -dict { PACKAGE_PIN "AB6"    IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_dq[1]}]     ;               # IO_L20N_T3_34                 Sch = DDR3-DQ1
#set_property -dict { PACKAGE_PIN "W9"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_dq[2]}]     ;               # IO_L24P_T3_34                 Sch = DDR3-DQ2
#set_property -dict { PACKAGE_PIN "AA8"    IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_dq[3]}]     ;               # IO_L22P_T3_34                 Sch = DDR3-DQ3
#set_property -dict { PACKAGE_PIN "AB7"    IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_dq[4]}]     ;               # IO_L20P_T3_34                 Sch = DDR3-DQ4
#set_property -dict { PACKAGE_PIN "V7"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_dq[5]}]     ;               # IO_L19P_T3_34                 Sch = DDR3-DQ5
#set_property -dict { PACKAGE_PIN "AB8"    IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_dq[6]}]     ;               # IO_L22N_T3_34                 Sch = DDR3-DQ6
#set_property -dict { PACKAGE_PIN "W7"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_dq[7]}]     ;               # IO_L19N_T3_VREF_34            Sch = DDR3-DQ7
#set_property -dict { PACKAGE_PIN "V4"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_dq[8]}]     ;               # IO_L12P_T1_MRCC_34            Sch = DDR3-DQ8
#set_property -dict { PACKAGE_PIN "AB2"    IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_dq[9]}]     ;               # IO_L8N_T1_34                  Sch = DDR3-DQ9
#set_property -dict { PACKAGE_PIN "AA5"    IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_dq[10]}]    ;               # IO_L10P_T1_34                 Sch = DDR3-DQ10
#set_property -dict { PACKAGE_PIN "AB3"    IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_dq[11]}]    ;               # IO_L8P_T1_34                  Sch = DDR3-DQ11
#set_property -dict { PACKAGE_PIN "AB5"    IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_dq[12]}]    ;               # IO_L10N_T1_34                 Sch = DDR3-DQ12
#set_property -dict { PACKAGE_PIN "W4"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_dq[13]}]    ;               # IO_L12N_T1_MRCC_34            Sch = DDR3-DQ13
#set_property -dict { PACKAGE_PIN "AB1"    IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_dq[14]}]    ;               # IO_L7N_T1_34                  Sch = DDR3-DQ14
#set_property -dict { PACKAGE_PIN "AA4"    IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_dq[15]}]    ;               # IO_L11N_T1_SRCC_34            Sch = DDR3-DQ15
#set_property -dict { PACKAGE_PIN "U6"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_addr[0]}]   ;               # IO_L16P_T2_34                 Sch = DDR3-A0
#set_property -dict { PACKAGE_PIN "T5"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_addr[1]}]   ;               # IO_L14P_T2_SRCC_34            Sch = DDR3-A1
#set_property -dict { PACKAGE_PIN "Y6"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_addr[2]}]   ;               # IO_L18P_T2_34                 Sch = DDR3-A2
#set_property -dict { PACKAGE_PIN "T6"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_addr[3]}]   ;               # IO_L17N_T2_34                 Sch = DDR3-A3
#set_property -dict { PACKAGE_PIN "V2"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_addr[4]}]   ;               # IO_L2N_T0_34                  Sch = DDR3-A4
#set_property -dict { PACKAGE_PIN "T4"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_addr[5]}]   ;               # IO_L13N_T2_MRCC_34            Sch = DDR3-A5
#set_property -dict { PACKAGE_PIN "Y2"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_addr[6]}]   ;               # IO_L4N_T0_34                  Sch = DDR3-A6
#set_property -dict { PACKAGE_PIN "R2"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_addr[7]}]   ;               # IO_L3N_T0_DQS_34              Sch = DDR3-A7
#set_property -dict { PACKAGE_PIN "Y1"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_addr[8]}]   ;               # IO_L5N_T0_34                  Sch = DDR3-A8
#set_property -dict { PACKAGE_PIN "R4"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_addr[9]}]   ;               # IO_L13P_T2_MRCC_34            Sch = DDR3-A9
#set_property -dict { PACKAGE_PIN "W5"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_addr[10]}]  ;               # IO_L15N_T2_DQS_34             Sch = DDR3-A10
#set_property -dict { PACKAGE_PIN "W1"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_addr[11]}]  ;               # IO_L5P_T0_34                  Sch = DDR3-A11
#set_property -dict { PACKAGE_PIN "AA6"    IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_addr[12]}]  ;               # IO_L18N_T2_34                 Sch = DDR3-A12
#set_property -dict { PACKAGE_PIN "U2"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_addr[13]}]  ;               # IO_L2P_T0_34                  Sch = DDR3-A13
#set_property -dict { PACKAGE_PIN "W6"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_ba[0]}]     ;               # IO_L15P_T2_DQS_34             Sch = DDR3-BA0
#set_property -dict { PACKAGE_PIN "U5"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_ba[1]}]     ;               # IO_L14N_T2_SRCC_34            Sch = DDR3-BA1
#set_property -dict { PACKAGE_PIN "R6"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_ba[2]}]     ;               # IO_L17P_T2_34                 Sch = DDR3-BA2
#set_property -dict { PACKAGE_PIN "V5"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_ras_n}]     ;               # IO_L16N_T2_34                 Sch = DDR3-RAS
#set_property -dict { PACKAGE_PIN "T1"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_cas_n}]     ;               # IO_L1P_T0_34                  Sch = DDR3-CAS
#set_property -dict { PACKAGE_PIN "R3"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_we_n}]      ;               # IO_L3P_T0_DQS_34              Sch = DDR3-WE
#set_property -dict { PACKAGE_PIN "U7"     IOSTANDARD LVCMOS15   SLEW FAST} [get_ports {ddr3_reset_n}]   ;               # IO_25_34                      Sch = DDR3-RESET
#set_property -dict { PACKAGE_PIN "U1"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_cke}]       ;               # IO_L1N_T0_34                  Sch = DDR3-CKE
#set_property -dict { PACKAGE_PIN "W2"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_odt}]       ;               # IO_L4P_T0_34                  Sch = DDR3-ODT
#set_property -dict { PACKAGE_PIN "T3"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_cs_n}]      ;               # IO_0_34                       Sch = DDR3-CS#
#set_property -dict { PACKAGE_PIN "Y7"     IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_dm[0]}]     ;               # IO_L23N_T3_34                 Sch = DDR3-LDM
#set_property -dict { PACKAGE_PIN "AA1"    IOSTANDARD SSTL15     SLEW FAST} [get_ports {ddr3_dm[1]}]     ;               # IO_L7P_T1_34                  Sch = DDR3-UDM
#set_property -dict { PACKAGE_PIN "V9"     IOSTANDARD DIFF_SSTL15 SLEW FAST} [get_ports {ddr3_dqs_p[0]}] ;               # IO_L21P_T3_DQS_34             Sch = DDR3-LDQS_P
#set_property -dict { PACKAGE_PIN "V8"     IOSTANDARD DIFF_SSTL15 SLEW FAST} [get_ports {ddr3_dqs_n[0]}] ;               # IO_L21N_T3_DQS_34             Sch = DDR3-LDQS_N
#set_property -dict { PACKAGE_PIN "Y3"     IOSTANDARD DIFF_SSTL15 SLEW FAST} [get_ports {ddr3_dqs_p[1]}] ;               # IO_L9P_T1_DQS_34              Sch = DDR3-UDQS_P
#set_property -dict { PACKAGE_PIN "AA3"    IOSTANDARD DIFF_SSTL15 SLEW FAST} [get_ports {ddr3_dqs_n[1]}] ;               # IO_L9N_T1_DQS_34              Sch = DDR3-UDQS_N
#set_property -dict { PACKAGE_PIN "U3"     IOSTANDARD DIFF_SSTL15 SLEW FAST} [get_ports {ddr3_ck_p[0]}]  ;               # IO_L6P_T0_34                  Sch = DDR3-CK_P
#set_property -dict { PACKAGE_PIN "V3"     IOSTANDARD DIFF_SSTL15 SLEW FAST} [get_ports {ddr3_ck_n[0]}]  ;               # IO_L6N_T0_VREF_34             Sch = DDR3-CK_N

####################################################################################################################
#                                              QSPI - FLASH                                                        #
####################################################################################################################
#set_property -dict { PACKAGE_PIN "T19"    IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { SPI_CS_N }]     ;              # IO_L6P_T0_FCS_B_14            Sch = SPI_CS_N
#set_property -dict { PACKAGE_PIN "P22"    IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { SPI_DQ[0] }]    ;              # IO_L1P_T0_D00_MOSI_14         Sch = SPI_DQ0
#set_property -dict { PACKAGE_PIN "R22"    IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { SPI_DQ[1] }]    ;              # IO_L1N_T0_D01_DIN_14          Sch = SPI_DQ1
#set_property -dict { PACKAGE_PIN "P21"    IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { SPI_DQ[2] }]    ;              # IO_L2P_T0_D02_14              Sch = SPI_DQ2
#set_property -dict { PACKAGE_PIN "R21"    IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { SPI_DQ[3] }]    ;              # IO_L2N_T0_D03_14              Sch = SPI_DQ3
#set_property -dict { PACKAGE_PIN "L12"    IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { SPI_SCK }]      ;              # CCLK_0                        Sch = SPI_SCK

####################################################################################################################
#                                               Micro SD                                                           #
####################################################################################################################
#set_property -dict { PACKAGE_PIN "R16"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { sd_clk }];                      # IO_L22N_T3_A04_D20_14         Sch = SD_SCK
#set_property -dict { PACKAGE_PIN "R18"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { sd_cs  }];                      # IO_L20P_T3_A08_D24_14         Sch = SD_CS
#set_property -dict { PACKAGE_PIN "P15"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { sd_miso}];                      # IO_L22P_T3_A05_D21_14         Sch = SD_SDO
#set_property -dict { PACKAGE_PIN "T18"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { sd_mosi}];                      # IO_L20N_T3_A07_D23_14         Sch = SD_SDI
#set_property -dict { PACKAGE_PIN "P14"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { sd_rsv}];                       # IO_L19P_T3_A10_D26_14         Sch = SD_RSV

####################################################################################################################
#                                               Push Buttons                                                       #
####################################################################################################################
#set_property -dict { PACKAGE_PIN "P20"  IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { sw_in[0] }];                     # IO_0_14                       Sch = SW0
#set_property -dict { PACKAGE_PIN "P19"  IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { sw_in[1] }];                     # IO_L5P_T0_D06_14              Sch = SW1
#set_property -dict { PACKAGE_PIN "P17"  IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { sw_in[2] }];                     # IO_L21N_T3_DQS_A06_D22_14     Sch = SW2
#set_property -dict { PACKAGE_PIN "N17"  IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { sw_in[3] }];                     # IO_L21P_T3_DQS_14             Sch = SW3

####################################################################################################################
#                                               LEDs                                                               #
####################################################################################################################
set_property -dict { PACKAGE_PIN "K17"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { led[0] }];                      # IO_L21P_T3_DQS_15             Sch = LED0
set_property -dict { PACKAGE_PIN "J17"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { led[1] }];                      # IO_L21N_T3_DQS_A18_15         Sch = LED1
set_property -dict { PACKAGE_PIN "L14"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { led[2] }];                      # IO_L22P_T3_A17_15             Sch = LED2
set_property -dict { PACKAGE_PIN "L15"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { led[3] }];                      # IO_L22N_T3_A16_15             Sch = LED3
set_property -dict { PACKAGE_PIN "L16"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { led[4] }];                      # IO_L23P_T3_FOE_B_15           Sch = LED4
set_property -dict { PACKAGE_PIN "K16"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { led[5] }];                      # IO_L23N_T3_FWE_B_15           Sch = LED5
set_property -dict { PACKAGE_PIN "M15"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { led[6] }];                      # IO_L24P_T3_RS1_15             Sch = LED6
set_property -dict { PACKAGE_PIN "M16"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { led[7] }];                      # IO_L24N_T3_RS0_15             Sch = LED7

####################################################################################################################
#                                               DIP Switches                                                       #
####################################################################################################################
#set_property -dict { PACKAGE_PIN "B21"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { dip_sw[0] }];                   # IO_L21P_T3_DQS_16             Sch = DP0
#set_property -dict { PACKAGE_PIN "A21"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { dip_sw[1] }];                   # IO_L21N_T3_DQS_16             Sch = DP1
#set_property -dict { PACKAGE_PIN "E22"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { dip_sw[2] }];                   # IO_L22P_T3_16                 Sch = DP2
#set_property -dict { PACKAGE_PIN "D22"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { dip_sw[3] }];                   # IO_L22N_T3_16                 Sch = DP3
#set_property -dict { PACKAGE_PIN "E21"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { dip_sw[4] }];                   # IO_L23P_T3_16                 Sch = DP4
#set_property -dict { PACKAGE_PIN "D21"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { dip_sw[5] }];                   # IO_L23N_T3_16                 Sch = DP5
#set_property -dict { PACKAGE_PIN "G21"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { dip_sw[6] }];                   # IO_L24P_T3_16                 Sch = DP6
#set_property -dict { PACKAGE_PIN "G22"   IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { dip_sw[7] }];                   # IO_L24N_T3_16                 Sch = DP7

####################################################################################################################
#                                               Seven Segment                                                      #
####################################################################################################################
#set_property -dict { PACKAGE_PIN "N3"    IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { enable[0] }];                   # IO_L19N_T3_VREF_35            Sch = 7_SEG1_EN
#set_property -dict { PACKAGE_PIN "R1"    IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { enable[1] }];                   # IO_L20P_T3_35                 Sch = 7_SEG2_EN
#set_property -dict { PACKAGE_PIN "P1"    IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { enable[2] }];                   # IO_L20N_T3_35                 Sch = 7_SEG3_EN
#set_property -dict { PACKAGE_PIN "P4"    IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { seven_segment[0] }];            # IO_L21N_T3_DQS_35             Sch = 7SEG_0
#set_property -dict { PACKAGE_PIN "N4"    IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { seven_segment[1] }];            # IO_L19P_T3_35                 Sch = 7SEG_1
#set_property -dict { PACKAGE_PIN "M3"    IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { seven_segment[2] }];            # IO_L16P_T2_35                 Sch = 7SEG_2
#set_property -dict { PACKAGE_PIN "M5"    IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { seven_segment[3] }];            # IO_L23N_T3_35                 Sch = 7SEG_3
#set_property -dict { PACKAGE_PIN "L5"    IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { seven_segment[4] }];            # IO_L18P_T2_35                 Sch = 7SEG_4
#set_property -dict { PACKAGE_PIN "L6"    IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { seven_segment[5] }];            # IO_25_35                      Sch = 7SEG_5
#set_property -dict { PACKAGE_PIN "M6"    IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { seven_segment[6] }];            # IO_L23P_T3_35                 Sch = 7SEG_6
#set_property -dict { PACKAGE_PIN "P5"    IOSTANDARD LVCMOS33    SLEW FAST} [get_ports { seven_segment[7] }];            # IO_L21P_T3_DQS_35             Sch = 7SEG_7

####################################################################################################################
#                                               24AA02E48T EEPROM                                                  #
####################################################################################################################
#set_property -dict { PACKAGE_PIN "N5"   IOSTANDARD LVCMOS33 } [get_ports { iic_rtl_scl_io }];                           # IO_L24N_T3_35                 Sch = EEPROM_SCL
#set_property -dict { PACKAGE_PIN "P6"   IOSTANDARD LVCMOS33 } [get_ports { iic_rtl_sda_io }];                           # IO_L24P_T3_35                 Sch = EEPROM_SDA

####################################################################################################################
#                                               HDMI Signals                                                       #
####################################################################################################################
##HDMI in
#set_property -dict { PACKAGE_PIN "K2"    IOSTANDARD LVCMOS33 }  [get_ports { hdmi_rx_cec  }];                           # IO_L9P_T1_DQS_AD7P_35         Sch = HDMI_RX_CEC
#set_property -dict { PACKAGE_PIN "J4"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_rx_clk_n}];                           # IO_L13N_T2_MRCC_35            Sch = HDMI_RX_CLK_N
#set_property -dict { PACKAGE_PIN "K4"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_rx_clk_p}];                           # IO_L13P_T2_MRCC_35            Sch = HDMI_RX_CLK_P
#set_property -dict { PACKAGE_PIN "G2"    IOSTANDARD LVCMOS33 }  [get_ports { hdmi_rx_hpa  }];                           # IO_L8N_T1_AD14N_35            Sch = HDMI_RX_HOT
#set_property -dict { PACKAGE_PIN "J2"    IOSTANDARD LVCMOS33 }  [get_ports { hdmi_rx_scl  }];                           # IO_L9N_T1_DQS_AD7N_35         Sch = HDMI_RX_SCL
#set_property -dict { PACKAGE_PIN "H2"    IOSTANDARD LVCMOS33 }  [get_ports { hdmi_rx_sda  }];                           # IO_L8P_T1_AD14P_35            Sch = HDMI_RX_SDA
#set_property -dict { PACKAGE_PIN "J1"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_rx_n[0] }];                           # IO_L7N_T1_AD6N_35             Sch = HDMI_RX0_N
#set_property -dict { PACKAGE_PIN "K1"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_rx_p[0] }];                           # IO_L7P_T1_AD6P_35             Sch = HDMI_RX0_P
#set_property -dict { PACKAGE_PIN "L1"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_rx_n[1] }];                           # IO_L15N_T2_DQS_35             Sch = HDMI_RX1_N
#set_property -dict { PACKAGE_PIN "M1"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_rx_p[1] }];                           # IO_L15P_T2_DQS_35             Sch = HDMI_RX1_P
#set_property -dict { PACKAGE_PIN "N2"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_rx_n[2] }];                           # IO_L22N_T3_35                 Sch = HDMI_RX2_N
#set_property -dict { PACKAGE_PIN "P2"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_rx_p[2] }];                           # IO_L22P_T3_35                 Sch = HDMI_RX2_P

##HDMI out
#set_property -dict { PACKAGE_PIN "E2"    IOSTANDARD LVCMOS33 }  [get_ports { hdmi_tx_cec  }];                           # IO_L4P_T0_35                  Sch = HDMI_TX_CEC
#set_property -dict { PACKAGE_PIN "K3"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_tx_clk_n}];                           # IO_L14N_T2_SRCC_35            Sch = HDMI_TX_CLK_N
#set_property -dict { PACKAGE_PIN "L3"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_tx_clk_p}];                           # IO_L14P_T2_SRCC_35            Sch = HDMI_TX_CLK_P
#set_property -dict { PACKAGE_PIN "B2"    IOSTANDARD LVCMOS33 }  [get_ports { hdmi_tx_hpd  }];                           # IO_L2N_T0_AD12N_35            Sch = HDMI_TX_HOT
#set_property -dict { PACKAGE_PIN "D2"    IOSTANDARD LVCMOS33 }  [get_ports { hdmi_tx_rscl }];                           # IO_L4N_T0_35                  Sch = HDMI_TX_SCL
#set_property -dict { PACKAGE_PIN "C2"    IOSTANDARD LVCMOS33 }  [get_ports { hdmi_tx_rsda }];                           # IO_L2P_T0_AD12P_35            Sch = HDMI_TX_SDA
#set_property -dict { PACKAGE_PIN "A1"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_tx_n[0] }];                           # IO_L1N_T0_AD4N_35             Sch = HDMI_TX0_N
#set_property -dict { PACKAGE_PIN "B1"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_tx_p[0] }];                           # IO_L1P_T0_AD4P_35             Sch = HDMI_TX0_P
#set_property -dict { PACKAGE_PIN "D1"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_tx_n[1] }];                           # IO_L3N_T0_DQS_AD5N_35         Sch = HDMI_TX1_N
#set_property -dict { PACKAGE_PIN "E1"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_tx_p[1] }];                           # IO_L3P_T0_DQS_AD5P_35         Sch = HDMI_TX1_P
#set_property -dict { PACKAGE_PIN "F1"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_tx_n[2] }];                           # IO_L5N_T0_AD13N_35            Sch = HDMI_TX2_N
#set_property -dict { PACKAGE_PIN "G1"    IOSTANDARD TMDS_33  }  [get_ports { hdmi_tx_p[2] }];                           # IO_L5P_T0_AD13P_35            Sch = HDMI_TX2_P

####################################################################################################################
#                                               Gigabit Ethernet                                                   #
####################################################################################################################
#set_property -dict  {PACKAGE_PIN  "P16"   IOSTANDARD  LVCMOS33   SLEW FAST } [get_ports {mdio}]         ;               # IO_L24P_T3_A01_D17_14         Sch = ETH_MDIO
#set_property -dict  {PACKAGE_PIN  "R19"   IOSTANDARD  LVCMOS33   SLEW FAST } [get_ports {mdc}]          ;               # IO_L5N_T0_D07_14              Sch = ETH_MDC
#set_property -dict  {PACKAGE_PIN  "R14"   IOSTANDARD  LVCMOS33   SLEW FAST } [get_ports {phy_reset_n}]  ;               # IO_L19N_T3_A09_D25_VREF_14    Sch = ETH_RESET_B
#set_property -dict  {PACKAGE_PIN  "V18"   IOSTANDARD  LVCMOS33   SLEW FAST } [get_ports {TXD[0]}]       ;               # IO_L14P_T2_SRCC_14            Sch = ETH_TXD0
#set_property -dict  {PACKAGE_PIN  "U18"   IOSTANDARD  LVCMOS33   SLEW FAST } [get_ports {TXD[1]}]       ;               # IO_L18N_T2_A11_D27_14         Sch = ETH_TXD1
#set_property -dict  {PACKAGE_PIN  "V17"   IOSTANDARD  LVCMOS33   SLEW FAST } [get_ports {TXD[2]}]       ;               # IO_L16P_T2_CSI_B_14           Sch = ETH_TXD2
#set_property -dict  {PACKAGE_PIN  "U17"   IOSTANDARD  LVCMOS33   SLEW FAST } [get_ports {TXD[3]}]       ;               # IO_L18P_T2_A12_D28_14         Sch = ETH_TXD3
#set_property -dict  {PACKAGE_PIN  "T20"   IOSTANDARD  LVCMOS33   SLEW FAST } [get_ports {TxCtl}]        ;               # IO_L6N_T0_D08_VREF_14         Sch = ETH_TXCTL
#set_property -dict  {PACKAGE_PIN  "U20"   IOSTANDARD  LVCMOS33   SLEW FAST } [get_ports {TxClk}]        ;               # IO_L11P_T1_SRCC_14            Sch = ETH_TXCLK
#set_property -dict  {PACKAGE_PIN  "AB18"  IOSTANDARD  LVCMOS33 } [get_ports {RXD[0]}] ;                                 # IO_L17N_T2_A13_D29_14         Sch = ETH_RXD0
#set_property -dict  {PACKAGE_PIN  "W20"   IOSTANDARD  LVCMOS33 } [get_ports {RXD[1]}] ;                                 # IO_L12N_T1_MRCC_14            Sch = ETH_RXD1
#set_property -dict  {PACKAGE_PIN  "W17"   IOSTANDARD  LVCMOS33 } [get_ports {RXD[2]}] ;                                 # IO_L16N_T2_A15_D31_14         Sch = ETH_RXD2
#set_property -dict  {PACKAGE_PIN  "V20"   IOSTANDARD  LVCMOS33 } [get_ports {RXD[3]}] ;                                 # IO_L11N_T1_SRCC_14            Sch = ETH_RXD3
#set_property -dict  {PACKAGE_PIN  "Y19"   IOSTANDARD  LVCMOS33 } [get_ports {RxCtl}]  ;                                 # IO_L13N_T2_MRCC_14            Sch = ETH_RXCTL
#set_property -dict  {PACKAGE_PIN  "W19"   IOSTANDARD  LVCMOS33 } [get_ports {RxClk}]  ;                                 # IO_L12P_T1_MRCC_14            Sch = ETH_RXCLK

###################################################################################################################
#                                               Display Port                                                      #
###################################################################################################################
#set_property -dict { PACKAGE_PIN "A8" } [get_ports { DPRX_LANE_N[0] }]    ;                                             # MGTPRXN0_216                  Sch = DPRX_LANE_0_N
#set_property -dict { PACKAGE_PIN "B8" } [get_ports { DPRX_LANE_P[0] }]    ;                                             # MGTPRXP0_216                  Sch = DPRX_LANE_0_P
#set_property -dict { PACKAGE_PIN "A4" } [get_ports { DPTX_LANE_N[0] }]    ;                                             # MGTPTXN0_216                  Sch = DPTX_LANE_0_N
#set_property -dict { PACKAGE_PIN "B4" } [get_ports { DPTX_LANE_P[0] }]    ;                                             # MGTPTXP0_216                  Sch = DPTX_LANE_0_P
#set_property -dict { PACKAGE_PIN "C11"} [get_ports { DPRX_LANE_N[1] }]    ;                                             # MGTPRXN1_216                  Sch = DPRX_LANE_1_N
#set_property -dict { PACKAGE_PIN "D11"} [get_ports { DPRX_LANE_P[1] }]    ;                                             # MGTPRXP1_216                  Sch = DPRX_LANE_1_P
#set_property -dict { PACKAGE_PIN "C5" } [get_ports { DPTX_LANE_N[1] }]    ;                                             # MGTPTXN1_216                  Sch = DPTX_LANE_1_N
#set_property -dict { PACKAGE_PIN "D5" } [get_ports { DPTX_LANE_P[1] }]    ;                                             # MGTPTXP1_216                  Sch = DPTX_LANE_1_P
#set_property -dict { PACKAGE_PIN "A10"} [get_ports { DPRX_LANE_N[2] }]    ;                                             # MGTPRXN2_216                  Sch = DPRX_LANE_2_N
#set_property -dict { PACKAGE_PIN "B10"} [get_ports { DPRX_LANE_P[2] }]    ;                                             # MGTPRXP2_216                  Sch = DPRX_LANE_2_P
#set_property -dict { PACKAGE_PIN "A6" } [get_ports { DPTX_LANE_N[2] }]    ;                                             # MGTPTXN2_216                  Sch = DPTX_LANE_2_N
#set_property -dict { PACKAGE_PIN "B6" } [get_ports { DPTX_LANE_P[2] }]    ;                                             # MGTPTXP2_216                  Sch = DPTX_LANE_2_P
#set_property -dict { PACKAGE_PIN "C9" } [get_ports { DPRX_LANE_N[3] }]    ;                                             # MGTPRXN3_216                  Sch = DPRX_LANE_3_N
#set_property -dict { PACKAGE_PIN "D9" } [get_ports { DPRX_LANE_P[3] }]    ;                                             # MGTPRXP3_216                  Sch = DPRX_LANE_3_P
#set_property -dict { PACKAGE_PIN "C7" } [get_ports { DPTX_LANE_N[3] }]    ;                                             # MGTPTXN3_216                  Sch = DPTX_LANE_3_N
#set_property -dict { PACKAGE_PIN "D7" } [get_ports { DPTX_LANE_P[3] }]    ;                                             # MGTPTXP3_216                  Sch = DPTX_LANE_3_P

#set_property -dict { PACKAGE_PIN "F6" } [get_ports { DP_REFCLK_P }]   ;                                                 # MGTREFCLK0P_216               Sch = DP_REFCLK_P
#set_property -dict { PACKAGE_PIN "E6" } [get_ports { DP_REFCLK_N }]   ;                                                 # MGTREFCLK0N_216               Sch = DP_REFCLK_N
#set_property -dict { PACKAGE_PIN "F10"} [get_ports { MGTREFCLK1_P}]   ;                                                 # MGTREFCLK1P_216               Sch = MGTREFCLK1_P
#set_property -dict { PACKAGE_PIN "E10"} [get_ports { MGTREFCLK1_N}]   ;                                                 # MGTREFCLK1N_216               Sch = MGTREFCLK1_N

#set_property -dict  { PACKAGE_PIN "E3"    IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {DP_TX_HPD}]    ;                # IO_L6N_T0_VREF_35             Sch = DP_TX_HPD
#set_property -dict  { PACKAGE_PIN "K6"    IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {DPTXCONFIG[0]}];                # IO_L17P_T2_35                 Sch = DPTXCONFIG1
#set_property -dict  { PACKAGE_PIN "J6"    IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {DPTXCONFIG[1]}];                # IO_L17N_T2_35                 Sch = DPTXCONFIG2
#set_property -dict  { PACKAGE_PIN "J5"    IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {DPTXAUXCH_P}]  ;                # IO_L10P_T1_AD15P_35           Sch = DPTXAUXCH_P
#set_property -dict  { PACKAGE_PIN "H5"    IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {DPTXAUXCH_N}]  ;                # IO_L10N_T1_AD15N_35           Sch = DPTXAUXCH_N
#set_property -dict  { PACKAGE_PIN "F3"    IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {DP_RX_HPD}]    ;                # IO_L6P_T0_35                  Sch = DP_RX_HPD
#set_property -dict  { PACKAGE_PIN "G4"    IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {DPRXCONFIG[0]}];                # IO_L12N_T1_MRCC_35            Sch = DPRXCONFIG1
#set_property -dict  { PACKAGE_PIN "F4"    IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {DPRXCONFIG[1]}];                # IO_0_35                       Sch = DPRXCONFIG2
#set_property -dict  { PACKAGE_PIN "H3"    IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {DPRXAUXCH_P}]  ;                # IO_L11P_T1_SRCC_35            Sch = DPRXAUXCH_P
#set_property -dict  { PACKAGE_PIN "G3"    IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {DPRXAUXCH_N]}] ;                # IO_L11N_T1_SRCC_35            Sch = DPRXAUXCH_N

###################################################################################################################
#                                               Header P12                                                        #
###################################################################################################################
#set_property -dict  { PACKAGE_PIN "J20"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[0]}];                       # IO_L11P_T1_SRCC_15            Sch = GPIO_1_P
#set_property -dict  { PACKAGE_PIN "J21"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[1]}];                       # IO_L11N_T1_SRCC_15            Sch = GPIO_1_N
#set_property -dict  { PACKAGE_PIN "K21"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[2]}];                       # IO_L9P_T1_DQS_AD3P_15         Sch = GPIO_2_P
#set_property -dict  { PACKAGE_PIN "K22"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[3]}];                       # IO_L9N_T1_DQS_AD3N_15         Sch = GPIO_2_N
#set_property -dict  { PACKAGE_PIN "H20"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[4]}];                       # IO_L8P_T1_AD10P_15            Sch = GPIO_3_P
#set_property -dict  { PACKAGE_PIN "G20"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[5]}];                       # IO_L8N_T1_AD10N_15            Sch = GPIO_3_N
#set_property -dict  { PACKAGE_PIN "J19"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[6]}];                       # IO_L12P_T1_MRCC_15            Sch = GPIO_4_P
#set_property -dict  { PACKAGE_PIN "H19"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[7]}];                       # IO_L12N_T1_MRCC_15            Sch = GPIO_4_N
#set_property -dict  { PACKAGE_PIN "J22"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[8]}];                   `   # IO_L7P_T1_AD2P_15             Sch = GPIO_5_P
#set_property -dict  { PACKAGE_PIN "H22"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[9]}];                       # IO_L7N_T1_AD2N_15             Sch = GPIO_5_N
#set_property -dict  { PACKAGE_PIN "K18"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[10]}];                      # IO_L13P_T2_MRCC_15            Sch = GPIO_6_P
#set_property -dict  { PACKAGE_PIN "K19"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[11]}];                      # IO_L13N_T2_MRCC_15            Sch = GPIO_6_N
#set_property -dict  { PACKAGE_PIN "L19"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[12]}];                      # IO_L14P_T2_SRCC_15            Sch = GPIO_7_P
#set_property -dict  { PACKAGE_PIN "L20"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[13]}];                      # IO_L14N_T2_SRCC_15            Sch = GPIO_7_N
#set_property -dict  { PACKAGE_PIN "M21"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[14]}];                      # IO_L10P_T1_AD11P_15           Sch = GPIO_8_P
#set_property -dict  { PACKAGE_PIN "L21"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[15]}];                      # IO_L10N_T1_AD11N_15           Sch = GPIO_8_N
#set_property -dict  { PACKAGE_PIN "N22"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[16]}];                      # IO_L15P_T2_DQS_15             Sch = GPIO_9_P
#set_property -dict  { PACKAGE_PIN "M22"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[17]}];                      # IO_L15N_T2_DQS_ADV_B_15       Sch = GPIO_9_N
#set_property -dict  { PACKAGE_PIN "N20"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[18]}];                      # IO_L18P_T2_A24_15             Sch = GPIO_10_P
#set_property -dict  { PACKAGE_PIN "M20"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[19]}];                      # IO_L18N_T2_A23_15             Sch = GPIO_10_N
#set_property -dict  { PACKAGE_PIN "M18"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[20]}];                      # IO_L16P_T2_A28_15             Sch = GPIO_11_P
#set_property -dict  { PACKAGE_PIN "L18"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[21]}];                      # IO_L16N_T2_A27_15             Sch = GPIO_11_N
#set_property -dict  { PACKAGE_PIN "N18"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[22]}];                      # IO_L17P_T2_A26_15             Sch = GPIO_12_P
#set_property -dict  { PACKAGE_PIN "N19"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[23]}];                      # IO_L17N_T2_A25_15             Sch = GPIO_12_N
#set_property -dict  { PACKAGE_PIN "H17"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[24]}];                      # IO_L6P_T0_15                  Sch = GPIO_13_P
#set_property -dict  { PACKAGE_PIN "H18"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[25]}];                      # IO_L6N_T0_VREF_15             Sch = GPIO_13_N
#set_property -dict  { PACKAGE_PIN "G17"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[26]}];                      # IO_L4P_T0_15                  Sch = GPIO_14_P
#set_property -dict  { PACKAGE_PIN "G18"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[27]}];                      # IO_L4N_T0_15                  Sch = GPIO_14_N
#set_property -dict  { PACKAGE_PIN "G15"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[28]}];                      # IO_L2P_T0_AD8P_15             Sch = GPIO_15_P
#set_property -dict  { PACKAGE_PIN "G16"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[29]}];                      # IO_L2N_T0_AD8N_15             Sch = GPIO_15_N
#set_property -dict  { PACKAGE_PIN "J15"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[30]}];                      # IO_L5P_T0_AD9P_15             Sch = GPIO_16_P
#set_property -dict  { PACKAGE_PIN "H15"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[31]}];                      # IO_L5N_T0_AD9N_15             Sch = GPIO_16_N
#set_property -dict  { PACKAGE_PIN "K13"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[32]}];                      # IO_L19P_T3_A22_15             Sch = GPIO_17_P
#set_property -dict  { PACKAGE_PIN "K14"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[33]}];                      # IO_L19N_T3_A21_VREF_15        Sch = GPIO_17_N
#set_property -dict  { PACKAGE_PIN "M13"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[34]}];                      # IO_L20P_T3_A20_15             Sch = GPIO_18_P
#set_property -dict  { PACKAGE_PIN "L13"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[35]}];                      # IO_L20N_T3_A19_15             Sch = GPIO_18_N
#set_property -dict  { PACKAGE_PIN "J14"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[36]}];                      # IO_L3P_T0_DQS_AD1P_15         Sch = GPIO_19_P
#set_property -dict  { PACKAGE_PIN "H14"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[37]}];                      # IO_L3N_T0_DQS_AD1N_15         Sch = GPIO_19_N
#set_property -dict  { PACKAGE_PIN "H13"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[38]}];                      # IO_L1P_T0_AD0P_15             Sch = GPIO_20_P
#set_property -dict  { PACKAGE_PIN "G13"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P12[39]}];                      # IO_L1N_T0_AD0N_15             Sch = GPIO_20_N

###################################################################################################################
#                                              Header P13                                                         #
###################################################################################################################
#set_property -dict  { PACKAGE_PIN "F19"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[0]}];                       # IO_L18P_T2_16                 Sch = GPIO_21_P
#set_property -dict  { PACKAGE_PIN "F20"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[1]}];                       # IO_L18N_T2_16                 Sch = GPIO_21_N
#set_property -dict  { PACKAGE_PIN "E19"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[2]}];                       # IO_L14P_T2_SRCC_16            Sch = GPIO_22_P
#set_property -dict  { PACKAGE_PIN "D19"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[3]}];                       # IO_L14N_T2_SRCC_16            Sch = GPIO_22_N
#set_property -dict  { PACKAGE_PIN "D20"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[4]}];                       # IO_L19P_T3_16                 Sch = GPIO_23_P
#set_property -dict  { PACKAGE_PIN "C20"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[5]}];                       # IO_L19N_T3_VREF_16            Sch = GPIO_23_N
#set_property -dict  { PACKAGE_PIN "C22"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[6]}];                       # IO_L20P_T3_16                 Sch = GPIO_24_P
#set_property -dict  { PACKAGE_PIN "B22"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[7]}];                       # IO_L20N_T3_16                 Sch = GPIO_24_N
#set_property -dict  { PACKAGE_PIN "F18"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[8]}];                       # IO_L15P_T2_DQS_16             Sch = GPIO_25_P
#set_property -dict  { PACKAGE_PIN "E18"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[9]}];                       # IO_L15N_T2_DQS_16             Sch = GPIO_25_N
#set_property -dict  { PACKAGE_PIN "C18"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[10]}];                      # IO_L13P_T2_MRCC_16            Sch = GPIO_26_P
#set_property -dict  { PACKAGE_PIN "C19"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[11]}];                      # IO_L13N_T2_MRCC_16            Sch = GPIO_26_N
#set_property -dict  { PACKAGE_PIN "D17"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[12]}];                      # IO_L12P_T1_MRCC_16            Sch = GPIO_27_P
#set_property -dict  { PACKAGE_PIN "C17"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[13]}];                      # IO_L12N_T1_MRCC_16            Sch = GPIO_27_N
#set_property -dict  { PACKAGE_PIN "B20"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[14]}];                      # IO_L16P_T2_16                 Sch = GPIO_28_P
#set_property -dict  { PACKAGE_PIN "A20"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[15]}];                      # IO_L16N_T2_16                 Sch = GPIO_28_N
#set_property -dict  { PACKAGE_PIN "B17"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[16]}];                      # IO_L11P_T1_SRCC_16            Sch = GPIO_29_P
#set_property -dict  { PACKAGE_PIN "B18"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[17]}];                      # IO_L11N_T1_SRCC_16            Sch = GPIO_29_N
#set_property -dict  { PACKAGE_PIN "A18"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[18]}];                      # IO_L17P_T2_16                 Sch = GPIO_30_P
#set_property -dict  { PACKAGE_PIN "A19"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[19]}];                      # IO_L17N_T2_16                 Sch = GPIO_30_N
#set_property -dict  { PACKAGE_PIN "E16"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[20]}];                      # IO_L5P_T0_16                  Sch = GPIO_31_P
#set_property -dict  { PACKAGE_PIN "D16"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[21]}];                      # IO_L5N_T0_16                  Sch = GPIO_31_N
#set_property -dict  { PACKAGE_PIN "B15"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[22]}];                      # IO_L7P_T1_16                  Sch = GPIO_32_P
#set_property -dict  { PACKAGE_PIN "B16"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[23]}];                      # IO_L7N_T1_16                  Sch = GPIO_32_N
#set_property -dict  { PACKAGE_PIN "A15"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[24]}];                      # IO_L9P_T1_DQS_16              Sch = GPIO_33_P
#set_property -dict  { PACKAGE_PIN "A16"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[25]}];                      # IO_L9N_T1_DQS_16              Sch = GPIO_33_N
#set_property -dict  { PACKAGE_PIN "C14"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[26]}];                      # IO_L3P_T0_DQS_16              Sch = GPIO_34_P
#set_property -dict  { PACKAGE_PIN "C15"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[27]}];                      # IO_L3N_T0_DQS_16              Sch = GPIO_34_N
#set_property -dict  { PACKAGE_PIN "A13"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[28]}];                      # IO_L10P_T1_16                 Sch = GPIO_35_P
#set_property -dict  { PACKAGE_PIN "A14"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[29]}];                      # IO_L10N_T1_16                 Sch = GPIO_35_N
#set_property -dict  { PACKAGE_PIN "C13"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[30]}];                      # IO_L8P_T1_16                  Sch = GPIO_36_P
#set_property -dict  { PACKAGE_PIN "B13"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[31]}];                      # IO_L8N_T1_16                  Sch = GPIO_36_N
#set_property -dict  { PACKAGE_PIN "D14"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[32]}];                      # IO_L6P_T0_16                  Sch = GPIO_37_P
#set_property -dict  { PACKAGE_PIN "D15"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[33]}];                      # IO_L6N_T0_VREF_16             Sch = GPIO_37_N
#set_property -dict  { PACKAGE_PIN "E13"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[34]}];                      # IO_L4P_T0_16                  Sch = GPIO_38_P
#set_property -dict  { PACKAGE_PIN "E14"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[35]}];                      # IO_L4N_T0_16                  Sch = GPIO_38_N
#set_property -dict  { PACKAGE_PIN "F13"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[36]}];                      # IO_L1P_T0_16                  Sch = GPIO_39_P
#set_property -dict  { PACKAGE_PIN "F14"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[37]}];                      # IO_L1N_T0_16                  Sch = GPIO_39_N
#set_property -dict  { PACKAGE_PIN "F16"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[38]}];                      # IO_L2P_T0_16                  Sch = GPIO_40_P
#set_property -dict  { PACKAGE_PIN "E17"   IOSTANDARD LVCMOS33   SLEW FAST } [get_ports {P13[39]}];                      # IO_L2N_T0_16                  Sch = GPIO_40_N
