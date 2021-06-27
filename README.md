# Simodense: a RISC-V softcore for custom SIMD instructions

### Welcome to the source code repository for a RISC-V softcore optimised for exploring advanced reconfigurable SIMD instructions

The source code is divided into 4 directories. A separate README file accompanies each directory, to explain how the source code can be used to reproduce the experiments in the paper.

- ``RTL_and_simulation`` This folder contains the main code of the softcore for simulation, as well as the template and examples for custom SIMD instructions. 
- ``Benchmarks`` This directory contains the benchmarks and micro-benchmarks (sort & prefix sum) used in the evaluation section.
- ``FPGA_Implementation_AXI_peripheral`` The FPGA directory provides additional Verilog code for interfacing with the an AXI interconnect (such as for Avnet's Ultra96 with the Xilinx device ZU3EG) and the relevant information for creating a Vivado project
- ``ARM_Linux_Client_for_Ultra96`` The optional Linux (for ARM) client mainly provides C code for interfacing with the softcore in our heterogeneous platform. Having Linux and the specific board is not necessary, as AXI is a versatile protocol, at least for Xilinx boards. Though [bridges](https://github.com/ZipCPU/wb2axip) to other protocols exist as well. 

#### Setting up the environment 

- In order to run the simulations, [Icarus Verilog](http://iverilog.icarus.com/) is the main requirement for running the provided examples (tested with version 11.0 (stable) (v11_0)). For the debugging functionality through waveforms, a waveform viewer is recommended, such as [GTKWave Analyzer](http://gtkwave.sourceforge.net/) (tested on version 3.3.108).

- For software development for the softcore, we need to install the [RISC-V GNU Compiler Toolchain](https://github.com/riscv/riscv-gnu-toolchain), and modify it for supporting the custom SIMD instructions for inline assembly.

First we fetch the code using the bash command (6.65GB of data, about 10GB after compilation):

    $ git clone https://github.com/riscv/riscv-gnu-toolchain

and change directory:

    $ cd riscv-gnu-toolchain
    
Then we provide the target directory where GCC and related tools are installed. This is for bare-metal applications, based on the 32-bit "RV32I" base specification and "M" multiplication/division extension. The size of the prefix directory will become about 1.1 GB after compilation.

    $ ./configure --prefix=/opt/riscv32im_custom --with-arch=rv32im --with-abi=ilp32    

Before compiling, we need to add the support of custom instructions to binutils. In order to do that, we add the following lines to the C file `riscv-gnu-toolchain/riscv-binutils/opcodes/riscv-opc.c` inside the lengthy `const struct riscv_opcode riscv_opcodes[]` array:

	{"c0_lv",      0, INSN_CLASS_I, "d,s,t,j",   MATCH_CUSTOM0, MASK_CUSTOM0, match_opcode, 0 },
	{"c0_sv",      0, INSN_CLASS_I, "d,s,t,j",   MATCH_CUSTOM0_RS1, MASK_CUSTOM0_RS1, match_opcode, 0 },
	{"c1",      0, INSN_CLASS_I, "d,s,j",   MATCH_CUSTOM1, MASK_CUSTOM1, match_opcode, 0 },
	{"c2",      0, INSN_CLASS_I, "d,s,j",   MATCH_CUSTOM2, MASK_CUSTOM2, match_opcode, 0 },
	{"c3",      0, INSN_CLASS_I, "d,s,j",   MATCH_CUSTOM3, MASK_CUSTOM3, match_opcode, 0 },

where ``c0_lv``, ``c0_sv`` are two custom instructions for vector load and store respectively, using the same opcode and the S' instruction type. `c1`, `c2` and `c3` are for the custom instructions, and are using the I' instruction type. Currently, `c1`, `c2` and `c3` are used for the merge, sort and prefix SIMD instruction examples, but can be replaced as well as increased and aliased. For more information on the pre-defined opcodes for custom instructions, and for adding more, see file `riscv-gnu-toolchain/riscv-binutils/include/opcode/riscv-opc.h`. The equivalent files are also included in the `riscv-gnu-toolchain/riscv-gdb`, should this be of use.

Finally, we compile the tools by running make, preferably with multiple-threads (15 in the example), as it can take a while.

	$ make newlib -j15

- For experimentation on Xilinx FPGAs, the freely-available Webpack version of [Vivado](https://www.xilinx.com/support/download.html) is enough, given that your FPGA board is mentioned in the licence (see [Release Notes](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2020_1/ug973-vivado-release-notes-install-license.pdf)).

#### License

[Apache License, Version 2.0](https://opensource.org/licenses/Apache-2.0), except on code of other projects like some benchmarks in the Benchmarks folder.
<br><br>
   Copyright 2021 Philippos Papaphilippou @ Imperial College London

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
   
#### Publications

Philippos Papaphilippou, Paul H. J. Kelly and Wayne Luk "Extending the RISC-V ISA for exploring advanced reconfigurable SIMD instructions" The Fifth Workshop on Computer Architecture Research with RISC-V (CARRV 2021) (co-located with ISCA 2021) [pdf](https://carrv.github.io/2021/papers/CARRV2021_paper_86_Papaphilippou.pdf) [slides](https://carrv.github.io/2021/slides/CARRV2021_slides_86_Papaphilippou.pdf) [source](http://philippos.info/simdsoftcore/) [video](https://carrv.github.io/2021/videos/CARRV2021_full_86_Papaphilippou.html) [program](https://carrv.github.io/2021) [bib](./simdcarrv.bib)   
