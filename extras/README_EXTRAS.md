This directory contains an implementation of the device described in the technical specification, with one caveat: it is implemented in SystemVerilog. In terms of functionality, the device is identical to the one found in the [original folder](../solution).

Verification can be initiated using the scripts [run_tb_sv.bat](./run_tb_sv.bat) (for Windows cmd) or [run_tb_sv.sh](./run_tb_sv.sh) (for Linux shell).

**P.S.** Please note that the same testbench file—[testbench.sv](../solution/testbench.sv)—is used for both the Verilog and SystemVerilog implementations.