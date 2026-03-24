# =============================================================================
# RISC-V Assembly Driver for Spansion S25FL128S Flash
# Controller: Xilinx AXI Quad SPI IP (in Full Quad I/O Mode)
# =============================================================================

# v1.1 mappings
# .equ SRAM_BASE,            0x06000000
# .equ SPI_BASE,             0x01000000
# .equ UART_BASE,            0x03000000
# .equ GPIO_BASE,            0x05000000

# v0.1 mappings
.equ SRAM_BASE,            0x4000
.equ SPI_BASE,             0x20000000
.equ UART_BASE,            0x20020000
.equ GPIO_BASE,            0x05000000

.equ UART_TX_OFFSET,       0x4
.equ SPI_SR_OFFSET,        0x64
.equ SPI_TX_FIFO_OFFSET,   0x68
.equ SPI_RX_FIFO_OFFSET,   0x6C
.equ SPI_SSR_OFFSET,       0x70

.equ TX_EMPTY_MASK,        0x4
.equ RX_NOT_EMPTY_MASK,    0x1
.equ WIP_BIT_MASK,         0x1
.equ FLASH_ADDR_TO_READ,   0x0

# --- Firmware load parameters ---
.equ FW_FLASH_OFFSET,   0x00000000   # flash offset where .mem starts
.equ FW_MAGIC_WORD,     0xB007B007
.equ FW_HEADER_WORDS, 4
.equ FW_HEADER_BYTES, 16


.text
.global main

main:
    li   s0, SRAM_BASE    # BRAM base
    li   s1, SPI_BASE    # SPI base
    li   s2, UART_BASE    # UART base

    # NEW: GPIO base
    li   t6, GPIO_BASE    # GPIO register

    # --- GPIO INIT (DIRECTION SET) ---
    # AXI GPIO offset 0x4 = direction register
    # 0 = OUTPUT, 1 = INPUT
    li   t0, 0x0
    sw   t0, 4(t6)

.ifdef FLASH_PATH
    # --- SPI Init ---
    li   t0, 0x1E6
    sw   t0, 0x60(s1)
    li   t0, 0x13C
    sw   t0, 0x60(s1)
    li   t0, 0x086
    sw   t0, 0x60(s1)
.endif

####################### --- BRAM TEST ---
    li   t0, 10
    sw   t0, 0(s0)
    li   t0, 20
    sw   t0, 4(s0)

    lw   t1, 0(s0)
    sw   t1, UART_TX_OFFSET(s2)

    li   t0, 5
delay1:
    addi t0, t0, -1
    bnez t0, delay1

    lw   t1, 4(s0)
    sw   t1, UART_TX_OFFSET(s2)

    li   t0, 5
delay2:
    addi t0, t0, -1
    bnez t0, delay2

####################### --- GPIO STATUS: BRAM DONE (0x01) ---
    li   t0, 0x01
    sw   t0, 0(t6)

.ifdef FLASH_PATH
####################### --- WREN ---
    li   t0, -2
    sw   t0, SPI_SSR_OFFSET(s1)
wren_tx_wait:
    lw   t0, SPI_RX_FIFO_OFFSET(s1)
    lw   t0, SPI_SR_OFFSET(s1)
    andi t0, t0, TX_EMPTY_MASK
    beq  t0, zero, wren_tx_wait
    li   t0, 0x06
    sw   t0, SPI_TX_FIFO_OFFSET(s1)

#loop allows write to flash
wren_end_wait:
    lw   t0, SPI_SR_OFFSET(s1)
    andi t0, t0, TX_EMPTY_MASK
    beq  t0, zero, wren_end_wait
    li   t0, -1
    sw   t0, SPI_SSR_OFFSET(s1)

    # --- WRR (set QE bit) ---
    li   t0, -2
    sw   t0, SPI_SSR_OFFSET(s1)
wrr_tx_wait_1:
    lw   t0, SPI_SR_OFFSET(s1)
    andi t0, t0, TX_EMPTY_MASK
    beq  t0, zero, wrr_tx_wait_1
    li   t0, 0x01
    sw   t0, SPI_TX_FIFO_OFFSET(s1)

wrr_tx_wait_2:
    lw   t0, SPI_SR_OFFSET(s1)
    andi t0, t0, TX_EMPTY_MASK
    beq  t0, zero, wrr_tx_wait_2
    sw   zero, SPI_TX_FIFO_OFFSET(s1)

wrr_tx_wait_3:
    lw   t0, SPI_SR_OFFSET(s1)
    andi t0, t0, TX_EMPTY_MASK
    beq  t0, zero, wrr_tx_wait_3

    li   t0, 0xC2
    sw   t0, SPI_TX_FIFO_OFFSET(s1)

wrr_end_wait:
    lw   t0, SPI_SR_OFFSET(s1)
    andi t0, t0, TX_EMPTY_MASK
    beq  t0, zero, wrr_end_wait
    li   t0, -1
    sw   t0, SPI_SSR_OFFSET(s1)

###################### --- GPIO STATUS: SPI + QE DONE (0x03) ---
    li   t0, 0x03
    sw   t0, 0(t6)

###################### --- WIP poll loop ---
wip_poll_loop:
    li   t0, 0X0C6
    sw   t0, 0x60(s1)
    li   t0, -2
    sw   t0, SPI_SSR_OFFSET(s1)

wip_tx_wait_1:
    lw   t0, SPI_SR_OFFSET(s1)
    andi t0, t0, TX_EMPTY_MASK
    beq  t0, zero, wip_tx_wait_1

    li   t0, 0x05
    sw   t0, SPI_TX_FIFO_OFFSET(s1)

wrr_end_wait_rdsr:
    lw   t0, SPI_SR_OFFSET(s1)
    andi t0, t0, TX_EMPTY_MASK
    beq  t0, zero, wrr_end_wait_rdsr

    sw   zero, SPI_TX_FIFO_OFFSET(s1)

wrr_end_wait_dummy:
    lw   t0, SPI_SR_OFFSET(s1)
    andi t0, t0, TX_EMPTY_MASK
    beq  t0, zero, wrr_end_wait_dummy

    li   t0, -1
    sw   t0, SPI_SSR_OFFSET(s1)
    li   t0, 0x186
    sw   t0, 0x60(s1)

    lw   t1, SPI_RX_FIFO_OFFSET(s1)
    lw   t1, SPI_RX_FIFO_OFFSET(s1)
    andi t1, t1, WIP_BIT_MASK
    bnez t1, wip_poll_loop

# --- UART TX delay ---
uart_tx_full:
    lw   t2, 0x8(s2)
    andi t2, t2, TX_EMPTY_MASK
    beq  t2, zero, uart_tx_full
    sw   zero, UART_TX_OFFSET(s2)
    sw   zero, UART_TX_OFFSET(s2)

##################### --- GPIO STATUS: UART DONE (0x02) ---
    li   t0, 0x02
    sw   t0, 0(t6)

##################### --- QIO Read : FLASH -> BRAM ---
    li   s3, 0x03
    sw   s3, 0xc(s2)
    li   s3, FW_FLASH_OFFSET   # flash read start address
    li   s4, FW_HEADER_WORDS     # number of 32-bit words to read
    mv   s5, s0                  # store header at BRAM base
    li   s6, 0			#payload flag

    li   t0, 0xFE
    sw   t0, UART_TX_OFFSET(s2) # Send 0xFE to UART to indicate QIO read start
    
qio_read_start:
    jal  ra, drain_rx_fifo

    li   t0, 0x1E6
    sw   t0, 0x60(s1)

qio_tx_wait_1:
    lw   t0, SPI_SR_OFFSET(s1)
    andi t0, t0, TX_EMPTY_MASK
    beq  t0, zero, qio_tx_wait_1
    li   t0, 0x6B
    sw   t0, SPI_TX_FIFO_OFFSET(s1)

# send address
qio_tx_addr_1:
    lw   t0, SPI_SR_OFFSET(s1)
    andi t0, t0, 0x8
    bnez t0, qio_tx_addr_1
    srli t0, s3, 16
    sw   t0, SPI_TX_FIFO_OFFSET(s1)

qio_tx_addr_2:
    lw   t0, SPI_SR_OFFSET(s1)
    andi t0, t0, 0x8
    bnez t0, qio_tx_addr_2
    srli t0, s3, 8
    sw   t0, SPI_TX_FIFO_OFFSET(s1)

qio_tx_addr_3:
    lw   t0, SPI_SR_OFFSET(s1)
    andi t0, t0, 0x8
    bnez t0, qio_tx_addr_3
    sw   s3, SPI_TX_FIFO_OFFSET(s1)

qio_tx_dummy:
    lw   t0, SPI_SR_OFFSET(s1)
    andi t0, t0, 0x8
    bnez t0, qio_tx_dummy
    sw   zero, SPI_TX_FIFO_OFFSET(s1)

qio_tx_dummy_wait:
    lw   t0, SPI_SR_OFFSET(s1)
    andi t0, t0, 0x8
    bnez t0, qio_tx_dummy_wait
    sw   zero, SPI_TX_FIFO_OFFSET(s1) 					# zero[7:0]

qio_tx_dummy_wait3:
    lw   t0, SPI_SR_OFFSET(s1)
    andi t0, t0, 0x8
    bnez t0, qio_tx_dummy_wait3
    sw   zero, SPI_TX_FIFO_OFFSET(s1) 					# zero[7:0]

qio_tx_dummy_wait4:
    lw   t0, SPI_SR_OFFSET(s1)
    andi t0, t0, 0x8
    bnez t0, qio_tx_dummy_wait4
    sw   zero, SPI_TX_FIFO_OFFSET(s1) 					# zero[7:0]


    li   t0, -2
    sw   t0, SPI_SSR_OFFSET(s1) 						# Assert CS


    #disable master inhibit
    li   t0, 0x086
    sw   t0, 0x60(s1)

wait_tx_empty:
     lw   t0, SPI_SR_OFFSET(s1)
     andi t0, t0, TX_EMPTY_MASK
     beq  t0, zero, wait_tx_empty

     lw   t1, SPI_RX_FIFO_OFFSET(s1)
     lw   t1, SPI_RX_FIFO_OFFSET(s1)
     lw   t1, SPI_RX_FIFO_OFFSET(s1)
     lw   t1, SPI_RX_FIFO_OFFSET(s1)

    li   x13, 0
    lw   t1, SPI_RX_FIFO_OFFSET(s1) 						# Read data word
    slli x13,t1,0

    lw   t1, SPI_RX_FIFO_OFFSET(s1) 						# Read data word
    slli t1,t1,8
    add  x13,x13,t1

    lw   t1, SPI_RX_FIFO_OFFSET(s1) 						# Read data word
    slli t1,t1,16
    add  x13,x13,t1

    lw   t1, SPI_RX_FIFO_OFFSET(s1) 						# Read data word
    slli t1,t1,24
    add  x13,x13,t1

    sw   x13, 0(s5)          					# Store data to BRAM
    addi s5,s5,4
    addi s4,s4,-1

############################################# --- Read Burst Loop (for s4=4 words) ---
read_burst_loop:
    li   x7,4
    beq  s4, zero, read_burst_end # If count is 0, we're done


tx_dummy_for_read:
    lw   t0, SPI_SR_OFFSET(s1)
    andi t0, t0, TX_EMPTY_MASK       				# Poll Tx_Full changed to tx empty
#   andi  t0, t0, 0x8
#   bnez  t0, tx_dummy_for_read                         # Loop if full
    beqz  t0, tx_dummy_for_read
    sw    zero, SPI_TX_FIFO_OFFSET(s1)  				# Write dummy byte
    addi  x7,x7,-1
    bnez  x7,tx_dummy_for_read

qio_rx_wait:
    lw   t0, SPI_SR_OFFSET(s1)
    andi t0, t0, TX_EMPTY_MASK
    beq  t0, zero, qio_rx_wait # Wait for RX FIFO

# check for the data transmission between flash and controller
# dummy
################# --- 2. POLL FOR RX DATA ---

qio_rx_wait_:
    lw   t0, SPI_SR_OFFSET(s1)
    andi t0, t0, RX_NOT_EMPTY_MASK        				# ** BUG FIX: Poll Rx_Empty (0x1) **
    bnez t0, qio_rx_wait_    				# Loop if Rx_Empty is 1 (EMPTY)

    li   x13, 0
    lw   t1, SPI_RX_FIFO_OFFSET(s1) 					# Read data word
    slli x13,t1,0

    lw   t1, SPI_RX_FIFO_OFFSET(s1) # Read data word
    slli t1,t1,8
    add  x13,x13,t1

    lw   t1, SPI_RX_FIFO_OFFSET(s1) # Read data word
    slli t1,t1,16
    add  x13,x13,t1

    lw   t1, SPI_RX_FIFO_OFFSET(s1) # Read data word
    slli t1,t1,24
    add  x13,x13,t1


    sw   x13, 0(s5)          # Store data to BRAM
    addi s5, s5, 4          # Increment BRAM pointer
    addi s4, s4, -1         # Decrement word counter
    j    read_burst_loop

read_burst_end:
    li   t0, -1
    sw   t0, SPI_SSR_OFFSET(s1) # De-assert CS

    jal  ra, drain_rx_fifo

    beqz s6, parse_header
    j firmware_done

######################################################## --- PARSE FIRMWARE HEADER (now in BRAM)
parse_header:
    lw   t0, 0(s0)              # magic
    li   t1, FW_MAGIC_WORD
    bne  t0, t1, done           # halt if magic mismatch

    lw   t2, 4(s0)              # firmware size (bytes)
    lw   t3, 8(s0)              # load address
    lw   t4, 12(s0)             # entry point

    srli t2, t2, 2              # bytes -> words
    mv   s4, t2                 # number of words to read
    mv   s5, t3                 # destination address in BRAM
    addi s3, s3, FW_HEADER_BYTES # advance flash offset to payload
    li   s6, 1			#flag set to knn
    j    qio_read_start


######################################################## --- GPIO STATUS: FLASH BURST READ DONE (0x04) ---
firmware_done:
    li   t0, 0x04
    sw   t0, 0(t6)

    li   t0, 0xFF
    sw   t0, UART_TX_OFFSET(s2) # Send 0xFF to UART to indicate firmware load done

    li   t0, SRAM_BASE
    jr   t0

done:
    j done

.else
################## --- UART_PATH: Bootrom tests complete, jump to firmware at SRAM_BASE ---
    li   t0, 0xFF
    sw   t0, UART_TX_OFFSET(s2) # Send 0xFF to UART to indicate bootrom done

    # end of bootrom, firmware should start right after here
.endif
######################################################## --- Halt catchall

.ifdef FLASH_PATH
# --------------------------------------------------
# Drain RX FIFO completely
# --------------------------------------------------
drain_rx_fifo:
    lw   t0, SPI_SR_OFFSET(s1)
    andi t0, t0, RX_NOT_EMPTY_MASK  # RX_EMPTY?
    bnez t0, drain_rx_done
    lw   t1, SPI_RX_FIFO_OFFSET(s1) # pop + discard
    j    drain_rx_fifo
drain_rx_done:
    ret
.endif
