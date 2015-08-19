SRC = tb_apple_out.v ../datacontroller.v ../../gmii2fifo48/rtl/gmii_rec.v ../../fifo/test/asfifo.v ../../fifo/test/afifo48.v ../../fifo/test/graycounter.v

tb_system: $(SRC)
	iverilog -o tb_system $(SRC)

clean: 
	rm -f tb_system verilog.log test.vcd

.PHONY: clean isim wave
