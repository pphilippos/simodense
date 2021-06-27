#!/bin/bash
export TOOL_DIR=/opt/riscv32im2

make clean
make
/opt/riscv32im2/bin/riscv32-unknown-elf-objcopy -O binary stream_c.exe  stream.bin 
/opt/riscv32im2/bin/riscv32-unknown-elf-objdump -s -t -r -d -f --source stream_c.exe > objdump.txt

cat objdump.txt | grep "start address" 
rm stream_c.exe
