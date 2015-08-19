`timescale 1ns / 1ps

`define simulation

module tb_timing();


//
// System Clock 125MHz
//
reg sys_clk;
initial sys_clk = 1'b0;
always #8 sys_clk = ~sys_clk;


//
// Test Bench
//
reg sys_rst;
reg hsync,vsync;
wire video_en;
wire [10:0] video_hcnt,video_vcnt;


tmds_timing timing(
  .rx0_pclk(sys_clk),
  .rstbtn_n(sys_rst),
  .rx0_hsync(hsync),
  .rx0_vsync(vsync),
  .video_en(video_en),
  .video_hcnt(video_hcnt),
  .video_vcnt(video_vcnt)
);
//
// a clock
//
task waitclock;
begin
	@(posedge sys_clk);
	#1;
end
endtask

//
// Scinario
//

reg [1:0] rom [0:8360];
reg [15:0]counter = 16'd0;

always@(posedge sys_clk)begin
	{vsync,hsync} 	<= rom[counter];
	counter		<= counter + 12'd1;
end


initial begin
	$dumpfile("./test.vcd");
	$dumpvars(0, tb_timing);
	$readmemb("request.mem", rom);
	sys_rst = 1'b1;
	counter = 0;
	
	waitclock;
	waitclock;
	
	sys_rst = 1'b0;
	
	waitclock;
	
	
	#1000000;
	$finish;
end

endmodule
