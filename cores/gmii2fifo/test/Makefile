SOURCES=$(wildcard *.v) \
	$(wildcard ../rtl/gmii_rec.v) 

#all: cversim
all: phy_rx.hex isim

gtk: all
	gtkwave test.vcd

isim: tb_system
	./tb_system

cversim: $(SOURCES)
	cver $(SOURCES)

clean:
	rm -f tb_system verilog.log test.vcd phy_rx.hex

phy_rx.hex: make_data
	./make_data >phy_rx.hex

tb_system: $(SOURCES)
	iverilog -o tb_system $(SOURCES)

.PHONY: clean isim cversim gtk
