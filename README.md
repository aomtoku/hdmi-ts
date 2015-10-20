#Debug 

BTN Left  --> Reset FIFO
BTN Right --> Next Data


Slide Switch 
3'b000 ---> {7'd0, RX\_CLK\_PLLLOCKD}
3'b001 ---> SDATA[7:0]
3'b010 ---> SDATA[15:8]
3'b011 ---> SDATA[23:16]
3'b100 ---> SDATA[31:24]
3'b101 ---> SDATA[39:32]




## Directory Structure  
 /cores/  Cores library, with Verilog sources, test benches and documentation.  
 /boards/     Top-level design files, constraint files and Makefiles for supported FPGA boards.  
 /software/   Software.


## Building tools  
You will need as Software:
 - Xilinx ISE 14.7
 - Impact  
   
You will need as Hardware:
 - HDMI cable supported 1.4a
 - HD Camera 
 - Digital Display

## How to build  
    $ cd boards/atlys/synthesis  
    $ make  

## Quickstart  
connect serial and JTAG cables in advance.  

    $ cd boards/atlys/synthesis  
    $ make load  

## DEMO : HDMI-TS
![hdmi-ts-app](http://web.sfc.wide.ad.jp/~aom/img/hdmi-ts-ap.png "hdmi-ts-app")


## Documentation



## Contact 
Email : aom at sfc.wide.ad.jp
