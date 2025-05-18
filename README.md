# DecibelMeterVHDL

I was tasked with creating an open ended project that utilized the Zybo FPGA, at a least two PMODs. I decided to create a decibel meter that would measure the noisy environment in real time using my iPhone and sending the data over bluetooth to the Zybo FPGA. There are multiple implementations each using a different set of PMODs. 
The first set of PMOD are the BT2 bluetooth and OLED display. The second set are the BLE bluetooth low energy and Seven Segment Display. Finally I have the USB to UART and SSD. Along with this I include the iPhone application for measuring and sending data along with the seven segment display counter that was used to test functionality. 
