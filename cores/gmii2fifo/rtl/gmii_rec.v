`timescale 1ns / 1ps

module gmii2fifo24#(
	parameter [31:0] ipv4_dst_rec  = {8'd192, 8'd168, 8'd0, 8'd1},
	parameter [15:0] dst_port_rec  = 16'd12345,
	parameter [15:0] packet_size   = 16'd1280
)(
	input  wire        clk125,
	input  wire        sys_rst,
	input  wire        id,
	input  wire [7:0]  rxd,
	input  wire        rx_dv,
	output reg  [28:0] datain,
	output reg         recv_en,
	output wire        packet_en
);

/* ------------------------------------------ 
 *  Parameters for Ether/IP
 * ------------------------------------------ */
parameter [15:0] ethernet_type = 16'h0800;
parameter [7:0]  ip_version    = 8'h45;
parameter [7:0]  ip_protcol    = 8'h11;
`define YUV_MODE
reg        packet_dv;
reg [15:0] rx_count;

assign packet_en = packet_dv;

//---------------------------------------------------------
//  Ethernet Header & IP Header & UDP Header
//---------------------------------------------------------
reg [15:0] eth_type;
reg [7:0]  ip_ver;
reg [7:0]  ipv4_proto;
reg [31:0] ipv4_src;
reg [31:0] ipv4_dst;
reg [15:0] src_port;
reg [15:0] dst_port;

//----------------------------------------------------------
//
//  Counting the Recv Byte
//					& Check each Header
//----------------------------------------------------------
reg        pre_en;
reg        data_en;
reg        invalid;
reg [11:0] x_info;
reg [11:0] y_info;

always@(posedge clk125) begin
	if(sys_rst) begin
		rx_count    <= 16'd0;
		eth_type    <= 16'h0;
		ip_ver      <= 8'h0;
		ipv4_proto  <= 8'h0;
		ipv4_src    <= 32'h0;
		ipv4_dst    <= 32'h0;
		src_port    <= 16'h0;
		dst_port    <= 16'h0;
		packet_dv   <= 1'b0;
		x_info      <= 12'h0;
		y_info      <= 12'h0;
		pre_en      <= 1'b0;
		data_en     <= 1'b0;
		invalid     <= 1'b0;
	end else begin
	  if(rx_dv && rxd == 8'hd5)
			data_en <= 1'b1;
		if(data_en)
			rx_count <= rx_count + 16'd1;

		case(rx_count[10:0])
			11'h0c: eth_type  [15:8]  <= rxd;
			11'h0d: eth_type  [7:0]   <= rxd;
			11'h0e: ip_ver    [7:0]   <= rxd;
			11'h17: ipv4_proto[7:0]   <= rxd;
			11'h1a: ipv4_src  [31:24] <= rxd;
			11'h1b: ipv4_src  [23:16] <= rxd;
			11'h1c: ipv4_src  [15:8]  <= rxd;
			11'h1d: ipv4_src  [7:0]   <= rxd;
			11'h1e: ipv4_dst  [31:24] <= rxd;
			11'h1f: ipv4_dst  [23:16] <= rxd;
			11'h20: ipv4_dst  [15:8]  <= rxd;
			11'h21: ipv4_dst  [7:0]   <= rxd;
			11'h22: src_port  [15:8]  <= rxd;
			11'h23: src_port  [7:0]   <= rxd;
			11'h24: dst_port  [15:8]  <= rxd;
			11'h25: dst_port  [7:0]   <= rxd;
			11'h2a: begin
				if(eth_type[15:0] == ethernet_type &&
					ip_ver    [7:0]  == ip_version &&
					ipv4_proto[7:0]  == ip_protcol &&
					ipv4_dst  [31:8] == ipv4_dst_rec[31:8] &&
					ipv4_dst  [7:0]  == (ipv4_dst_rec[7:0] + {7'd0, id}) &&
					dst_port  [15:0] == dst_port_rec) begin
					packet_dv 	<= 1'b1;
					y_info[7:0]	<= rxd;
				end
			end
			11'h2b: if(packet_dv) begin
				y_info[11:8]  <= rxd[3:0];
				x_info[3:0]   <= rxd[7:4];
				pre_en        <= 1'b1;
			end
			//11'd1323: begin // before 11'd1005
			//	packet_dv <= 1'b0;
			//	invalid   <= 1'b1;
			//	pre_en    <= 1'b0;
			//end
		endcase
		if (rx_count == packet_size + 16'd43) begin
			packet_dv <= 1'b0;
			invalid   <= 1'b1;
			pre_en    <= 1'b0;
		end
		if(~rx_dv) begin
			data_en     <=  1'd0;
			rx_count    <= 11'd0;
			eth_type    <= 16'h0;
			ip_ver      <=  8'h0;
			ipv4_proto  <=  8'h0;
			ipv4_src    <= 32'h0;
			ipv4_dst    <= 32'h0;
			src_port    <= 16'h0;
			dst_port    <= 16'h0;
			packet_dv   <=  1'b0;
			pre_en      <=  1'b0;
			invalid     <=  1'b0;
		end
	end
end

/* ----------------------------------------------------------
 *   Output Data for FIFO
 * ----------------------------------------------------------*/

parameter YUV_1 = 1'b0;
parameter YUV_2 = 1'b1;

reg [1:0]  state_data;
reg [10:0] d_cnt;


always@(posedge clk125) begin
	if(sys_rst) begin
		state_data  <= YUV_1;
		datain      <= 29'd0;
		recv_en     <= 1'd0;
		d_cnt       <= 11'd0;
	end else begin
		if(packet_dv && pre_en) begin
			if(state_data == YUV_1) begin
				datain[28:27]  <= {1'b0,x_info[0]};
				datain[26:16]  <= y_info[10:0];
				datain[15:8]   <= rxd;
				state_data     <= YUV_2;
				recv_en        <= 1'b0;
			end else begin
				recv_en      <= 1'b1;
				state_data   <= YUV_1;
				datain[7:0]  <= rxd;
				d_cnt        <= d_cnt + 11'd1;
			end			
		end else begin
			state_data  <= YUV_1;
			if(invalid) begin
				datain    <= 29'd0;
				recv_en   <= 1'b0;
				d_cnt     <= 11'd0;
			end else begin
				recv_en   <= 1'b0;
				d_cnt     <= 11'd0;
			end
		end
	end
end

endmodule
