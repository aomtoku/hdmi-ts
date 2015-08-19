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
	// TMDS INPUT
	output wire [3:0] TX_TMDS,
	output wire [3:0] TX_TMDSB,
	// Ethernet PHY
	output wire       RESET,
	output wire       GTXCLK,
	output wire       TXEN,
	output wire       TXER,
	output wire [7:0] TXD,
	input  wire       RXCLK,
	input  wire       RXDV,
	input  wire [7:0] RXD,

	input  wire [3:0] SW,
	input  wire [3:0] DEBUG_SW,

	output wire [7:0] LED,
	output wire [4:0] JA
);

hdmits_top inst_hdmits_top(
	// SYSTEM
	.rstbtn(RSTBTN),    //The BTN NORTH
	.sys_clk(SYS_CLK),   //100 MHz osicallator
	// tx_tmds OUTPUT
	.rx_tmds(RX_TMDS),
	.rx_tmdsb(RX_TMDSB),
	.rx_scl(RX_SCL),
	.rx_sda(RX_SDA),
	// tx_tmds INPUT
	.tx_tmds(TX_TMDS),
	.tx_tmdsb(TX_TMDSB),
	// Ethernet PHY
	.gmii_reset(RESET),
	.gtxclk(GTXCLK),
	.gmii_txen(TXEN),
	.gmii_txerr(TXER),
	.gmii_txd(TXD),
	.gmii_rxclk(RXCLK),
	.gmii_rxdv(RXDV),
	.gmii_rxd(RXD),

	.slide_sw(SW),
	.mode_sw(DEBUG_SW),

	.led(LED),
	.probe_io(JA)
);



endmodule
