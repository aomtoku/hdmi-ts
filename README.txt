HDMI Transport Stream over IP
-----------------------------
[> Directory Structure
 /cores/      Cores library, with Verilog sources, test benches and documentation.
 /boards/     Top-level design files, constraint files and Makefiles
              for supported FPGA boards.
 /doc/        Documentation.
 /software/   Software.


[> Building tools
You will need:
 - Xilinx ISE 14.6

[> How to build
1- cd boards/atlys/synthesis
2- make

[> Quickstart
1- connect serial and JTAG cables
2- cd boards/atlys/synthesis
3- make load

aom@sfc.wide.ad.jp
