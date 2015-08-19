`timescale 1 ns / 1 ps

module rvsync (
	input  wire [10:0] tc_hsblnk,
	input  wire [10:0] tc_hssync,
	input  wire [10:0] tc_hesync,
	input  wire [10:0] tc_heblnk,

	output wire [10:0] hcount,
	output wire        hsync,
	output wire        hblnk,

	input  wire [10:0] tc_vsblnk,
	input  wire [10:0] tc_vssync,
	input  wire [10:0] tc_vesync,
	input  wire [10:0] tc_veblnk,

	output wire [10:0] vcount,
	output wire        vsync,
	output wire        vblnk,

	input  wire        restart,
	input  wire        clk74m,
	input  wire        clk125m,

	input  wire        fifo_wr_en,
	input  wire [10:0] y_din
);

reg [10:0] y_din_q,y_din_qq;
reg [10:0] vsync_f;

always@(posedge clk125m)begin
	if(restart)begin
		y_din_q     <= 11'b0;
		y_din_qq    <= 11'b0;
		vsync_f     <= 11'd0;
	end else begin
		y_din_qq <= y_din_q;
		if(fifo_wr_en)
			y_din_q <= y_din; 

		if(y_din_q < y_din_qq)
			vsync_f <= 12'b111111111111;
		else
			vsync_f <= {1'b0, vsync_f[10:1]};
		end
end

reg vsync_buf; //Double FF for vsync
reg vsync_buf_q;
reg vsync_buf_r;
reg vclr = 1'b0;

always@(posedge clk74m)begin
	if(restart)begin
		vsync_buf   <= 1'b0;
		vsync_buf_q <= 1'b0;
		vsync_buf_r <= 1'b0;
		vclr        <= 1'b0;
	end else begin
		vsync_buf   <= vsync_f[0];
		vsync_buf_q <= vsync_buf;
		vsync_buf_r <= vsync_buf_q;
		if ({vsync_buf_q,vsync_buf_r} == 2'b10)
			vclr <= 1'b1;
		else
			vclr <= 1'b0;
	end
end

//******************************************************************//
// This logic describes a 11-bit horizontal position counter.       //
//******************************************************************//

reg    [10:0] hpos_cnt = 0;
wire          hpos_clr;
wire          hpos_ena;

always @(posedge clk74m) begin : hcounter
	if(hpos_clr)
		hpos_cnt <= 11'b000_0000_0000;
	else if(hpos_ena)
		hpos_cnt <= hpos_cnt + 11'b000_0000_0001;
end

/******************************************************************/
// This logic describes a 11-bit vertical position counter.         //
//******************************************************************//

reg    [10:0] vpos_cnt = 0;
wire          vpos_clr;
wire          vpos_ena;

always @(posedge clk74m)
begin : vcounter
	if(vpos_clr)
		vpos_cnt <= 11'b000_0000_0000;
	else if(vpos_ena)
		vpos_cnt <= vpos_cnt + 11'b000_0000_0001;
end


//******************************************************************//
// This logic describes the position counter control.  Counters are //
// reset when they reach the total count and the counter is then    //
// enabled to advance.  Use of GTE operator ensures dynamic changes //
// to display timing parameters do not allow counters to run away.  //
//******************************************************************//

assign hpos_ena = 1'b1;
assign hpos_clr = ((hpos_cnt >= tc_heblnk) && hpos_ena ) || restart; // || vclr;

assign vpos_ena = hpos_clr;
assign vpos_clr = ((vpos_cnt >= tc_veblnk) && vpos_ena ) || restart || vclr;
//  assign vpos_clr = restart || vclr;

//******************************************************************//
// This is the logic for the horizontal outputs.  Active video is   //
// always started when the horizontal count is zero.  Example:      //
//                                                                  //
// tc_hsblnk = 03                                                   //
// tc_hssync = 07                                                   //
// tc_hesync = 11                                                   //
// tc_heblnk = 15 (htotal)                                          //
//                                                                  //
// hcount   00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15         //
// hsync    ________________________------------____________        //
// hblnk    ____________------------------------------------        //
//                                                                  //
// hsync time  = (tc_hesync - tc_hssync) pixels                     //
// hblnk time  = (tc_heblnk - tc_hsblnk) pixels                     //
// active time = (tc_hsblnk + 1) pixels                             //
//                                                                  //
//******************************************************************//

assign hcount = hpos_cnt;
assign hblnk = (hcount > tc_hsblnk);
assign hsync = (hcount > tc_hssync) && (hcount <= tc_hesync);

//******************************************************************//
// This is the logic for the vertical outputs.  Active video is     //
// always started when the vertical count is zero.  Example:        //
//                                                                  //
// tc_vsblnk = 03                                                   //
// tc_vssync = 07                                                   //
// tc_vesync = 11                                                   //
// tc_veblnk = 15 (vtotal)                                          //
//                                                                  //
// vcount   00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15         //
// vsync    ________________________------------____________        //
// vblnk    ____________------------------------------------        //
//                                                                  //
// vsync time  = (tc_vesync - tc_vssync) lines                      //
// vblnk time  = (tc_veblnk - tc_vsblnk) lines                      //
// active time = (tc_vsblnk + 1) lines                              //
//                                                                  //
//******************************************************************//

assign vcount = vpos_cnt;
assign vblnk = (vcount >= 11'd745) || (vcount < 11'd25);
assign vsync = (vcount < 5);

//******************************************************************//
//                                                                  //
//******************************************************************//

endmodule
