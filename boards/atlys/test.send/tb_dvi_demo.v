`timescale 1ns / 1ps

`define simulation

module tb_dvi_demo();


//
// System Clock 125MHz
//
reg sys_clk;
initial sys_clk = 1'b0;
always #4 sys_clk = ~sys_clk;

//
// Ethernet Clock 125MHz
//
reg phy_clk;
initial phy_clk = 1'b0;
always #4 phy_clk = ~phy_clk;
//
// TMDS CLOCK 74.2MHz
//


reg tmds_clk;
initial tmds_clk = 1'b0;
always #6.734 tmds_clk = ~tmds_clk;


//
// Test Bench
//
reg sys_rst;
wire TXEN;
wire [7:0]TXD;
wire gtxclk;
wire phy_rst;


//-----------------------------------------------------------
//  FIFO(48bit) to GMII
//              Depth --> 4096
//-----------------------------------------------------------
wire full;
wire empty;
wire [47:0]tx_data;
wire rd_en;
reg [3:0]hsync, vsync;
wire hsyn = hsync[0];
wire vsyn = vsync[0];
reg [7:0]red,green,blue;
wire [47:0]din_fifo = {in_vcnt, in_hcnt, red, green, blue};
wire fifo_wr_en = (in_hcnt < 12'd1280 & in_vcnt < 12'd720) & video_en;

afifo48 asfifo(
        .Data(din_fifo),
        .WrClock(tmds_clk),
        .RdClock(phy_clk),
        .WrEn(fifo_wr_en),
        .RdEn(rd_en),
        .Reset(sys_rst),
        .RPReset(),
        .Q(tx_data),
        .Empty(empty),
        .Full(full)
);



  // TMDS HSYNC VSYNC COUNTER ()
  //           (1280x720 progressive 
  //                     HSYNC: 45khz   VSYNC : 60Hz)
  //-----------------------------------------------------
  
  wire [11:0]in_hcnt = {1'b0, video_hcnt[10:0]};
  wire [11:0]in_vcnt = {1'b0, video_vcnt[10:0]};
  wire [10:0]video_hcnt;
  wire [10:0]video_vcnt;
  wire video_en;

  tmds_timing timing(
                .rx0_pclk(tmds_clk),
                .rstbtn_n(sys_rst), 
                .rx0_hsync(hsyn),
                .rx0_vsync(vsyn),
                .video_en(video_en),
                .video_hcnt(video_hcnt),
                .video_vcnt(video_vcnt)
  );


gmii_tx gmii_tx(
        /*** FIFO ***/
        .fifo_clk(tmds_clk),
        .sys_rst(sys_rst),
        .dout(tx_data), //48bit
        .empty(empty),
        .full(full),
        .rd_en(rd_en),
        .wr_en(video_en),
        
        /*** Ethernet PHY GMII ***/
        .tx_clk(phy_clk),
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

reg [31:0] rom [0:2475000];
reg [21:0]counter = 22'd0;

always@(posedge tmds_clk)begin
	{vsync,hsync,red,green,blue} 	<= rom[counter];
	counter		<= counter + 22'd1;
end

reg [11:0]hcnt;
always@(posedge tmds_clk)begin
	if(in_hcnt == 0)
	    hcnt <= hcnt + 1;
	else 
	    hcnt <= in_hcnt;
end

initial begin
	$dumpfile("./test.vcd");
	$dumpvars(0, tb_dvi_demo);
	sys_rst = 1'b1;
	counter = 0;
	
	waitclock;
	waitclock;
	
	sys_rst = 1'b0;
	
	waitclock;
	
	$readmemh("request.mem", rom);
	counter = 0;
	$readmemh("request.mem", rom);
	counter = 0;
	$readmemh("request.mem", rom);
	
	#20000000;
	$finish;
end

endmodule
