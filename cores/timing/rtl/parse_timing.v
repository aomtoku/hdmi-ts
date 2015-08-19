module parse_timing # (
	parameter FPOCH_HORIZ = 11'd220,
	parameter FPOCH_VIRTC = 11'd20,
	parameter FRAME_WIDTH = 11'd1280,
	parameter FRAME_HIGHT = 11'd720
)(
	input  wire       pclk,
	input  wire       rstbtn_n, 
	input  wire       hsync,
	input  wire       vsync,
	output wire       video_en,
	output reg [11:0] index,
	output reg [10:0] video_hcnt,
	output reg [10:0] video_vcnt
);

reg  [10:0] vcounter;
reg  [10:0] hcounter;
reg         vactive;
reg         hactive;
reg         hsync_buf;

wire [10:0] vstart  = FPOCH_VIRTC - 11'd1;
wire [10:0] vfinish = FPOCH_VIRTC + FRAME_HIGHT - 11'd1;
wire [10:0] hstart  = FPOCH_HORIZ - 11'd1;
wire [10:0] hfinish = FPOCH_HORIZ + FRAME_WIDTH - 11'd1;
wire [10:0] hmiddle = FPOCH_HORIZ + FRAME_WIDTH/2 - 11'd1;

assign video_en = (vactive & hactive);

always@(posedge pclk) begin
	if(rstbtn_n) begin
		index      <= 12'd0;
		hcounter   <= 11'd0;
		vcounter   <= 11'd0;
		video_hcnt <= 11'd0;
		video_vcnt <= 11'd0;
		vactive    <= 1'b0;
		hactive    <= 1'b0;
		hsync_buf  <= 1'b0;
	end else begin
		hsync_buf <= hsync;
		// Counts Hsync and Vsync 
		if(vsync)
			vcounter <= 11'd0;
		else if({hsync, hsync_buf} == 2'b10)
			vcounter <= vcounter + 11'd1;
		if(hsync)
			hcounter <= 11'd0;
		else
			hcounter <= hcounter + 11'd1;

		// Active Verical line 
		//if(vcounter == 11'd19)   vactive <= 1'b1;
		//if(vcounter == 11'd739)  vactive <= 1'b0;
		if(vcounter == vstart)   vactive <= 1'b1;
		if(vcounter == vfinish)  vactive <= 1'b0;

		// Active Horizontal line 
		//if(hcounter == 11'd219)  hactive <= 1'b1;
		//if(hcounter == 11'd1499) hactive <= 1'b0;
		if(hcounter == hstart)  hactive <= 1'b1;
		if(hcounter == hfinish) hactive <= 1'b0;

		// Counts Horizontal line for FIFO
		if(video_en)
		    video_hcnt <= video_hcnt + 11'd1;
		else
		    video_hcnt <= 11'd0;
			 
		if(vactive)begin
			if({hsync, hsync_buf} == 2'b10)
				video_vcnt <= video_vcnt + 11'd1;
		end else 
			video_vcnt <= 11'd0;
			
		//if(video_vcnt == 11'd0 && hcounter == 11'd219)
		if(video_vcnt == 11'd0 && hcounter == FPOCH_HORIZ - 11'd1)
			index <= 12'd0;
		//else if(hcounter == 11'd219 || hcounter == 11'd859)
		else if(hcounter == FPOCH_HORIZ - 11'd1 || hcounter == hmiddle)
			index <= index + 12'd1;
	end
end

endmodule
