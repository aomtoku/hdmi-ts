`timescale 1ns / 1ps

`define simulation

module tb_gmiisend();


//
// System Clock 125MHz
//
reg sys_clk;
initial sys_clk = 1'b0;
always #8 sys_clk = ~sys_clk;

reg gmii_tx_clk;
initial gmii_tx_clk = 1'b0;
always #8 gmii_tx_clk = ~gmii_tx_clk;

reg fifo_clk;
initial fifo_clk = 1'b0;
always #13.468 fifo_clk = ~fifo_clk;


//
// Test Bench
//
reg sys_rst;
//reg rx_dv;
reg empty;
reg full;
wire rd_en;
wire TXEN;
wire [7:0]TXD;
reg [23:0]tx_data;

gmii_tx gmiisend(
	/*** FIFO ***/
	.fifo_clk(fifo_clk),
	.sys_rst(sys_rst),
	.dout(tx_data), //24bit
	.empty(empty),
	.full(full),
	.rd_en(rd_en),
	//.rd_clk(fifo_clk),
							
	/*** Ethernet PHY GMII ****/
	.tx_clk(gmii_tx_clk),
	.tx_en(TXEN),
	.txd(TXD)
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

reg [25:0] rom [0:2024];
reg [11:0]counter = 12'd0;

always@(posedge sys_clk)begin
	{full,empty, tx_data} 	<= rom[counter];
	counter		<= counter + 12'd1;
end


initial begin
	$dumpfile("./test.vcd");
	$dumpvars(0, tb_gmiisend);
	$readmemh("request.mem", rom);
	sys_rst = 1'b1;
	counter = 0;
	
	waitclock;
	waitclock;
	
	sys_rst = 1'b0;
	
	waitclock;
	
	
	#100000;
	$finish;
end

endmodule
