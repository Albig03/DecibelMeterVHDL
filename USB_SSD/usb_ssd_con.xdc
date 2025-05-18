# Clock
set_property -dict {PACKAGE_PIN L16 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 8.000 -name sys_clk_pin -waveform {0.000 4.000} -add [get_ports clk]

# Reset button (use BTN0 on Zybo)
set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS33} [get_ports rst]

# LEDs
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {leds[0]}]
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports {leds[1]}]
set_property -dict {PACKAGE_PIN G14 IOSTANDARD LVCMOS33} [get_ports {leds[2]}]
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports {leds[3]}]

# PMOD JB (for segments A, B, C, D)
set_property -dict {PACKAGE_PIN T20 IOSTANDARD LVCMOS33} [get_ports ssd_seg_a]
set_property -dict {PACKAGE_PIN U20 IOSTANDARD LVCMOS33} [get_ports ssd_seg_b]
set_property -dict {PACKAGE_PIN V20 IOSTANDARD LVCMOS33} [get_ports ssd_seg_c]
set_property -dict {PACKAGE_PIN W20 IOSTANDARD LVCMOS33} [get_ports ssd_seg_d]

# PMOD JC (for segments E, F, G, digit_sel)
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports ssd_seg_e]
set_property -dict {PACKAGE_PIN W15 IOSTANDARD LVCMOS33} [get_ports ssd_seg_f]
set_property -dict {PACKAGE_PIN T11 IOSTANDARD LVCMOS33} [get_ports ssd_seg_g]
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports ssd_digit_sel]

# PMOD JE (for USBUART)
set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33} [get_ports uart_rx]
set_property -dict {PACKAGE_PIN W16 IOSTANDARD LVCMOS33} [get_ports uart_tx]
