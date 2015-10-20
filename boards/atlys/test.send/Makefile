SRC =  tb_dvi_demo.v  ../../../core/gmii_tx/rtl/gmii_tx.v ../../../core/timing/rtl/tmds_timing.v ../../../core/crc/crc_gen.v ../../../core/fifo/test/afifo48.v ../../../core/fifo/test/asfifo.v ../../../core/fifo/test/graycounter.v

tb_system: $(SRC)
	iverilog -o tb_system $(SRC)

clean: 
	rm -f tb_system verilog.log test.vcd

.PHONY: clean isim wave
