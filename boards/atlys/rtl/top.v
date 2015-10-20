`timescale 1 ps / 1 ps

module top (
	// SYSTEM
	input  wire       RSTBTN,    //The BTN NORTH
	input  wire       SYS_CLK,   //100 MHz osicallator
	// TMDS OUTPUT
	input  wire [3:0] RX_TMDS,
	input  wire [3:0] RX_TMDSB,
	input  wire       RX_SCL,
	inout  wire       RX_SDA,
	
	input  wire       BTNL,
	input  wire       BTNR,
	input  wire [3:0] SW,
	output wire [7:0] LED,
	output wire [3:0] JA
);

eval_top inst_eval_top(
	// SYSTEM
	.rstbtn(RSTBTN),    //The BTN NORTH
	.sys_clk(SYS_CLK),   //100 MHz osicallator
	// tx_tmds OUTPUT
	.rx_tmds(RX_TMDS),
	.rx_tmdsb(RX_TMDSB),
	.rx_scl(RX_SCL),
	.rx_sda(RX_SDA),
	.btnl(BTNL),
	.btnr(BTNR),
	.sw(SW),
	.led(LED),
	.probe_io(JA)
);

endmodule
