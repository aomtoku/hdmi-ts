`timescale 1ns / 1ps

module tb_apple_out();

`define simulation
//
// GMII Clock 125MHz
//
reg sys_clk;
initial sys_clk = 1'b0;
always #8 sys_clk = ~sys_clk;

//
//TMDS clock 74.25MHz
//
reg tmds_clk;
initial tmds_clk = 1'b0;
always #13.468 tmds_clk = ~tmds_clk;


//
// Test Bench
//
reg sys_rst;
reg rx_dv;
reg [7:0]rxd;
//reg [7:0]o_r;
//reg [7:0]o_g;
//reg [7:0]o_b;
reg [11:0]i_vcnt;
reg [11:0]i_hcnt;
wire reset_timing;
wire [7:0]o_r,o_g,o_b;

datacontroller apple_out(
	.i_clk_74M(tmds_clk), //74.25 MHZ pixel clock
	.i_clk_125M(sys_clk),
	.i_rst(sys_rst),
	.i_format(2'b00),
	.i_vcnt(i_vcnt), //vertical counter from video timing generator
	.i_hcnt(i_hcnt), //horizontal counter from video timing generator^M
	.rx_dv(rx_dv),
        .rxd(rxd),
	.reset_timing(reset_timing),
	.gtxclk(sys_clk),
	.LED(),
	.SW(),
        .o_r(o_r),
        .o_g(o_g),
	.o_b(o_b)
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

reg [8:0] rom [0:1620];
reg [11:0]counter = 12'd0;

always@(posedge sys_clk)begin
	{rx_dv, rxd} 	<= rom[counter];
	counter			<= counter + 12'd1;
end

reg [23:0] tmds [0:1188000];
reg [20:0] tmds_count = 21'd0;

always@(posedge tmds_clk)begin
	{i_hcnt, i_vcnt} <= tmds[tmds_count];
	tmds_count <= tmds_count + 21'd1;
end

initial begin
	$dumpfile("./test.vcd");
	$dumpvars(0, tb_apple_out);
	$readmemh("request.mem", rom);
	$readmemh("tmds.mem",tmds);
	sys_rst = 1'b1;
	counter = 0;
	tmds_count = 0;
	
	waitclock;
	waitclock;
	
	sys_rst = 1'b0;
	
	waitclock;
	
	
	#1000000;
	$finish;
end

endmodule
