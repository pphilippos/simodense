### Benchmark and micro-benchmark directory for the softcore

Each on of the following directories has its own `build.sh` file, that can be used to provite the binary for testing in simulation and on real hardware.

- `sort`
- `prefix sum`
- `benchmark-dhrystone`
- `STREAM`
- `riscv-coremark`

By running `bash build.sh`, on a successful run, the start address is printed to the screen. The start address, alongside the path of the binary must be provided in the respective fields inside the `testbench.v` file for simulation.

#### Remember to:

- Set the correct tool directory from this example line in each `build.sh` file

```
export TOOL_DIR=/opt/riscv32im2/
```

- Set the correct problem size corresponding to a small run for simulation and a big run for the FPGA. 

- With the current configuration, physical addresses starting with 0 is a requirement for the simulation, to consume less RAM, such as 0x07000000 instead of 0x70000000. (The relevant comment exist on the code, and can be uncommented for bigger runs on the FPGA)

- Enable the correct custom SIMD instruction (in the case of prefix sum, comment line 413 and uncomment line 414 from `cpu.v`)

- Some metrics have not been fully ported. Specifically, the performance of `riscv-coremark` is done manually using the ticks rather than the seconds. (Its score was disabled anyway because floating point is disabled)

- Apart from the `StartAddress`, you may also need to change `byte_address` inside `testbench.v`. This should be the start of the symbol table inside the corresponding objdump. (TODO: make it more consistent/automated)   

#### Other notes:

- `benchmark-dhrystone` was fetched from [here](https://github.com/sifive/benchmark-dhrystone) and the modifications were partly based on [PicoRV32](https://github.com/cliffordwolf/picorv32)

- `riscv-coremark` is based on [Coremark EEMBC Wrapper](https://github.com/riscv-boom/riscv-coremark), which is based on [Coremark](https://www.eembc.org/coremark/)

- `STREAM` was originally fetched from [here](https://github.com/jeffhammond/STREAM)
