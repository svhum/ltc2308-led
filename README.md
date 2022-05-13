# ltc2308-led

This is a Quartus project that makes use of the LTC2308 ADC on the DE10-Nano development board. It samples a 12-bit value from channel 0 of the ADC every 0.86 seconds and writes the 8 most significant bits of the result to the LED array.

The ADC code is based on a helpful code from [truhy](https://github.com/truhy/adc_f2h_uart_de10nano).
