# Include project configuration
include ../config.mk

CC      := $(if $(wildcard $(RISCV_PREFIX)-gcc),$(RISCV_PREFIX)-gcc,riscv32-unknown-elf-gcc)
OBJDUMP := $(patsubst %gcc,%objdump,$(CC))
OBJCOPY := $(patsubst %gcc,%objcopy,$(CC))

SRC_DIR     := src
BUILD_DIR   := build
SCRIPT_DIR  := ../scripts

CFLAGS  := $(OPT_LEVEL) -march=$(ARCH) -mabi=$(ABI) $(EXTRA_CFLAGS)
LDFLAGS := -T$(BUILD_DIR)/bootrom.lds -nostdlib -lgcc

# Linker script preprocessor flags
LD_DEFINES := -DBOOTROM_START_ADDR=$(BOOTROM_START_ADDR) \
              -DBOOTROM_SIZE=$(BOOTROM_SIZE)


TARGET_NAME := bootrom
TARGET      := $(BUILD_DIR)/$(TARGET_NAME)

C_SRCS   := $(wildcard $(SRC_DIR)/*.c)
ASM_SRCS := $(wildcard $(SRC_DIR)/*.S)

OBJS := \
	$(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(C_SRCS)) \
	$(patsubst $(SRC_DIR)/%.S,$(BUILD_DIR)/%.o,$(ASM_SRCS))

# Default target
all: $(TARGET).elf $(TARGET).dis $(TARGET).bin $(TARGET).hex $(TARGET).coe $(TARGET).mem $(TARGET).v

# Test binaries
TEST_DIR   := tests
TEST_SRCS := $(wildcard $(TEST_DIR)/*.S)
TEST_ELF_TARGETS = $(patsubst $(TEST_DIR)/%.S,$(BUILD_DIR)/%_test.elf,$(TEST_SRCS))
TEST_COE_TARGETS = $(patsubst $(TEST_DIR)/%.S,$(BUILD_DIR)/%_test.coe,$(TEST_SRCS))
TEST_BIN_TARGETS = $(patsubst $(TEST_DIR)/%.S,$(BUILD_DIR)/%_test.bin,$(TEST_SRCS))
TEST_HEX_TARGETS = $(patsubst $(TEST_DIR)/%.S,$(BUILD_DIR)/%_test.hex,$(TEST_SRCS))
TEST_DIS_TARGETS = $(patsubst $(TEST_DIR)/%.S,$(BUILD_DIR)/%_test.dis,$(TEST_SRCS))

tests: $(TEST_COE_TARGETS) $(TEST_HEX_TARGETS) $(TEST_DIS_TARGETS)

$(BUILD_DIR)/%_test.elf: $(TEST_DIR)/%.S $(BUILD_DIR)/bootrom.lds
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

clean-tests:
	rm -f $(TEST_ELF_TARGETS) $(TEST_COE_TARGETS) $(TEST_BIN_TARGETS) $(TEST_HEX_TARGETS) $(TEST_DIS_TARGETS)

# Ensure build folder exists
$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c ../config.mk | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.S ../config.mk | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Preprocess linker script
$(BUILD_DIR)/bootrom.lds: bootrom.lds ../config.mk | $(BUILD_DIR)
	$(CC) -E -P -x c $(LD_DEFINES) $< -o $@

$(TARGET).elf: $(OBJS) $(BUILD_DIR)/bootrom.lds
	$(CC) $(CFLAGS) -o $@ $(OBJS) $(LDFLAGS)

# Output binaries
%.dis: %.elf
	$(OBJDUMP) -d $< > $@

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@

%.hex: %.bin $(SCRIPT_DIR)/makehex.py
	python3 $(SCRIPT_DIR)/makehex.py $< > $@

%.coe: %.bin $(SCRIPT_DIR)/bin2coe.py
	python3 $(SCRIPT_DIR)/bin2coe.py $< $@

%.mem: %.bin $(SCRIPT_DIR)/bin2mem.py
	python3 $(SCRIPT_DIR)/bin2mem.py $< $@ $(BOOTROM_START_ADDR)

%.v: %.bin $(SCRIPT_DIR)/bin2verilog.py
	python3 $(SCRIPT_DIR)/bin2verilog.py $< $@ bootrom_mem

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean
