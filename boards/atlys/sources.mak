BOARD_SRC=$(wildcard $(BOARD_DIR)/top.v $(BOARD_DIR)/eval_top.v)

COMMON_SRC=$(wildcard $(CORES_DIR)/common/rtl/*.v)
HDMI_RX_SRC=$(wildcard $(CORES_DIR)/hdmi_rx/rtl/*.v)
HDMI_TX_SRC=$(wildcard $(CORES_DIR)/hdmi_tx/rtl/*.v)
COREGEN_SRC=$(wildcard $(CORES_DIR)/coregen/rtl/*.v)
EDID_SRC=$(wildcard $(CORES_DIR)/i2c_edid/rtl/*.v)

CORES_SRC=$(COMMON_SRC) $(COREGEN_SRC) $(HDMI_RX_SRC) $(HDMI_TX_SRC) $(EDID_SRC)
