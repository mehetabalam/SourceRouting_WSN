COMPONENT=AppC
TINYOS_ROOT_DIR?=/home/user/tinyos

# max payload size, may grow up to 90 (circa)
CFLAGS += -DTOSH_DATA_LENGTH=28
# radio frequency channel from 11 to 26
CFLAGS += -DCC2420_DEF_CHANNEL=26
# transmission power from 1 to 31
CFLAGS += -DCC2420_DEF_RFPOWER=31

# include the low power listening component
CFLAGS += -DLOW_POWER_LISTENING

# wake-up interval
CFLAGS += -DLPL_DEF_REMOTE_WAKEUP=256
#CFLAGS += -DLPL_DEF_REMOTE_WAKEUP=0 # 0 means no LPL

CFLAGS += -DDELAY_AFTER_RECEIVE=10

# include the packet link (acknowledgements) component
CFLAGS += -DPACKET_LINK
CFLAGS += -DCC2420_HW_ACKNOWLEDGEMENTS 
CFLAGS += -DCC2420_HW_ADDRESS_RECOGNITION

CFLAGS += -I$(TINYOS_ROOT_DIR)/tos/lib/printf
CFLAGS += -DNEW_PRINTF_SEMANTICS

# for CTP
CFLAGS += -I$(TINYOS_ROOT_DIR)/tos/lib/net \
          -I$(TINYOS_ROOT_DIR)/tos/lib/net/le \
          -I$(TINYOS_ROOT_DIR)/tos/lib/net/ctp

include $(TINYOS_ROOT_DIR)/Makefile.include
