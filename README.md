#HDMI Transport System Project

## Directory Structure  
 /cores/  Cores library, with Verilog sources, test benches and documentation.  
  /boards/     Top-level design files, constraint files and Makefiles
                for supported FPGA boards.
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

## Preview HDMI-TS
![hdmi-ts-app](http://web.sfc.wide.ad.jp/~aom/img/hdmi-ts-ap.png "hdmi-ts-app")


## Documentation



## Contact 
Email : aom at sfc.wide.ad.jp
