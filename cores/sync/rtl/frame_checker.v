`timescale 1ns/1ps

module frame_checker(
	input  wire        clk,
	input  wire        rst,
	input  wire        hsync,
	input  wire        vsync,
	output wire [15:0] hcnt,
	output wire [15:0] vcnt,
	output wire [15:0] hpwcnt,
	output wire [15:0] vpwcnt
);


reg [15:0] h_cnt, v_buff ,h_buff;
reg [15:0] hpw_cnt,vpw_cnt,hpw_buf,vpw_buf;
reg [15:0] act_cnt;
reg        vsync_q,hsync_q;
assign hcnt   = h_buff;
assign vcnt   = v_buff;
assign hpwcnt = hpw_buf;
assign vpwcnt = vpw_buf;

always@(posedge clk)
	if(rst)begin
		h_cnt   <= 16'd0;
		act_cnt <= 16'd0;
		vsync_q <= 1'b0;
		hsync_q <= 1'b0;
		vpw_cnt <= 16'd0;
		hpw_cnt <= 16'd0;
	end else begin
		vsync_q <= vsync;
		hsync_q <= hsync;
		//
		// counting Hsync during 1 frame
		//
		if({vsync,vsync_q} == 2'b10)begin
			hpw_cnt <= 16'd0;
			h_cnt   <= 16'd0;
			h_buff  <= h_cnt;
			hpw_buf <= hpw_cnt;
		end else begin
		if({hsync,hsync_q} == 2'b10)begin
			h_cnt     <= h_cnt + 16'd1;
			act_cnt   <= 16'd0;
			v_buff    <= act_cnt;
			vpw_cnt   <= 16'd0;
			vpw_buf   <= vpw_cnt;
		end else begin
			if(hsync)
				vpw_cnt  <= vpw_cnt + 16'd1;
				act_cnt  <= act_cnt + 16'd1;
			end
	 		if(vsync && {hsync,hsync_q} == 2'b10)
				hpw_cnt  <= hpw_cnt + 16'd1;
		end	
	end
endmodule
