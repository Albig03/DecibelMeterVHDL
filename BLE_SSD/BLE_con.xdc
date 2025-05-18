## Clock signal
set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports { clk }]; #IO_L11P_T1_SRCC_35 Sch=sysclk
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }]

## Buttons
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { rst }]; #IO_L20N_T3_34 Sch=BTN0
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { btn_ble_reset }]; #IO_L24N_T3_34 Sch=BTN1
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { btn_ble_cmd }]; #IO_L18P_T2_34 Sch=BTN2

## LEDs
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { leds[0] }]; #IO_L23P_T3_35 Sch=LED0
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { leds[1] }]; #IO_L23N_T3_35 Sch=LED1
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { leds[2] }]; #IO_0_35 Sch=LED2
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { leds[3] }]; #IO_L3N_T0_DQS_AD1N_35 Sch=LED3

## BLE PMOD on JE 
# Connect BLE PMOD to JE (Pmod connector on the right side of the board)
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports { ble_tx }]; #IO_L4P_T0_34 Sch=JE1 - Connect to RX of RN4871
set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33 } [get_ports { ble_rx }]; #IO_L18N_T2_34 Sch=JE2 - Connect to TX of RN4871
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { ble_rts }]; #IO_25_35 Sch=JE3 - Connect to RTS
set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33 } [get_ports { ble_reset }]; #IO_L3N_T0_DQS_34 Sch=JE7 - Connect to RESET pin

## SSD PMOD on JB and JC
# Header J1 (Connect to JB)
set_property -dict { PACKAGE_PIN T20   IOSTANDARD LVCMOS33 } [get_ports { ssd_seg_a }]; #IO_L15P_T2_DQS_34 Sch=JB1
set_property -dict { PACKAGE_PIN U20   IOSTANDARD LVCMOS33 } [get_ports { ssd_seg_b }]; #IO_L15N_T2_DQS_34 Sch=JB2
set_property -dict { PACKAGE_PIN V20   IOSTANDARD LVCMOS33 } [get_ports { ssd_seg_c }]; #IO_L16P_T2_34 Sch=JB3
set_property -dict { PACKAGE_PIN W20   IOSTANDARD LVCMOS33 } [get_ports { ssd_seg_d }]; #IO_L16N_T2_34 Sch=JB4

# Header J2 JC
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { ssd_seg_e }]; #IO_L10P_T1_34 Sch=JC1_P
set_property -dict { PACKAGE_PIN W15   IOSTANDARD LVCMOS33 } [get_ports { ssd_seg_f }]; #IO_L10N_T1_34 Sch=JC1_N
set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33 } [get_ports { ssd_seg_g }]; #IO_L1P_T0_34 Sch=JC2_P
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { ssd_digit_sel }]; #IO_L1N_T0_34 Sch=JC2_N
