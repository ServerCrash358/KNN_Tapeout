#!/usr/bin/env python3
"""
Convert binary file to Vivado-friendly MEMH format.

Format example (16 bytes per line):
02 05 ff 03 01 02 03 04 09 08 07 06 05 12 10 ff

Usage:
  python3 bin2memh.py <input.bin> [output.memh] [total_bytes] [fill_byte] [bytes_per_line]

Arguments:
  input.bin       Input binary file
  output.memh     Output file path (default: input with .memh extension)
  total_bytes     Optional padded output size in bytes (dec or 0x...)
  fill_byte       Optional padding byte value (dec or 0x..., default: 0xff)
  bytes_per_line  Optional bytes per line (default: 16)
"""

import sys


def parse_int(value: str) -> int:
    value = value.strip()
    if value.lower().startswith("0x"):
        return int(value, 16)
    return int(value, 10)


def bin2memh(input_file: str, output_file: str, total_bytes=None, fill_byte=0xFF, bytes_per_line=16):
    with open(input_file, "rb") as f:
        data = bytearray(f.read())

    if total_bytes is not None:
        if total_bytes < len(data):
            raise ValueError(
                f"total_bytes ({total_bytes}) is smaller than input size ({len(data)})."
            )
        data.extend([fill_byte] * (total_bytes - len(data)))

    with open(output_file, "w") as f:
        for i in range(0, len(data), bytes_per_line):
            chunk = data[i:i + bytes_per_line]
            f.write(" ".join(f"{b:02x}" for b in chunk) + "\n")

    print(f"Converted {input_file} to {output_file}")
    print(f"Input size: {len(open(input_file, 'rb').read())} bytes")
    print(f"Output size: {len(data)} bytes")
    print(f"Bytes/line: {bytes_per_line}")
    if total_bytes is not None:
        print(f"Padded with 0x{fill_byte:02x} to {total_bytes} bytes")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(
            "Usage: python3 bin2memh.py <input.bin> [output.memh] [total_bytes] [fill_byte] [bytes_per_line]",
            file=sys.stderr,
        )
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else input_file.rsplit('.', 1)[0] + '.memh'

    total_bytes = parse_int(sys.argv[3]) if len(sys.argv) > 3 else None
    fill_byte = parse_int(sys.argv[4]) if len(sys.argv) > 4 else 0xFF
    bytes_per_line = parse_int(sys.argv[5]) if len(sys.argv) > 5 else 16

    if not (0 <= fill_byte <= 0xFF):
        print("Error: fill_byte must be in range 0..255", file=sys.stderr)
        sys.exit(1)
    if bytes_per_line <= 0:
        print("Error: bytes_per_line must be > 0", file=sys.stderr)
        sys.exit(1)

    try:
        bin2memh(input_file, output_file, total_bytes, fill_byte, bytes_per_line)
    except Exception as exc:
        print(f"Error: {exc}", file=sys.stderr)
        sys.exit(1)
