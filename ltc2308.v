module ltc2308(
	// FPGA clock
	input FPGA_CLK1_50,
	input FPGA_CLK2_50,
	input FPGA_CLK3_50,
	
	// FPGA ADC LTC2308 (SPI)
	output ADC_CONVST,
	output ADC_SCK,
	output ADC_SDI,
	input  ADC_SDO,
	
	// FPGA push button, LEDs and slide switches
	input  [1:0] KEY,
	output [7:0] LED,
	input  [3:0] SW,
	
	// Disabled because 0ohm resistor is not populated (hardwired to the LTC 2x7 connector)
	//inout HPS_LTC_GPIO,
	
	// HPS I2C 0 (hardwired to the Accelerometer)
	inout HPS_I2C0_SCLK,
	inout HPS_I2C0_SDAT,
	
	// HPS I2C 1 (hardwired to the LTC 2x7 connector)
	inout HPS_I2C1_SCLK,
	inout HPS_I2C1_SDAT
);

	// Wires for the PLL clock and reset
	wire pll0_clock0;
//	wire pll0_clock1;
	wire pll0_locked;
	wire my_reset = ~pll0_locked;  // Stay in reset if pll is not locked

	// PLL module instance
	pll (
	.refclk(FPGA_CLK1_50),   
	.outclk_0(pll0_clock0),	 // 40 MHz
	.locked(pll0_locked)
	);
	
	// ==========================
	// ADC LT2308 module instance
	// ==========================
	
	wire adc_ready;
	wire [11:0] adc_data;
	adc_ltc2308 adc0(
		.clock(pll0_clock0),
		.reset(my_reset),
		.start(1'b1),
		.channel(0),
		.ready(adc_ready),
		.data(adc_data),
		.CONVST(ADC_CONVST),
		.SCK(ADC_SCK),
		.SDI(ADC_SDI),
		.SDO(ADC_SDO)
	);
	
	// ========================================
	// Control loop to send ADC samples to UART
	// ========================================
	
//	// UART messages, etc..
//	localparam UART_MSG1_LEN = 6;
//	localparam [8*UART_MSG1_LEN-1:0] uart_msg1 = "ch0=0x";
//	localparam UART_ADC_DATA_LEN = 2;
	reg [7:0] uart_adc_data;
//	reg [2:0] uart_msg_counter;  // Max value = 2^(2+1) = 8. Value must be equal or greater than longest message
//	
	reg [3:0] state;
	reg [24:0] counter;

	assign LED[7:0] = uart_adc_data[11:4];
	
	always @ (posedge pll0_clock0 or posedge my_reset) begin
		// STATE: Reset?
		if(my_reset) begin
//			uart_enable <= 0;
			state <= 0;
			counter <= 0;
		end else begin

			case(state)
				
				// Delay
				0: begin
					if(counter == {25{1'b1}}) begin	// SVH: Replicate "1" 25 times = 33554431 40 MHz cycles ~= 0.84 s
						counter <= 0;
//						uart_msg_counter <= UART_MSG1_LEN - 1;
						state <= state + 1;
					end else begin
						counter <= counter + 1;
					end
				end
				
//				// Transmit uart_msg1 to UART
//				1: begin
//					case(uart_status)
//						0: begin
//							uart_data <= uart_msg1[8*uart_msg_counter +: 8];
//							uart_input_type <= 0;
//							uart_data_len <= 1;
//							uart_hex <= 0;
//							uart_new_line <= 0;
//							uart_enable <= 1;
//						end
//						2: begin
//							uart_enable <= 0;
//							if(uart_msg_counter > 0) begin
//								uart_msg_counter <= uart_msg_counter - 1;
//							end else begin
//								state <= state + 1;
//							end
//						end
//					endcase
//				end
//				
				// Wait for ADC data sample ready
//				2: begin
				1: begin
					if(adc_ready) begin
						uart_adc_data <= adc_data[11:4];
//						uart_msg_counter <= UART_ADC_DATA_LEN - 1;
						state <= state + 1;
					end
				end
				
//				// Transmit ADC data sample as hex value to UART 
//				3: begin
//					case(uart_status)
//						0: begin
//							uart_data <= uart_adc_data[8*uart_msg_counter +: 8];
//							uart_input_type <= 0;
//							uart_data_len <= 1;
//							uart_hex <= 1;
//							uart_new_line <= 0;
//							uart_enable <= 1;
//						end
//						2: begin
//							uart_enable <= 0;
//							if(uart_msg_counter > 0) begin
//								uart_msg_counter <= uart_msg_counter - 1;
//							end else begin
//								state <= state + 1;
//							end
//						end
//					endcase
//				end

				// Set LEDS based on ADC
				2: begin
					state <= 0;
				end

			endcase
		end
	end
endmodule
