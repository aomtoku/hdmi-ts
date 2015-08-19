`timescale 1ns / 1ps

module tb_timing();


//
// System Clock 125MHz
//
reg sys_clk;
initial sys_clk = 1'b0;
always #4 sys_clk = ~sys_clk;

//
// System Clock 125MHz
//
reg tmds_clk;
initial tmds_clk = 1'b0;
always #6.74 tmds_clk = ~tmds_clk;


//
// Test Bench
//
reg sys_rst;
wire [10:0]hcount,vcount;
wire hsync,vsync,de;
reg fifo_wr_en = 0;

timing_parse timing(
    .clk(tmds_clk),
    .reset(sys_rst),
    .hvsync_polarity(1'b0),
    .fifo_wr_en(fifo_wr_en),
    .hcount(hcount),
    .hsync(hsync),
    .vcount(vcount),
    .vsync(vsync),
    .de(de)
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

task ifg;
begin
	@(posedge sys_clk);
	#14;
end
endtask

task pckt_gap;
begin
	@(posedge sys_clk);
	#75;
end
endtask
//
// Scinario
//
/*
reg [10:0]cnt;
reg en;
always @(posedge sys_clk)begin
	if(en)begin
	cnt <= cnt + 1;
	if(cnt == 54)
	   fifo_wr_en <= 1;
	if(cnt == 1334)
  	   fifo_wr_en <= 0;
	if(cnt == 1338)
	   cnt <= 0;
	end
end
*/
integer i,j;
initial begin
	$dumpfile("./test.vcd");
	$dumpvars(0, tb_timing);
	sys_rst = 1'b1;
	
	waitclock;
	waitclock;
	
	sys_rst = 1'b0;
	
	waitclock;
	
	for(i=0;i<720;i=i+1)begin
	    for(j=0;j<640;j=j+1)begin
		fifo_wr_en = 0;
		fifo_wr_en = 1;
	    end
	    for(j=0;j<370;j=j+1)
		fifo_wr_en = 0;
	end
	for(i=0;i<495000;i=i+1)
	    waitclock;
	
	#60000000;
	$finish;
end

endmodule
