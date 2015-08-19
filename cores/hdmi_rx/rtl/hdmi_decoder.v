//////////////////////////////////////////////////////////////////////////////
//
//  Xilinx, Inc. 2010                 www.xilinx.com
//
//  XAPPxxx
//
//////////////////////////////////////////////////////////////////////////////
//
//  File name :       dvi_decoder.v
//
//  Description :     Spartan-6 DVI decoder top module
//
//
//  Author :          Bob Feng
//
//  Disclaimer: LIMITED WARRANTY AND DISCLAMER. These designs are
//              provided to you "as is". Xilinx and its licensors makeand you
//              receive no warranties or conditions, express, implied,
//              statutory or otherwise, and Xilinx specificallydisclaims any
//              implied warranties of merchantability, non-infringement,or
//              fitness for a particular purpose. Xilinx does notwarrant that
//              the functions contained in these designs will meet your
//              requirements, or that the operation of these designswill be
//              uninterrupted or error free, or that defects in theDesigns
//              will be corrected. Furthermore, Xilinx does not warrantor
//              make any representations regarding use or the results ofthe
//              use of the designs in terms of correctness, accuracy,
//              reliability, or otherwise.
//
//              LIMITATION OF LIABILITY. In no event will Xilinx or its
//              licensors be liable for any loss of data, lost profits,cost
//              or procurement of substitute goods or services, or forany
//              special, incidental, consequential, or indirect damages
//              arising from the use or operation of the designs or
//              accompanying documentation, however caused and on anytheory
//              of liability. This limitation will apply even if Xilinx
//              has been advised of the possibility of such damage. This
//              limitation shall apply not-withstanding the failure ofthe
//              essential purpose of any limited remedies herein.
//
//  Copyright  2004 Xilinx, Inc.
//  All rights reserved
//
//////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1ps

module hdmi_decoder (
  input  wire tmdsclk_p,      // tmds clock
  input  wire tmdsclk_n,      // tmds clock
  input  wire blue_p,         // Blue data in
  input  wire green_p,        // Green data in
  input  wire red_p,          // Red data in
  input  wire blue_n,         // Blue data in
  input  wire green_n,        // Green data in
  input  wire red_n,          // Red data in
  input  wire exrst,          // external reset input, e.g. reset button

  output wire reset,          // rx reset
  output wire pclk,           // regenerated pixel clock
  output wire pclkx2,         // double rate pixel clock
  output wire pclkx10,        // 10x pixel as IOCLK
  output wire pllclk0,        // send pllclk0 out so it can be fed into a different BUFPLL
  output wire pllclk1,        // PLL x1 output
  output wire pllclk2,        // PLL x2 output

  output wire pll_lckd,       // send pll_lckd out so it can be fed into a different BUFPLL
  output wire serdesstrobe,   // BUFPLL serdesstrobe output
  output wire tmdsclk,        // TMDS cable clock

  output wire hsync,          // hsync data
  output wire vsync,          // vsync data
  output wire ade,             // data enable
  output wire vde,             // data enable

  output wire blue_vld,
  output wire green_vld,
  output wire red_vld,
  output wire blue_rdy,
  output wire green_rdy,
  output wire red_rdy,

  output wire psalgnerr,
	output wire [7:0]debug,

  output wire [29:0] sdout,
	output wire [3:0] aux0,
	output wire [3:0] aux1,
	output wire [3:0] aux2,
  output wire [7:0] red,      // pixel data out
  output wire [7:0] green,    // pixel data out
  output wire [7:0] blue);    // pixel data out
    

  wire [9:0] sdout_blue, sdout_green, sdout_red;
/*
  assign sdout = {sdout_red[9], sdout_green[9], sdout_blue[9], sdout_red[8], sdout_green[8], sdout_blue[8],
                  sdout_red[7], sdout_green[7], sdout_blue[7], sdout_red[6], sdout_green[6], sdout_blue[6],
                  sdout_red[5], sdout_green[5], sdout_blue[5], sdout_red[4], sdout_green[4], sdout_blue[4],
                  sdout_red[3], sdout_green[3], sdout_blue[3], sdout_red[2], sdout_green[2], sdout_blue[2],
                  sdout_red[1], sdout_green[1], sdout_blue[1], sdout_red[0], sdout_green[0], sdout_blue[0]} ;
*/
  assign sdout = {sdout_red[9:5], sdout_green[9:5], sdout_blue[9:5],
                  sdout_red[4:0], sdout_green[4:0], sdout_blue[4:0]};

  wire vde_b, vde_g, vde_r;
  wire ade_b, ade_g, ade_r;

  //assign de = (de_b | de_g | de_r);
  assign vde = vde_r;
  assign ade = ade_r;
 //wire blue_vld, green_vld, red_vld;
 //wire blue_rdy, green_rdy, red_rdy;

  wire blue_psalgnerr, green_psalgnerr, red_psalgnerr;

  //
  // Send TMDS clock to a differential buffer and then a BUFIO2
  // This is a required path in Spartan-6 feed a PLL CLKIN
  //
  wire rxclkint;
  IBUFDS  #(.IOSTANDARD("TMDS_33"), .DIFF_TERM("FALSE")
  ) ibuf_rxclk (.I(tmdsclk_p), .IB(tmdsclk_n), .O(rxclkint));
 
  wire rxclk;

  BUFIO2 #(.DIVIDE_BYPASS("TRUE"), .DIVIDE(1))
  bufio_tmdsclk (.DIVCLK(rxclk), .IOCLK(), .SERDESSTROBE(), .I(rxclkint));

  BUFG tmdsclk_bufg (.I(rxclk), .O(tmdsclk));

  //
  // PLL is used to generate three clocks:
  // 1. pclk:    same rate as TMDS clock
  // 2. pclkx2:  double rate of pclk used for 5:10 soft gear box and ISERDES DIVCLK
  // 3. pclkx10: 10x rate of pclk used as IO clock
  //
  PLL_BASE # (
    .CLKIN_PERIOD(10),
    .CLKFBOUT_MULT(10), //set VCO to 10x of CLKIN
    .CLKOUT0_DIVIDE(1),
    .CLKOUT1_DIVIDE(10),
    .CLKOUT2_DIVIDE(5),
    .COMPENSATION("INTERNAL")
  ) PLL_ISERDES (
    .CLKFBOUT(clkfbout),
    .CLKOUT0(pllclk0),
    .CLKOUT1(pllclk1),
    .CLKOUT2(pllclk2),
    .CLKOUT3(),
    .CLKOUT4(),
    .CLKOUT5(),
    .LOCKED(pll_lckd),
    .CLKFBIN(clkfbout),
    .CLKIN(rxclk),
    .RST(exrst)
  );

  //
  // Pixel Rate clock buffer
  //
  BUFG pclkbufg (.I(pllclk1), .O(pclk));

  //////////////////////////////////////////////////////////////////
  // 2x pclk is going to be used to drive IOSERDES2 DIVCLK
  //////////////////////////////////////////////////////////////////
  BUFG pclkx2bufg (.I(pllclk2), .O(pclkx2));

  //////////////////////////////////////////////////////////////////
  // 10x pclk is used to drive IOCLK network so a bit rate reference
  // can be used by IOSERDES2
  //////////////////////////////////////////////////////////////////
  
  wire bufpll_lock;
  BUFPLL #(.DIVIDE(5)) ioclk_buf (.PLLIN(pllclk0), .GCLK(pclkx2), .LOCKED(pll_lckd),
           .IOCLK(pclkx10), .SERDESSTROBE(serdesstrobe), .LOCK(bufpll_lock));

  assign reset = ~bufpll_lock;

	//////////////////////////////////////////////////////////////////
	// decode video preamble/ data preamble
	//
	/////////////////////////////////////////////////////////////////
  wire ctl0, ctl1, ctl2, ctl3;
	reg  videopreamble;
  reg  dilndpreamble;
  always @ (posedge pclk) begin
    //videopreamble <=#1 ({ctl0, ctl1, ctl2, ctl3} === 4'b1000);
    videopreamble <=#1 ({ctl0, ctl1, ctl2, ctl3} === 4'b1000);
    //dilndpreamble <=#1 ({ctl0, ctl1, ctl2, ctl3} === 4'b1010);
    dilndpreamble <=#1 ({ctl0, ctl1, ctl2, ctl3} === 4'b1010);
  end

	assign debug = {hsync,vsync, ctl0, ctl1, ctl2, ctl3, 2'b0};


	wire blue_c1, blue_c0;
	//assign hsync = ade_b ? aux0[0] : blue_c0;
	//assign vsync = ade_b ? aux0[1] : blue_c1;
	assign hsync = blue_c0;
	assign vsync = blue_c1;
	//assign debug = videopreamble;
  // channel 0
  decode # (
		.CHANNEL("BLUE")
	) dec_b (
    .reset        (reset),
    .pclk         (pclk),
    .pclkx2       (pclkx2),
    .pclkx10      (pclkx10),
    .serdesstrobe (serdesstrobe),
    .din_p        (blue_p),
    .din_n        (blue_n),
    .other_ch0_rdy(green_rdy),
    .other_ch1_rdy(red_rdy),
    .other_ch0_vld(green_vld),
    .other_ch1_vld(red_vld),
		.videopreamble(videopreamble),
		.dilndpreamble(dilndpreamble),

    .iamvld       (blue_vld),
    .iamrdy       (blue_rdy),
    .psalgnerr    (blue_psalgnerr),
    .c0           (blue_c0),
    .c1           (blue_c1),
    .ade          (ade_b),
    .vde          (vde_b),
    .sdout        (sdout_blue),
    .adout        (aux0),
    .vdout        (blue)) ;
  
	// channel 1
  decode # (
		.CHANNEL("GREEN")
	) dec_g (
    .reset        (reset),
    .pclk         (pclk),
    .pclkx2       (pclkx2),
    .pclkx10      (pclkx10),
    .serdesstrobe (serdesstrobe),
    .din_p        (green_p),
    .din_n        (green_n),
    .other_ch0_rdy(blue_rdy),
    .other_ch1_rdy(red_rdy),
    .other_ch0_vld(blue_vld),
    .other_ch1_vld(red_vld),
		.videopreamble(videopreamble),
		.dilndpreamble(dilndpreamble),

    .iamvld       (green_vld),
    .iamrdy       (green_rdy),
    .psalgnerr    (green_psalgnerr),
    .c0           (ctl0),
    .c1           (ctl1),
    .ade          (ade_g),
    .vde          (vde_g),
    .sdout        (sdout_green),
    .adout        (aux1),
    .vdout        (green)) ;
  
	// channel 2
  decode # (
		.CHANNEL("RED")
	) dec_r (
    .reset        (reset),
    .pclk         (pclk),
    .pclkx2       (pclkx2),
    .pclkx10      (pclkx10),
    .serdesstrobe (serdesstrobe),
    .din_p        (red_p),
    .din_n        (red_n),
    .other_ch0_rdy(blue_rdy),
    .other_ch1_rdy(green_rdy),
    .other_ch0_vld(blue_vld),
    .other_ch1_vld(green_vld),
		.videopreamble(videopreamble),
		.dilndpreamble(dilndpreamble),

    .iamvld       (red_vld),
    .iamrdy       (red_rdy),
    .psalgnerr    (red_psalgnerr),
    .c0           (ctl2),
    .c1           (ctl3),
    .ade          (ade_r),
    .vde          (vde_r),
    .sdout        (sdout_red),
    .adout        (aux2),
    .vdout        (red)
) ;

  assign psalgnerr = red_psalgnerr | blue_psalgnerr | green_psalgnerr;

endmodule
