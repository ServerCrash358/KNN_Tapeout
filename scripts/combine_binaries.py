#!/usr/bin/env python3
"""
Combine multiple binary files into a single output file.
Useful for creating UART-loadable combined images.

Usage: python combine_binaries.py [-o output.bin] input1.bin input2.bin [input3.bin ...]
"""

import sys
import argparse
import os

def combine_binaries(output_file, input_files):
    """
    Combine input binary files into a single output file.
    Files are concatenated in order.
    """
    combined_data = bytearray()
    
    for input_file in input_files:
        if not os.path.exists(input_file):
            print(f"Error: Input file not found: {input_file}", file=sys.stderr)
            sys.exit(1)
        
        with open(input_file, 'rb') as f:
            data = f.read()
            combined_data.extend(data)
            print(f"Added {input_file:40} ({len(data):8} bytes, total: {len(combined_data):8} bytes)")
    
    # Write combined output
    with open(output_file, 'wb') as f:
        f.write(combined_data)
    
    print()
    print(f"Created combined binary: {output_file}")
    print(f"Total size: {len(combined_data)} bytes")
    
    # Print component offset information
    print()
    print("Component layout:")
    offset = 0
    for input_file in input_files:
        with open(input_file, 'rb') as f:
            size = len(f.read())
            print(f"  0x{offset:08X}: {input_file} ({size} bytes)")
            offset += size

def main():
    parser = argparse.ArgumentParser(
        description='Combine multiple binary files for UART loading',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python combine_binaries.py -o combined.bin bootrom.bin firmware.bin
  python combine_binaries.py -o uart_image.bin test1.bin test2.bin firmware.bin
        """
    )
    
    parser.add_argument('-o', '--output', required=True,
                        help='Output binary file')
    parser.add_argument('inputs', nargs='+',
                        help='Input binary files to combine')
    
    args = parser.parse_args()
    
    if len(args.inputs) < 2:
        print("Error: At least 2 input files required", file=sys.stderr)
        parser.print_help()
        sys.exit(1)
    
    combine_binaries(args.output, args.inputs)

if __name__ == '__main__':
    main()
