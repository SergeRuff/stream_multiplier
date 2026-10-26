#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

vlib work
vlog src/oneshot_buffer.v src/stream_multiplier_top.v src/testbench.sv
vsim -gui -voptargs="+acc" work.testbench -do "onfinish stop; add wave -position insertpoint sim:/testbench/*; add wave -position insertpoint sim:/testbench/DUT/*; run -all; wave zoom full"

