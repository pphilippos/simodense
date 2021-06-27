#!/bin/bash
export TOOL_DIR=/opt/riscv32im2/

cd coremark

make clean
make PORT_DIR=../riscv32 PERFORMANCE_RUN=1 ITERATIONS=10 compile

cd ../riscv32

$TOOL_DIR/bin/riscv32-unknown-elf-objcopy -O binary ../coremark/coremark.riscv  ../firmware.bin 
$TOOL_DIR/bin/riscv32-unknown-elf-objdump -s -t -r -d -f --source ../coremark/coremark.riscv > objdump.txt
cat objdump.txt | grep "start address"

cd ..
