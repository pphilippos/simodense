### Verilog RTL and simulations

List of files with description:
- `testbench.v` The testbench code in Verilog. Only used for simulation.
- `system.v` A wrapper that mainly connects the core and the cache hierarchy.
- `cpu.v` Contains the main core.
- `caches.v` The IL1, DL1 and LLC caches and their parameters
- `custom.v` The placeholder for custom instructions. Already contains merge, sort and prefix sum instructions.
- `run.sh` A short bash script that runs the simulation with Icarus Verilog (runs with `bash run.sh`)
- `firmware.bin` Example binary (see below)

#### First run

By running the provided bash script on the provided binary we get the following output. The example binary is testing the SIMD sort functionality with small input. 

```
SIMDsort N 16 cyc 41 icount 22 CPI 1.86 MB/s@150MHz 234.14 qsort_cyc 1777 sp 43.34 End0!
SIMDsort N 32 cyc 283 icount 111 CPI 2.54 MB/s@150MHz 67.84 qsort_cyc 4343 sp 15.34 End0!
SIMDsort N 64 cyc 491 icount 302 CPI 1.62 MB/s@150MHz 78.20 qsort_cyc 9933 sp 20.23 End0!
SIMDsort N 128 cyc 1355 icount 891 CPI 1.52 MB/s@150MHz 56.67 qsort_cyc 21638 sp 15.96 End0!
SIMDsort N 256 cyc 2809 icount 2042 CPI 1.37 MB/s@150MHz 54.68 qsort_cyc 48653 sp 17.32 End0!
SIMDsort N 512 cyc 6940 icount 5037 CPI 1.37 MB/s@150MHz 44.26 qsort_cyc 109213 sp 15.73 End0!
SIMDsort N 1024 cyc 15906 icount 10839 CPI 1.46 MB/s@150MHz 38.62 qsort_cyc 237971 sp 14.96 End0!
SIMDsort N 2048 cyc 38225 icount 25139 CPI 1.52 MB/s@150MHz 32.14 qsort_cyc 521990 sp 13.65 End0!
```
(End0 stands for validated output)

#### Changing the binary to be executed 

The `testbench.v` file can be edited accordingly, to provide a start address and path of the binary. The default lines are:

```
// Use the StartAddress to set the start address of the binary
`define StartAddress 32'h00010620

// Use BINARY to set the path of the binary for simulation
`define BINARY "firmware.bin"  
```

#### Changing the cache parameters

You can find all relevant parameters in the start of the `cache.v` file:

```
// In powers of 2 above 1
`define IL1sets 64

`define DL1sets 32
`define DL1ways 4

`define DL2sets 32
`define DL2ways 4
`define DL2block 16384 
`define DL2subblocks 32
```

#### Adding custom SIMD instructions

There is a placeholder for a single additional instruction in `custom.v` file. For adding additional instructions, there need to be small modifications in `cpu.c` as described by the inline comments.

```
`define c3_pipe_cycles 5


// Template for custom SIMD instruction

module C3_custom_SIMD_instruction (clk, reset, 
	in_v, rd, vrd1, vrd2, 
		in_data, in_vdata1, in_vdata2, 
	out_v, out_rd, out_vrd1, out_vrd2, 
		out_data, out_vdata1, out_vdata2);
	input clk, reset;
	
	input in_v;
	input [4:0] rd;
	input [2:0] vrd1, vrd2;			
	input [32-1:0] in_data;
	input [`VLEN-1:0] in_vdata1, in_vdata2;	
	
	...
	
```
