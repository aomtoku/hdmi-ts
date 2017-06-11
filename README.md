# HDMI Transport System Project

HDMI-TS (HDMI Transport System) is low-latency HDMI video communication system by IP (Internet Protocol).
Sophisticated interactions between remote places requires low-latency such as, cooperative-working, remote controle, etc...
To this end, we developped sync method for video processing by hardware, RV-SYNC (Remote Virtical Sync).
The latency to remote host is equivalent to Virtical Front Porch Periods (e.g. 25 lines on 720p) on no L2/L3 switches.


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


## Published Paper (Domestic only)
 - Yuta Tokusashi, Yohei Kuga, Takeshi Matsuya, Osamu Nakamura, “Design and Implementation of An FPGA-Based Low-Latency HDMI Video Synchronization System”, IPSJ Journal, Vol.56, No.8 pp.1593-1603, Aug 2015. \[[IPSJ](http://id.nii.ac.jp/1001/00144711/)\]
 - Yuta Tokusashi, Yohei Kuga, Takeshi Matsuya, Jun Murai, “Improving the Naturalness of Internet Video Conversation using a Low-Latency Pipeline”, Proc. of Multimedia, Distributed, Cooperative and Mobile Symposium (DICOMO’13), Vol.2013, pp911-917, Jul 2013. \[[IPSJ](http://id.nii.ac.jp/1001/00097239/)\]

## Contact 
Email : aom at sfc.wide.ad.jp
