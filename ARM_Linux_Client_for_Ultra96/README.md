### ARM Linux Client for Ultra96

In this directory you can find essential files for interfacing with the softcore in a Linix environment.

Tested on Ultra96, running the official Linux distribution from Avnet (tested for Ultra96v1 running Petalinux 2018.2).

#### Before starting, first make sure that:

- The device tree of the device is appropriately patched to split the 2GB memory into a 1GB kernel space (0x00000000 - 0x3fffffff) and 1G uncached region for the RISC-V softcore (0x40000000-0x7fffffff). This can be done by adding `mem=1G` to the kernel boot parameters or adding the following entry to the device tree:

		reserved-memory {
			#address-cells = < 0x02 >;
			#size-cells = < 0x02 >;
			ranges;

			rproc@3ed000000 {
				no-map;
				reg = < 0x00 0x3ed00000 0x00 0x1000000 >;
			};
			
		   // from https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18841683/Linux+Reserved+Memory
		   reserved: buffer@0 {
			  no-map;
			  reg = <0x0 0x40000000 0x0 0x40000000>;
		   };
		};

- The tool `devmem` or [equivalent](https://github.com/pavel-a/devmemX) is properly installed and is included in the PATH as devmem (existed by default on the tested official Ultra96 image)

- The Xilinx [FPGA Manager](https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18841645/Solution+Zynq+PL+Programming+With+FPGA+Manager) facility is enabled in the kernel (existed by default on the tested official Ultra96 image). This allows flashing any FPGA bitstream within the Linux environment without rebooting.

#### This directory contains the following files:

- `loadbin.c` This file, compiles with `gcc -O3 loadbin.c -o loadbin` and copies the RISC-V binary file called `firmware.bin` to the non-kernel memory address 0x40010074

- `readmem.py` This is a python2 script that reads the first 3000 characters written by the RISC-V softcore at address 0x47000000. After a compatible binary was executed (with the appropriate syscall.c pointing to this physical address, as in all benchmarks in the `Benchmarks` directory). It can be called with `python readmem.py` from Ultra96's Linux.

#### Example steps to load a bitsream, RISC-V binary and read the program's output

1. Load the bitstream containing the RISC-V softcore
```
	root@Ultra96:~# echo Bitstream.bin> /sys/class/fpga_manager/fpga0/firmware; dmesg|grep FPGA|tail -1
	[  115.128176] fpga_manager fpga0: writing Bitstream.bin to Xilinx ZynqMP FPGA Manager
	root@Ultra96:~#
```
2. Adjust its operating frequency to 150 MHz (1500/(1*10))
```
	root@Ultra96:~# devmem 0XFF5E00C0 w 0x01010A00
	root@Ultra96:~#
```	
3. Load the binary of Dhrystone benchmark
```
	root@Ultra96:~# ./loadbin 
	File size is 23608
	root@Ultra96:~#
```
4. Set the start address directly to the softcore and set the reset flag to 0 for the execution to start
```
	root@Ultra96:~# devmem 0x90000004 w 0x0001099c
	root@Ultra96:~# devmem 0x90000000 w 0         
	root@Ultra96:~# 
```	
5. When the PC value is at the ending PC (`exit()` is implemented as an endless loop), make a read at 0x90000010 to initiate the `flush-writes` command for all dirty blocks to propagate to main memory.
```
	root@Ultra96:~# devmem 0x90000000 
	0x0001156C
	root@Ultra96:~# devmem 0x90000010 
```	
6. Finally, read the standard output using the provided python file 
```
	root@Ultra96:~# python readmem.py 

	Dhrystone Benchmark, Version 2.1 (Language: C)

	Program compiled without 'register' attribute

	Execution starts, 20000000 runs through Dhrystone
	Execution ends

	Final values of the variables used in the benchmark:

	Int_Glob:            5
		    should be:   5
	Bool_Glob:           1
		    should be:   1
	Ch_1_Glob:           A
		    should be:   A
	Ch_2_Glob:           B
		    should be:   B
	Arr_1_Glob[8]:       7
		    should be:   7
	Arr_2_Glob[8][7]:    20000010
		    should be:   Number_Of_Runs + 10
	Ptr_Glob->
	  Ptr_Comp:          8
		    should be:   (implementation-dependent)
	  Discr:             0
		    should be:   0
	  Enum_Comp:         2
		    should be:   2
	  Int_Comp:          17
		    should be:   17
	  Str_Comp:          DHRYSTONE PROGRAM, SOME STRING
		    should be:   DHRYSTONE PROGRAM, SOME STRING
	Next_Ptr_Glob->
	  Ptr_Comp:          8
		    should be:   (implementation-dependent), same as above
	  Discr:             0
		    should be:   0
	  Enum_Comp:         1
		    should be:   1
	  Int_Comp:          18
		    should be:   18
	  Str_Comp:          DHRYSTONE PROGRAM, SOME STRING
		    should be:   DHRYSTONE PROGRAM, SOME STRING
	Int_1_Loc:           5
		    should be:   5
	Int_2_Loc:           13
		    should be:   13
	Int_3_Loc:           7
		    should be:   7
	Enum_Loc:            1
		    should be:   1
	Str_1_Loc:           DHRYSTONE PROGRAM, 1'ST STRING
		    should be:   DHRYSTONE PROGRAM, 1'ST STRING
	Str_2_Loc:           DHRYSTONE PROGRAM, 2'ND STRING
		    should be:   DHRYSTONE PROGRAM, 2'ND STRING

	Number_Of_Runs: 20000000
	User_Time: 7760000183 cycles, 5300000036 insn
	
	root@Ultra96:~#
```

