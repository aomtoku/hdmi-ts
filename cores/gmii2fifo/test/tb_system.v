`timescale 1ns / 1ns

module tb_system();


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
reg eof;
reg rx_dv;
reg [7:0] rxd;
wire [28:0] datain;
wire recv_en;
wire packet_en;

gmii2fifo24 gmiififo24_inst (
	.clk125(sys_clk),
	.sys_rst(sys_rst),
	.rxd(rxd),
	.rx_dv(rx_dv),
	.datain(datain),
	.recv_en(recv_en),
	.packet_en(packet_en)
);

//
// a clock
//
task waitclock;
begin
	@(posedge sys_clk);
//	#1;
end
endtask

//
// Check FIFO
//
reg [11:0] check_y = 12'd00, check_x = 12'd0;
wire [11:0] org_x, org_y;
assign org_x = (datain[15:0] - 4096);
assign org_y = {1'b0,datain[26:16]};

always @(posedge sys_clk) begin
	if (sys_rst) begin
	end else if (recv_en == 1'b1) begin
		if (datain[27] == 1'b0 &&  org_x >= 640) begin
			$display( "error type 0" );
			$display( " at ", check_x,",", check_y, "   data:" , org_x,",", org_y );
		end
		if (datain[27] == 1'b1 &&  org_x  < 640) begin
			$display( "error type 1" );
			$display( " at ", check_x,",", check_y, "   data:" , org_x,",", org_y );
		end
		if (org_x != check_x) begin
			$display( "error type 2" );
			$display( " at ", check_x,",", check_y, "   data:" , org_x,",", org_y );
		end
		if (org_y != check_y) begin
			$display( "error type 3" );
			$display( " at ", check_x,",", check_y, "   data:" , org_x,",", org_y );
		end
		if ( check_x != 12'd1279) begin
			check_x <= check_x + 12'd1;
		end else begin
			check_x <= 12'd0;
			if ( check_y != 12'd719) begin
				check_y <= check_y + 12'd1;
			end else begin
				check_y <= 12'd0;
			end
		end
	end
end

//
// Scinario
//

reg [9:0] rom [0:3890000];
reg [23:0] counter = 24'd0;

always @(posedge sys_clk) begin
	{eof, rx_dv, rxd} <= rom[counter];
	if (eof) begin
		$finish;
	end
	counter		<= counter + 24'd1;
end


initial begin
	$dumpfile("./test.vcd");
	$dumpvars(0, tb_system);
	$readmemh("phy_rx.hex", rom);
	sys_rst = 1'b1;
	counter = 0;
	
	waitclock;
	waitclock;
	
	sys_rst = 1'b0;
	
	waitclock;
	
	
//	#1000000;
//	$finish;
end

endmodule
