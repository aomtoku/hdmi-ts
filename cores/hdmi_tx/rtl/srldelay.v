//////////////////////////////////////////////////////////////////////////////
//
//  Xilinx, Inc. 2008                 www.xilinx.com
//
//////////////////////////////////////////////////////////////////////////////
//
//  File name :       srldelay.v
//
//  Description :     Delay Line Using SRL16 - maximum 16 taps of delay
//
//  Date - revision : March 2008 - v 1.0
//
//  Author :          Bob Feng
//
//  Disclaimer: LIMITED WARRANTY AND DISCLAMER. These designs are
//              provided to you "as is". Xilinx and its licensors make and you
//              receive no warranties or conditions, express, implied,
//              statutory or otherwise, and Xilinx specifically disclaims any
//              implied warranties of merchantability, non-infringement,or
//              fitness for a particular purpose. Xilinx does not warrant that
//              the functions contained in these designs will meet your
//              requirements, or that the operation of these designs will be
//              uninterrupted or error free, or that defects in the Designs
//              will be corrected. Furthermore, Xilinx does not warrantor
//              make any representations regarding use or the results of the
//              use of the designs in terms of correctness, accuracy,
//              reliability, or otherwise.
//
//              LIMITATION OF LIABILITY. In no event will Xilinx or its
//              licensors be liable for any loss of data, lost profits,cost
//              or procurement of substitute goods or services, or for any
//              special, incidental, consequential, or indirect damages
//              arising from the use or operation of the designs or
//              accompanying documentation, however caused and on any theory
//              of liability. This limitation will apply even if Xilinx
//              has been advised of the possibility of such damage. This
//              limitation shall apply not-withstanding the failure of the
//              essential purpose of any limited remedies herein.
//
//  Copyright © 2006 Xilinx, Inc.
//  All rights reserved
//
//////////////////////////////////////////////////////////////////////////////  
module srldelay # (
  parameter WIDTH = 1,       //data width
  parameter TAPS  = 4'b1111  //delay taps
)(
  input  wire                 clk,
  input  wire [(WIDTH - 1):0] data_i,
  output wire [(WIDTH - 1):0] data_o
);

  wire [3:0] dlytaps = TAPS;

  genvar i;
  generate
    for (i=0; i < WIDTH; i = i + 1) begin : srl
      SRL16E srl16_i (
        .Q   (data_o[i]),
        .A0  (dlytaps[0]),
        .A1  (dlytaps[1]),
        .A2  (dlytaps[2]),
        .A3  (dlytaps[3]),
        .CE  (1'b1),
        .CLK (clk),
        .D   (data_i[i])
      );
      
      defparam srl[i].srl16_i.INIT = 16'h0;
    end
  endgenerate

endmodule
