#!/bin/bash
export TOOL_DIR=/opt/riscv32im2/

make clean
make

$TOOL_DIR/bin/riscv32-unknown-elf-objcopy -O binary dhrystone  dhrystone.bin 
$TOOL_DIR/bin/riscv32-unknown-elf-objdump -s -t -r -d -f --source dhrystone > objdump.txt

cat objdump.txt | grep "start address" 
rm dhrystone
