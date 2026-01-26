#!/usr/bin/env python3
"""
Convert binary file to Verilog register initialization file
Usage: python bin2verilog.py <input.bin> [output.v] [module_name]
"""

import sys

def bin2verilog(input_file, output_file, module_name="bootrom_mem"):
    """
    Convert binary file to Verilog module with initialized memory
    
    Args:
        input_file: Path to input binary file
        output_file: Path to output .v file
        module_name: Name of the Verilog module (default: bootrom_mem)
    """
    with open(input_file, "rb") as f:
        bindata = f.read()
    
    # Pad to 4-byte alignment if needed
    padding_needed = (4 - (len(bindata) % 4)) % 4
    if padding_needed:
        bindata += b'\x00' * padding_needed
        print(f"Padded {padding_needed} bytes to align to 4-byte boundary")
    
    # Convert to 32-bit words
    num_words = len(bindata) // 4
    words = []
    for i in range(num_words):
        word_bytes = bindata[i*4 : i*4+4]
        # Little-endian: byte0 is LSB
        word = (word_bytes[3] << 24) | (word_bytes[2] << 16) | (word_bytes[1] << 8) | word_bytes[0]
        words.append(word)
    
    with open(output_file, "w") as f:
        # Write module header
        f.write(f"// Bootrom memory initialization\n")
        f.write(f"// Generated from: {input_file}\n")
        f.write(f"// Size: {len(bindata)} bytes ({num_words} words)\n\n")
        
        f.write(f"module {module_name} (\n")
        f.write(f"    input wire clk,\n")
        f.write(f"    input wire [31:0] addr,\n")
        f.write(f"    output reg [31:0] data_out\n")
        f.write(f");\n\n")
        
        # Declare memory array
        f.write(f"    // Memory array: {num_words} words of 32 bits\n")
        f.write(f"    reg [31:0] memory [0:{num_words-1}];\n\n")
        
        # Initialize memory
        f.write(f"    // Memory initialization\n")
        f.write(f"    initial begin\n")
        
        for i, word in enumerate(words):
            f.write(f"        memory[{i}] = 32'h{word:08x};\n")
        
        f.write(f"    end\n\n")
        
        # Read logic
        f.write(f"    // Read logic\n")
        f.write(f"    always @(posedge clk) begin\n")
        f.write(f"        // Word-aligned address (divide by 4)\n")
        f.write(f"        data_out <= memory[addr[31:2]];\n")
        f.write(f"    end\n\n")
        
        f.write(f"endmodule\n")
    
    print(f"Converted {input_file} to {output_file}")
    print(f"Module name: {module_name}")
    print(f"Memory size: {num_words} words ({len(bindata)} bytes)")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python bin2verilog.py <input.bin> [output.v] [module_name]", file=sys.stderr)
        print("\nExamples:", file=sys.stderr)
        print("  python bin2verilog.py bootrom.bin                    # output: bootrom.v, module: bootrom_mem", file=sys.stderr)
        print("  python bin2verilog.py bootrom.bin bootrom_init.v     # custom output name", file=sys.stderr)
        print("  python bin2verilog.py bootrom.bin bootrom.v my_rom   # custom module name", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    
    # Default output filename: replace extension with .v
    if len(sys.argv) > 2:
        output_file = sys.argv[2]
    else:
        output_file = input_file.rsplit('.', 1)[0] + '.v'
    
    # Module name
    if len(sys.argv) > 3:
        module_name = sys.argv[3]
    else:
        module_name = "bootrom_mem"
    
    bin2verilog(input_file, output_file, module_name)
