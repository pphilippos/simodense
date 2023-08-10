#!/bin/bash

export TOOL_DIR=/opt/riscv32im_custom

$TOOL_DIR/bin/riscv32-unknown-elf-g++ -march=rv32im -std=gnu99 CProgram.cpp -O3 -ffreestanding -Wl,-Bstatic -o firmware.elf   -Wextra -Wshadow -Wundef -Wpointer-arith -Wcast-qual -Wcast-align -Wwrite-strings -Wredundant-decls -g -pedantic  -ffreestanding -fpermissive -D SIMODENSE

$TOOL_DIR/bin/riscv32-unknown-elf-objcopy -O binary firmware.elf  firmware.bin 
$TOOL_DIR/bin/riscv32-unknown-elf-objdump -s -t -r -d -f --source firmware.elf > objdump.txt

start_address=$(cat objdump.txt | grep "start address" | awk '{print $3}' | cut -c3-)
symbol_table=$(cat objdump.txt | grep -A1 "SYMBOL TABLE:" | tail -1 | awk '{print $1}' | cut -c3-)

# Converting values to the required format
start_address="32'h$start_address"
symbol_table="32'h$symbol_table"

# Replacing values in the target file
sed -i "s/\`define StartAddress .*/\`define StartAddress $start_address/" ../../RTL_and_simulation/testbench.v
sed -i "s/\`define SymbolTable .*/\`define SymbolTable $symbol_table/" ../../RTL_and_simulation/testbench.v

rm firmware.elf

cp firmware.bin ../../RTL_and_simulation