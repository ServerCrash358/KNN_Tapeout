#!/usr/bin/env python3
"""
Append firmware header for bootrom loading
Usage: python append_firmware_header.py <input.bin> <output.bin> [magic] [load_addr] [entry_pc]
"""

import struct
import sys

def parse_hex_or_int(value):
    """Parse hex (0x...) or decimal integer"""
    if isinstance(value, str):
        if value.startswith('0x') or value.startswith('0X'):
            return int(value, 16)
        else:
            return int(value)
    return value

# Default values
DEFAULT_MAGIC     = 0xB007B007
DEFAULT_LOAD_ADDR = 0x00004000
DEFAULT_ENTRY_PC  = 0x00004000

if len(sys.argv) < 3:
    print("Usage: python append_firmware_header.py <input.bin> <output.bin> [magic] [load_addr] [entry_pc]", file=sys.stderr)
    print("\nExamples:", file=sys.stderr)
    print("  python append_firmware_header.py firmware.bin firmware_hdr.bin", file=sys.stderr)
    print("  python append_firmware_header.py firmware.bin firmware_hdr.bin 0xB007B007 0x4000 0x4000", file=sys.stderr)
    sys.exit(1)

input_file = sys.argv[1]
output_file = sys.argv[2]

# Parse optional parameters
MAGIC     = parse_hex_or_int(sys.argv[3]) if len(sys.argv) > 3 else DEFAULT_MAGIC
LOAD_ADDR = parse_hex_or_int(sys.argv[4]) if len(sys.argv) > 4 else DEFAULT_LOAD_ADDR
ENTRY_PC  = parse_hex_or_int(sys.argv[5]) if len(sys.argv) > 5 else DEFAULT_ENTRY_PC

with open(input_file, "rb") as f:
    payload = f.read()

SIZE = len(payload)

header = struct.pack(
    "<IIII",
    MAGIC,
    SIZE,
    LOAD_ADDR,
    ENTRY_PC
)

with open(output_file, "wb") as f:
    f.write(header)
    f.write(payload)

print(f"Created firmware with header: {output_file}")
print(f"  Magic:      0x{MAGIC:08X}")
print(f"  Size:       {SIZE} bytes")
print(f"  Load Addr:  0x{LOAD_ADDR:08X}")
print(f"  Entry PC:   0x{ENTRY_PC:08X}")