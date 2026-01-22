RISCV_PREFIX ?= $(HOME)/riscv/toolchain/bin/riscv32-unknown-elf
CC      := $(if $(wildcard $(RISCV_PREFIX)-gcc),$(RISCV_PREFIX)-gcc,riscv32-unknown-elf-gcc)
OBJDUMP := $(patsubst %gcc,%objdump,$(CC))
OBJCOPY := $(patsubst %gcc,%objcopy,$(CC))

CFLAGS  := -Iinclude -Os -march=rv32im -mabi=ilp32 -ffreestanding -nostdlib -Wall
LDFLAGS := -Tsections.lds -nostdlib -lgcc

SRC_DIR     := src
BUILD_DIR   := build
SCRIPT_DIR  := scripts

TARGET_NAME := knn
TARGET      := $(BUILD_DIR)/$(TARGET_NAME)

C_SRCS   := $(wildcard $(SRC_DIR)/*.c)
ASM_SRCS := $(wildcard $(SRC_DIR)/*.S)

OBJS := \
	$(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(C_SRCS)) \
	$(patsubst $(SRC_DIR)/%.S,$(BUILD_DIR)/%.o,$(ASM_SRCS))

# Default target
all: $(TARGET).elf $(TARGET).dis $(TARGET).bin $(TARGET).hex $(TARGET).coe

# Ensure build folder exists
$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.S | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(TARGET).elf: $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

# Output binaries
%.dis: %.elf
	$(OBJDUMP) -d $< > $@

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@

%.hex: %.bin $(SCRIPT_DIR)/makehex.py
	python3 $(SCRIPT_DIR)/makehex.py $< > $@

%.coe: %.bin
	@echo "memory_initialization_radix=16;" > $@
	@echo "memory_initialization_vector=" >> $@
	@hexdump -v -e '1/1 "%02x\n"' $< | \
	awk '{bytes[NR-1]=$$0} \
	     END { for(i=0;i<NR;i+=4) \
	     { printf "%s%s%s%s", bytes[i+3], bytes[i+2], bytes[i+1], bytes[i]; \
	       if(i+4<NR) printf(",\n"); else printf(";\n"); }}' >> $@

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean
