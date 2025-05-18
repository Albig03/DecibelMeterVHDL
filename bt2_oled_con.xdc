# XDC file for Zybo Z7 board with PmodBT2 and PmodOLED connections
# Clock signal
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { clk_i }];
create_clock -period 8.000 -name sys_clk_pin -waveform {0.000 4.000} -add [get_ports { clk_i }]

# Reset button (active-high)
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { rst_i }];

# LEDs
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { leds_o[0] }];
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { leds_o[1] }];
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { leds_o[2] }];
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { leds_o[3] }];

# Pmod BT2 connected to Pmod JA
# Pin mapping for Pmod JA (Upper row)
set_property -dict { PACKAGE_PIN Y18   IOSTANDARD LVCMOS33 } [get_ports { bt_rx_i }];     # JA1
set_property -dict { PACKAGE_PIN Y19   IOSTANDARD LVCMOS33 } [get_ports { bt_tx_o }];     # JA2
set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33 } [get_ports { bt_cts_i }];    # JA3
set_property -dict { PACKAGE_PIN Y17   IOSTANDARD LVCMOS33 } [get_ports { bt_rts_o }];    # JA4
# Pin mapping for Pmod JA (Lower row) - Only need reset pin
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports { bt_reset_o }];  # JA7

# Pmod OLED connected to Pmod JB
# Pin mapping for Pmod JB (Upper row)
set_property -dict { PACKAGE_PIN T20   IOSTANDARD LVCMOS33 } [get_ports { oled_sdin_o }]; # JB1 - MOSI
set_property -dict { PACKAGE_PIN U20   IOSTANDARD LVCMOS33 } [get_ports { oled_sclk_o }]; # JB2 - SCK
set_property -dict { PACKAGE_PIN V20   IOSTANDARD LVCMOS33 } [get_ports { oled_dc_o }];   # JB3 - D/C
set_property -dict { PACKAGE_PIN W20   IOSTANDARD LVCMOS33 } [get_ports { oled_res_o }];  # JB4 - RES
# Pin mapping for Pmod JB (Lower row)
set_property -dict { PACKAGE_PIN T19   IOSTANDARD LVCMOS33 } [get_ports { oled_vbat_o }]; # JB7 - VBAT
set_property -dict { PACKAGE_PIN U19   IOSTANDARD LVCMOS33 } [get_ports { oled_vdd_o }];  # JB8 - VDD