`timescale 1 ps / 1 ps

module eval_top  (
	// SYSTEM
	input  wire       rstbtn,    //The BTN NORTH
	input  wire       sys_clk,   //100 MHz osicallator
	// tx_tmds OUTPUT
	input  wire [3:0] rx_tmds,
	input  wire [3:0] rx_tmdsb,
	input  wire       rx_scl,
	inout  wire       rx_sda,

	input  wire       btnl,
	input  wire       btnr,
	input  wire [3:0] sw,
	output wire [3:0] probe_io,
	output wire [7:0] led
);

/* -------------------------------------------------------------------
 * Create global clock and synchronous system reset.                
 * ------------------------------------------------------------------- */
reg    clk_buf;
wire   clk50m, clk50m_bufg;
wire   clkfx, pclk, sysclk;
wire   locked, reset, pwrup, pclk_lckd;

IBUFG sysclk_buf (.I(sys_clk), .O(sysclk));


/* -----------------------------------------------------------
 *  HDMI Decoder
 * ----------------------------------------------------------- */
wire        rx_tmdsclk;
wire        rx_pclkx10, rx_pllclk0;
wire        rx_plllckd;
wire        rx_reset;
wire        rx_serdesstrobe;

wire        rx_psalgnerr;      // channel phase alignment error
wire [7:0]  rx_red;            // pixel data out
wire [7:0]  rx_green;          // pixel data out
wire [7:0]  rx_blue;           // pixel data out
wire        rx_vde;
wire [29:0] rx_sdata;
wire        rx_blue_vld;
wire        rx_green_vld;
wire        rx_red_vld;
wire        rx_blue_rdy;
wire        rx_green_rdy;
wire        rx_red_rdy;

hdmi_decoder inst_decoder (
	.tmdsclk_p    (rx_tmds[3]),         // tmds clock
	.tmdsclk_n    (rx_tmdsb[3]),        // tmds clock
	.blue_p       (rx_tmds[0]),         // Blue data in
	.green_p      (rx_tmds[1]),         // Green data in
	.red_p        (rx_tmds[2]),         // Red data in
	.blue_n       (rx_tmdsb[0]),        // Blue data in
	.green_n      (rx_tmdsb[1]),        // Green data in
	.red_n        (rx_tmdsb[2]),        // Red data in
	.exrst        (rstbtn),             // external reset input, e.g. reset button

	.reset        (rx_reset),           // rx reset
	.pclk         (rx_pclk),            // regenerated pixel clock
	.pclkx2       (rx_pclkx2),          // double rate pixel clock
	.pclkx10      (rx_pclkx10),         // 10x pixel as IOCLK
	.pllclk0      (rx_pllclk0),         // send pllclk0 out so it can be fed into a different BUFPLL
	.pllclk1      (rx_pllclk1),         // PLL x1 output
	.pllclk2      (rx_pllclk2),         // PLL x2 output

	.pll_lckd     (rx_plllckd),         // send pll_lckd out so it can be fed into a different BUFPLL
	.serdesstrobe (rx_serdesstrobe),    // BUFPLL serdesstrobe output
	.tmdsclk      (rx_tmdsclk),         // TMDS cable clock

	.hsync        (rx_hsync),           // hsync data
	.vsync        (rx_vsync),           // vsync data
	.ade          (),                   // data enable (audio)
	.vde          (rx_vde),             // data enable (video)

	.blue_vld     (rx_blue_vld),
	.green_vld    (rx_green_vld),
	.red_vld      (rx_red_vld),
	.blue_rdy     (rx_blue_rdy),
	.green_rdy    (rx_green_rdy),
	.red_rdy      (rx_red_rdy),

	.psalgnerr    (rx_psalgnerr),
	.debug        (),
	
	.sdout        (rx_sdata),
	.aux0         (),
	.aux1         (),
	.aux2         (),
	.red          (rx_red),        // pixel data out
	.green        (rx_green),      // pixel data out
	.blue         (rx_blue)        // pixel data out
);   

i2c_edid inst_edid (
	.clk    (sysclk),
	.rst    (rstbtn),
	.scl    (rx_scl),
	.sda    (rx_sda)
);


wire wr_en = rx_plllckd && ~full;
wire rd_en, empty, full;
wire fifo_reset;

wire [39:0] din = {rx_sdata[29:0], 10'd0};
wire [39:0] dout;

fifo40 inst_fifo (
  .clk(rx_pclk), // input clk
  .rst(fifo_reset), // input rst
  .din(din), // input [39 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout), // output [39 : 0] dout
  .full(full), // output full
  .empty(empty) // output empty
);

reg [4:0] shft_cnt = 5'd0;
reg rd_en_reg;
reg rd_btn, rd_btn_reg;
reg rst_btn, rst_fifo_btn;

assign fifo_reset = rx_reset || shft_cnt != 5'd0;
assign rd_en = rd_en_reg;

always @ (posedge rx_pclk)
	if (rx_reset) begin
		rd_btn       <= 1'd0;
		rd_btn_reg   <= 1'd0;
		rd_en_reg    <= 1'd0;
		shft_cnt     <= 5'd0;
		rst_fifo_btn <= 1'd0;
		rst_btn      <= 1'd0;
	end else begin
		rd_btn       <= btnr;
		rd_btn_reg   <= rd_btn;
		rst_btn      <= btnl;
		rst_fifo_btn <= rst_btn;

		if (rst_fifo_btn)
			shft_cnt <= {shft_cnt[3:0], rst_fifo_btn};

		if ({rd_btn, rd_btn_reg} == 2'b10)
			rd_en_reg <= 1'b1;
		else 
			rd_en_reg <= 1'b0;
	end

assign probe_io = {rx_plllckd, rx_vde, rx_vsync, rx_hsync};
assign led      = (sw == 4'd0) ? {7'd0, rx_plllckd} : 
                  (sw == 4'd1) ? dout[7 : 0] :
                  (sw == 4'd2) ? dout[15: 8] :
                  (sw == 4'd3) ? dout[23:16] :
                  (sw == 4'd4) ? dout[31:24] :
                  (sw == 4'd5) ? dout[39:32] : 8'd0;

endmodule
