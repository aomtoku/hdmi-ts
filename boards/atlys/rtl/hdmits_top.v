`timescale 1 ps / 1 ps

`define FRAME_CHECK
`define HDMI_TMDS
module hdmits_top # (
	parameter SRC_MAC  = {8'h00,8'h23,8'h45,8'h67,8'h89,8'h01},
	parameter DST_MAC  = {8'h00,8'h23,8'h45,8'h67,8'h89,8'h02},
	parameter SRC_IP   = {8'd192, 8'd168, 8'd0, 8'd1},
	parameter DST_IP   = {8'd192, 8'd168, 8'd0, 8'd2},
	parameter SRC_PORT = 16'd12345,
	parameter DST_PORT = 16'd12346,
	parameter PKT_SIZE = 16'd1280
)(
	// SYSTEM
	input  wire       rstbtn,    //The BTN NORTH
	input  wire       sys_clk,   //100 MHz osicallator
	// tx_tmds OUTPUT
	input  wire [3:0] rx_tmds,
	input  wire [3:0] rx_tmdsb,
	input  wire       rx_scl,
	inout  wire       rx_sda,
	// tx_tmds INPUT
	output wire [3:0] tx_tmds,
	output wire [3:0] tx_tmdsb,
	// Ethernet PHY
	output wire       gmii_reset,
	output wire       gtxclk,
	output wire       gmii_txen,
	output wire       gmii_txerr,
	output wire [7:0] gmii_txd,
	input  wire       gmii_rxclk,
	input  wire       gmii_rxdv,
	input  wire [7:0] gmii_rxd,

	input  wire [3:0] slide_sw,
	input  wire [3:0] mode_sw,

	output wire [4:0] probe_io,
	output reg  [7:0] led
);

/* -------------------------------------------------------------------
 * Create global clock and synchronous system reset.                
 * ------------------------------------------------------------------- */
reg    clk_buf;
wire   clk50m, clk50m_bufg;
wire   clkfx, pclk, sysclk;
wire   locked, reset, pwrup, pclk_lckd;

assign clk50m = clk_buf;

always @(posedge sysclk) clk_buf <= ~clk_buf;

IBUFG sysclk_buf (.I(sys_clk), .O(sysclk));
BUFG clk50m_bufgbufg (.I(clk50m), .O(clk50m_bufg));

SRL16E #(.INIT(16'h1)) pwrup_0 (
	.Q(pwrup),
	.A0(1'b1),
	.A1(1'b1),
	.A2(1'b1),
	.A3(1'b1),
	.CE(pclk_lckd),
	.CLK(clk50m_bufg),
	.D(1'b0)
);

/* -----------------------------------------------------------
 *  GMII PHY Configuration
 * ----------------------------------------------------------- */
reg [20:0] coldsys_rst = 21'd0;
wire coldsys_rst10ms = (coldsys_rst == 21'h100000);
always @(posedge sysclk) coldsys_rst <= !coldsys_rst10ms ? coldsys_rst + 21'h1 : 21'h100000;
assign gmii_reset = coldsys_rst10ms;
assign gmii_txerr = 1'b0;

wire   clk_125M;
assign gtxclk = clk_125M;

clk_wiz_v3_6 clk125_gen ( .CLK_IN1(sysclk), .CLK_OUT1(clk_125M), .RESET(rstbtn) );

/* -----------------------------------------------------------
 * Gmii Recieve Logic
 * ----------------------------------------------------------- */
wire [28:0] fifo_din;
wire [10:0] y_din = fifo_din[26:16];
wire [ 1:0] x_din = fifo_din[28:27];
wire [28:0] dout;
wire        datavalid, recv_fifo_wr_en;

gmii2fifo24 #(
	.ipv4_dst_rec (SRC_IP),
	.dst_port_rec (SRC_PORT),
	.packet_size  (PKT_SIZE)
) gmii2fifo24 (
	.clk125       (gmii_rxclk),
	.sys_rst      (rstbtn),
	.id           (mode_sw[0]),
	.rxd          (gmii_rxd),
	.rx_dv        (gmii_rxdv),
	.datain       (fifo_din),
	.recv_en      (recv_fifo_wr_en),
	.packet_en    ()
);

/* ------------------------------------------------------------
 *  Gmii FIFO (Receiver ---> TMDS)
 * ----------------------------------------------------------- */
wire recv_full, recv_empty, fifo_read;
fifo29_32768 asfifo_recv (
	.rst     (reset)          , // Fifo Reset
	.wr_clk  (gmii_rxclk)     , // GMII RX clock 125MHz
	.rd_clk  (pclk)           , // tx_tmds clock 74.25MHz 
	.din     (fifo_din)       , // Data Input 29bit
	.wr_en   (recv_fifo_wr_en), // Write Enable
	.rd_en   (fifo_read)      , // Read Enable
	.dout    (dout)           , // data output 29bit
	.full    (recv_full)      , // Full signal
	.empty   (recv_empty)       // Empty signal
);
/* ----------------------------------------------------
 *  Switching screen formats
 * ---------------------------------------------------- */
wire busy;
wire  [3:0] sws_sync; //synchronous output

synchro #(.INITIALIZE("LOGIC0"))
synchro_sws_3 (.async(slide_sw[3]),.sync(sws_sync[3]),.clk(clk50m_bufg));

synchro #(.INITIALIZE("LOGIC0"))
synchro_sws_2 (.async(slide_sw[2]),.sync(sws_sync[2]),.clk(clk50m_bufg));

synchro #(.INITIALIZE("LOGIC0"))
synchro_sws_1 (.async(slide_sw[1]),.sync(sws_sync[1]),.clk(clk50m_bufg));

synchro #(.INITIALIZE("LOGIC0"))
synchro_sws_0 (.async(slide_sw[0]),.sync(sws_sync[0]),.clk(clk50m_bufg));

reg [3:0] sws_sync_q;
always @ (posedge clk50m_bufg) sws_sync_q <= sws_sync;

wire sw0_rdy, sw1_rdy, sw2_rdy, sw3_rdy;

debnce debsw0 (
	.sync(sws_sync_q[0]),
	.debnced(sw0_rdy),
	.clk(clk50m_bufg)
);

debnce debsw1 (
	.sync(sws_sync_q[1]),
	.debnced(sw1_rdy),
	.clk(clk50m_bufg)
);

debnce debsw2 (
	.sync(sws_sync_q[2]),
	.debnced(sw2_rdy),
	.clk(clk50m_bufg)
);

debnce debsw3 (
	.sync(sws_sync_q[3]),
	.debnced(sw3_rdy),
	.clk(clk50m_bufg)
);

reg switch = 1'b0;
always @ (posedge clk50m_bufg) begin
	switch <= pwrup | sw0_rdy | sw1_rdy | sw2_rdy | sw3_rdy;
end

wire gopclk;
defparam SRL16E_0.INIT = 16'h0;

SRL16E SRL16E_0 (
	.Q       (gopclk),
	.A0      (1'b1),
	.A1      (1'b1),
	.A2      (1'b1),
	.A3      (1'b1),
	.CE      (1'b1),
	.CLK     (clk50m_bufg),
	.D       (switch)
);

/* ----------------------------------------------------------------- *
 *  Pixel Clock Generator based on PLL
 * ----------------------------------------------------------------- */

parameter SW_CAMERA    = 4'b1001;

reg [7:0] pclk_M, pclk_D;
always @ (posedge clk50m_bufg) begin
	if(switch) begin
		case(sws_sync_q)
			SW_CAMERA: begin //108 MHz pixel clock
				pclk_M <= 8'd135 - 8'd1;
				pclk_D <= 8'd91 - 8'd1;
			end
			default: begin //74.25 MHz pixel clock
				pclk_M <= 8'd248 - 8'd1;
				pclk_D <= 8'd167 - 8'd1;
			end
		endcase
	end
end

wire progdone, progen, progdata;
dcmspi dcmspi_0 (
	.RST       (switch),        //Synchronous Reset
	.PROGCLK   (clk50m_bufg),   //SPI clock
	.PROGDONE  (progdone),      //DCM is ready to take next command
	.DFSLCKD   (pclk_lckd),
	.M         (pclk_M),        //DCM M value
	.D         (pclk_D),        //DCM D value
	.GO        (gopclk),        //Go programme the M and D value into DCM(1 cycle pulse)
	.BUSY      (busy),
	.PROGEN    (progen),        //SlaveSelect,
	.PROGDATA  (progdata)       //CommandData
);

DCM_CLKGEN #(
	.CLKFX_DIVIDE     (21),
	.CLKFX_MULTIPLY   (31),
	.CLKIN_PERIOD     (20.000)
)
PCLK_GEN_INST (
	.CLKFX            (clkfx),
	.CLKFX180         (),
	.CLKFXDV          (),
	.LOCKED           (pclk_lckd),
	.PROGDONE         (progdone),
	.STATUS           (),
	.CLKIN            (clk50m),
	.FREEZEDCM        (1'b0),
	.PROGCLK          (clk50m_bufg),
	.PROGDATA         (progdata),
	.PROGEN           (progen),
	.RST              (1'b0)
);

wire pllclk0, pllclk1, pllclk2;
wire pclkx2, pclkx10, pll_lckd;
wire clkfbout;

BUFG pclkbufg (.I(pllclk1), .O(pclk));
BUFG pclkx2bufg (.I(pllclk2), .O(pclkx2));

PLL_BASE # (
	.CLKIN_PERIOD     (13),
	.CLKFBOUT_MULT    (10), //set VCO to 10x of CLKIN
	.CLKOUT0_DIVIDE   (1),
	.CLKOUT1_DIVIDE   (10),
	.CLKOUT2_DIVIDE   (5),
	.COMPENSATION     ("INTERNAL")
) PLL_OSERDES (
	.CLKFBOUT         (clkfbout),
	.CLKOUT0          (pllclk0),
	.CLKOUT1          (pllclk1),
	.CLKOUT2          (pllclk2),
	.CLKOUT3          (),
	.CLKOUT4          (),
	.CLKOUT5          (),
	.LOCKED           (pll_lckd),
	.CLKFBIN          (clkfbout),
	.CLKIN            (clkfx),
	.RST              (~pclk_lckd)
);

wire serdesstrobe;
wire bufpll_lock;
BUFPLL #(.DIVIDE(5)) ioclk_buf (.PLLIN(pllclk0), .GCLK(pclkx2), .LOCKED(pll_lckd),
	.IOCLK(pclkx10), .SERDESSTROBE(serdesstrobe), .LOCK(bufpll_lock));

synchro #(.INITIALIZE("LOGIC1"))
synchro_reset (.async(!pll_lckd),.sync(reset),.clk(pclk));

/* ------------------------------------------------------------------------ *
 *  Video Timing Parameters
 * ------------------------------------------------------------------------ */

// 1280x720@60HZ
parameter HPIXELS_HDTV720P = 11'd1280; // Horizontal Live Pixels
parameter VLINES_HDTV720P  = 11'd720;  // Vertical Live ines
parameter HSYNCPW_HDTV720P = 11'd40;   // HSYNC Pulse Width
parameter VSYNCPW_HDTV720P = 11'd5;    // VSYNC Pulse Width
parameter HFNPRCH_HDTV720P = 11'd110;  // Horizontal Front Portch hotoha72
parameter VFNPRCH_HDTV720P = 11'd5;    // Vertical Front Portch
parameter HBKPRCH_HDTV720P = 11'd220;  // Horizontal Front Portch
parameter VBKPRCH_HDTV720P = 11'd20;   // Vertical Front Portch

// CAMERA 
parameter HPIXELS_CAMERA = 11'd1280;   // Horizontal Live Pixels
parameter VLINES_CAMERA  = 11'd720;    // Vertical Live ines
parameter HSYNCPW_CAMERA = 11'd39;     // HSYNC Pulse Width
parameter VSYNCPW_CAMERA = 11'd4;      // VSYNC Pulse Width
parameter HFNPRCH_CAMERA = 11'd110;    // Horizontal Front Portch hotoha72
parameter VFNPRCH_CAMERA = 11'd4;      // Vertical Front Portch
parameter HBKPRCH_CAMERA = 11'd220;    // Horizontal Front Portch
parameter VBKPRCH_CAMERA = 11'd22;     // default size is 25//Vertical Front Portch 

reg [10:0] tc_hsblnk;
reg [10:0] tc_hssync;
reg [10:0] tc_hesync;
reg [10:0] tc_heblnk;
reg [10:0] tc_vsblnk;
reg [10:0] tc_vssync;
reg [10:0] tc_vesync;
reg [10:0] tc_veblnk;

wire  [3:0] sws_clk;      //clk synchronous output

synchro #(.INITIALIZE("LOGIC0"))
clk_sws_3 (.async(slide_sw[3]),.sync(sws_clk[3]),.clk(pclk));

synchro #(.INITIALIZE("LOGIC0"))
clk_sws_2 (.async(slide_sw[2]),.sync(sws_clk[2]),.clk(pclk));

synchro #(.INITIALIZE("LOGIC0"))
clk_sws_1 (.async(slide_sw[1]),.sync(sws_clk[1]),.clk(pclk));

synchro #(.INITIALIZE("LOGIC0"))
clk_sws_0 (.async(slide_sw[0]),.sync(sws_clk[0]),.clk(pclk));

reg  [3:0] sws_clk_sync; //clk synchronous output
always @(posedge pclk) begin
	sws_clk_sync <= sws_clk;
end

reg hvsync_polarity; //1-Negative, 0-Positive
always @(*) begin
	case (sws_clk_sync)
		SW_CAMERA: begin
			hvsync_polarity = 1'b0; // positive polarity

			tc_hsblnk = HPIXELS_CAMERA - 11'd1;
			tc_hssync = HPIXELS_CAMERA - 11'd1 + HFNPRCH_CAMERA;
			tc_hesync = HPIXELS_CAMERA - 11'd1 + HFNPRCH_CAMERA + HSYNCPW_CAMERA;
			tc_heblnk = HPIXELS_CAMERA - 11'd1 + HFNPRCH_CAMERA + HSYNCPW_CAMERA + HBKPRCH_CAMERA;
			tc_vsblnk =  VLINES_CAMERA - 11'd1;
			tc_vssync =  VLINES_CAMERA - 11'd1 + VFNPRCH_CAMERA;
			tc_vesync =  VLINES_CAMERA - 11'd1 + VFNPRCH_CAMERA + VSYNCPW_CAMERA;
			tc_veblnk =  VLINES_CAMERA - 11'd1 + VFNPRCH_CAMERA + VSYNCPW_CAMERA + VBKPRCH_CAMERA;
		end

		default: begin //SW_HDTV720P:
			hvsync_polarity = 1'b0;

			tc_hsblnk = HPIXELS_HDTV720P - 11'd1;
			tc_hssync = HPIXELS_HDTV720P - 11'd1 + HFNPRCH_HDTV720P;
			tc_hesync = HPIXELS_HDTV720P - 11'd1 + HFNPRCH_HDTV720P + HSYNCPW_HDTV720P;
			tc_heblnk = HPIXELS_HDTV720P - 11'd1 + HFNPRCH_HDTV720P + HSYNCPW_HDTV720P + HBKPRCH_HDTV720P;
			tc_vsblnk =  VLINES_HDTV720P - 11'd1;
			tc_vssync =  VLINES_HDTV720P - 11'd1 + VFNPRCH_HDTV720P;
			tc_vesync =  VLINES_HDTV720P - 11'd1 + VFNPRCH_HDTV720P + VSYNCPW_HDTV720P;
			tc_veblnk =  VLINES_HDTV720P - 11'd1 + VFNPRCH_HDTV720P + VSYNCPW_HDTV720P + VBKPRCH_HDTV720P;
		end
	endcase
end

wire [10:0] bgnd_hcount;
wire [10:0] bgnd_vcount;
wire        VGA_HSYNC_INT, VGA_VSYNC_INT;
wire        bgnd_hsync;
wire        bgnd_hblnk;
wire        bgnd_vsync;
wire        bgnd_vblnk;
wire        restart = reset ;

rvsync inst_rvsync (
	.tc_hsblnk  (tc_hsblnk),      //input
	.tc_hssync  (tc_hssync),      //input
	.tc_hesync  (tc_hesync),      //input
	.tc_heblnk  (tc_heblnk),      //input
	.hcount     (bgnd_hcount),    //output
	.hsync      (VGA_HSYNC_INT),  //output
	.hblnk      (bgnd_hblnk),     //output
	.tc_vsblnk  (tc_vsblnk),      //input
	.tc_vssync  (tc_vssync),      //input
	.tc_vesync  (tc_vesync),      //input
	.tc_veblnk  (tc_veblnk),      //input
	.vcount     (bgnd_vcount),    //output
	.vsync      (VGA_VSYNC_INT),  //output
	.vblnk      (bgnd_vblnk),     //output
	.restart    (restart),
	.clk74m     (pclk),
	.clk125m    (gmii_rxclk),
	.fifo_wr_en (recv_fifo_wr_en),
	.y_din      (y_din)
);

wire        active;
wire [7:0]  red_data, green_data, blue_data;
wire [11:0] hcnt = {1'd0,bgnd_hcount};
wire [11:0] vcnt = {1'd0,bgnd_vcount};
reg         active_q, vsync, hsync;
reg         VGA_HSYNC, VGA_VSYNC;
reg         de;

assign active = !bgnd_hblnk && !bgnd_vblnk;

always @ (posedge pclk) begin
	hsync <= VGA_HSYNC_INT ^ hvsync_polarity ;
	vsync <= VGA_VSYNC_INT ^ hvsync_polarity ;
	VGA_HSYNC <= hsync;
	VGA_VSYNC <= vsync;

	active_q <= active;
	de <= active_q;
end

yub2rgb dataproc(
	.pclk        (pclk),
	.rst         (reset),
	.hcnt        (hcnt),
	.vcnt        (vcnt),
	.format      (2'b00),
	.fifo_read   (fifo_read),
	.data        (dout),
	.sw          (~mode_sw[3]),
	.o_r         (red_data),
	.o_g         (green_data),
	.o_b         (blue_data)
);

/* ------------------------------------------------------------ *
 *   HDMI Encoder
 * ------------------------------------------------------------ */
`ifdef HDMI_TMDS
dvi_encoder_top enc0 (
	.pclk          (pclk),            // pixel clock
	.pclkx2        (pclkx2),          // pixel clock x2
	.pclkx10       (pclkx10),         // pixel clock x10
	.serdesstrobe  (serdesstrobe),    // OSERDES2 serdesstrobe
	.rstin         (reset),           // reset
	.blue_din      (blue_data),       // Blue data in
	.green_din     (green_data),      // Green data in
	.red_din       (red_data),        // Red data in
	.aux0_din      (),                // Audio data in
	.aux1_din      (),                // Audio data in
	.aux2_din      (),                // Audio data in
	.hsync         (VGA_HSYNC),       // hsync data
	.vsync         (VGA_VSYNC),       // vsync data
	.ade           (1'b0),            // data enable (Audio)
	.vde           (de),              // data enable (Video)
	.TMDS          (tx_tmds),
	.TMDSB         (tx_tmdsb)
);
`else

wire [4:0] tmds_data0, tmds_data1, tmds_data2;
wire [2:0] tmdsint;
wire serdes_rst = rstbtn | ~bufpll_lock;

serdes_n_to_1 #(.SF(5)) oserdes0 (
	.ioclk       (pclkx10),
	.serdesstrobe(serdesstrobe),
	.reset       (serdes_rst),
	.gclk        (pclkx2),
	.datain      (tmds_data0),
	.iob_data_out(tmdsint[0])
);

serdes_n_to_1 #(.SF(5)) oserdes1 (
	.ioclk       (pclkx10),
	.serdesstrobe(serdesstrobe),
	.reset       (serdes_rst),
	.gclk        (pclkx2),
	.datain      (tmds_data1),
	.iob_data_out(tmdsint[1])
);

serdes_n_to_1 #(.SF(5)) oserdes2 (
	.ioclk       (pclkx10),
	.serdesstrobe(serdesstrobe),
	.reset       (serdes_rst),
	.gclk        (pclkx2),
	.datain      (tmds_data2),
	.iob_data_out(tmdsint[2])
);

OBUFDS tx_tmds0 (.I(tmdsint[0]), .O(tx_tmds[0]), .OB(tx_tmdsb[0])) ;
OBUFDS tx_tmds1 (.I(tmdsint[1]), .O(tx_tmds[1]), .OB(tx_tmdsb[1])) ;
OBUFDS tx_tmds2 (.I(tmdsint[2]), .O(tx_tmds[2]), .OB(tx_tmdsb[2])) ;

reg [4:0] tmdsclkint = 5'b00000;
reg toggle = 1'b0;

always @ (posedge pclkx2 or posedge serdes_rst) begin
	if (serdes_rst)
		toggle <= 1'b0;
	else
		toggle <= ~toggle;
end

always @ (posedge pclkx2) begin
	if (toggle)
		tmdsclkint <= 5'b11111;
	else
		tmdsclkint <= 5'b00000;
end

wire tmdsclk;

serdes_n_to_1 #(
	.SF           (5))
clkout (
	.iob_data_out (tmdsclk),
	.ioclk        (pclkx10),
	.serdesstrobe (serdesstrobe),
	.gclk         (pclkx2),
	.reset        (serdes_rst),
	.datain       (tmdsclkint)
);

OBUFDS tx_tmds3 (.I(tmdsclk), .O(tx_tmds[3]), .OB(tx_tmdsb[3])) ;// clock



dvi_encoder enc0 (
	.clkin      (pclk),
	.clkx2in    (pclkx2),
	.rstin      (reset),
	.blue_din   (blue_data),
	.green_din  (green_data),
	.red_din    (red_data),
	.hsync      (VGA_HSYNC),
	.vsync      (VGA_VSYNC),
	.de         (de),
	.tmds_data0 (tmds_data0),
	.tmds_data1 (tmds_data1),
	.tmds_data2 (tmds_data2)
);
`endif


/* -----------------------------------------------------------
 *   FIFO(48bit) to GMII
 *   	Depth --> 4096
 * ----------------------------------------------------------- */
wire        send_full;
wire        send_empty;
wire [47:0] tx_data;
wire        rd_en;
wire [47:0] din_fifo = {in_vcnt, index, rx_red, rx_green, rx_blue};
wire        rx_pclk;           
wire        rx_hsync;                   // hsync data
wire        rx_vsync;                   // vsync data
wire        send_fifo_wr_en = video_en; // (in_hcnt <= 12'd1280 & in_vcnt < 12'd720) & 

fifo48_8k asfifo_send (
	.rst     (rstbtn | rx_vsync),
	.wr_clk  (rx_pclk),                 // tx_tmds clock 74.25MHz 
	.rd_clk  (clk_125M),                // GMII TX clock 125MHz
	.din     (din_fifo),                // data input 48bit
	.wr_en   (send_fifo_wr_en),         // Write Enable
	.rd_en   (rd_en),                   // Read Enable
	.dout    (tx_data),                 // data output 48bit 
	.full    (send_full),
	.empty   (send_empty)
);


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

`ifdef HDMI_TMDS
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

`else 
dvi_decoder inst_decoder (
	//These are input ports
	.tmdsclk_p   (rx_tmds[3]),
	.tmdsclk_n   (rx_tmdsb[3]),
	.blue_p      (rx_tmds[0]),
	.green_p     (rx_tmds[1]),
	.red_p       (rx_tmds[2]),
	.blue_n      (rx_tmdsb[0]),
	.green_n     (rx_tmdsb[1]),
	.red_n       (rx_tmdsb[2]),
	.exrst       (rstbtn),

	//These are output ports
	.reset       (rx_reset),
	.pclk        (rx_pclk),
	.pclkx2      (rx_pclkx2),
	.pclkx10     (rx_pclkx10),
	.pllclk0     (rx_pllclk0), // PLL x10 output
	.pllclk1     (rx_pllclk1), // PLL x1 output
	.pllclk2     (rx_pllclk2), // PLL x2 output
	.pll_lckd    (rx_plllckd),
	.tmdsclk     (rx_tmdsclk),
	.serdesstrobe(rx_serdesstrobe),
	.hsync       (rx_hsync),
	.vsync       (rx_vsync),
	.de          (rx_vde),

	.blue_vld    (rx_blue_vld),
	.green_vld   (rx_green_vld),
	.red_vld     (rx_red_vld),
	.blue_rdy    (rx_blue_rdy),
	.green_rdy   (rx_green_rdy),
	.red_rdy     (rx_red_rdy),

	.psalgnerr   (rx_psalgnerr),

	.sdout       (rx_sdata),
	.red         (rx_red),
	.green       (rx_green),
	.blue        (rx_blue)
); 
`endif


/* -----------------------------------------------------
 *  tx_tmds HSYNC VSYNC COUNTER ()
 *  	(1280x720 progressive 
 *  		HSYNC: 45khz   VSYNC : 60Hz)
 * ----------------------------------------------------- */

wire [11:0] in_hcnt = {1'b0, video_hcnt[10:0]};
wire [11:0] in_vcnt = {1'b0, video_vcnt[10:0]};
wire [10:0] video_hcnt;
wire [10:0] video_vcnt;
wire [11:0] index;
wire        video_en;

parse_timing #(
	.FPOCH_HORIZ    (11'd220),  // Horizontal Front Porch  
	.FPOCH_VIRTC    (11'd20),   // Veritical  Front Porch
	.FRAME_WIDTH    (11'd1280), // Horizontal Video Active
	.FRAME_HIGHT    (11'd720)   // 
) inst_parse_timing (
	.pclk           (rx_pclk),
	.rstbtn_n       (rstbtn), 
	.hsync          (rx_hsync),
	.vsync          (rx_vsync),
	.video_en       (video_en),
	.index          (index),
	.video_hcnt     (video_hcnt),
	.video_vcnt     (video_vcnt)
);


/* ----------------------------------------------------------- *
 *  Video over IP Generator (Gmii Tx Logic)
 * ----------------------------------------------------------- */

gmii_tx #(
	.src_mac       (SRC_MAC),
	.dst_mac       (DST_MAC),
	.ip_src_addr   (SRC_IP),
	.ip_dst_addr   (DST_IP),
	.src_port      (SRC_PORT),
	.dst_port      (DST_PORT),
	.packet_size   (PKT_SIZE)
) gmii_tx (
	.id            (mode_sw[0]),
	// FIFO
	.fifo_clk      (rx_pclk),
	.sys_rst       (rstbtn),
	.dout          (tx_data), // 48bit
	.empty         (send_empty),
	.full          (send_full),
	.rd_en         (rd_en),
	.wr_en         (video_en),
	.sw            (~mode_sw[2]),
	
	// Ethernet PHY GMII
	.tx_clk        (clk_125M),
	.tx_en         (gmii_txen),
	.txd           (gmii_txd)
);

/* -----------------------------------------------------------
 *  DEBUG mode : Frame check
 * ----------------------------------------------------------- */
`ifdef FRAME_CHECK
wire [15:0]hf_cnt,vf_cnt,hpwcnt,vpwcnt;
frame_checker frame_checker(
	.clk     (rx_pclk),
	.rst     (rstbtn),
	.hsync   (rx_hsync),
	.vsync   (rx_vsync),
	.hcnt    (hf_cnt),
	.vcnt    (vf_cnt),
	.hpwcnt  (hpwcnt),
	.vpwcnt  (vpwcnt)
);
`endif

/* -----------------------------------------------------------
 *  DEBUG mode : Status LED
 * ----------------------------------------------------------- */
always @(gmii_rxclk) begin
	case(mode_sw[1])
		1'b0   : led <= {4'b0,recv_full,recv_empty,send_full,send_empty};
		default: led <= 8'd0;
	endcase
end

endmodule
