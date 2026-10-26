@echo off
cd /d "%~dp0"

vlib work
vlog src/oneshot_buffer.v src/stream_multiplier_top.v src/testbench.sv
if errorlevel 1 exit /b %errorlevel%
vsim -gui -voptargs="+acc" work.testbench -do "onfinish stop; add wave -divider {Testbench}; add wave sim:/testbench/*; add wave -divider {DUT}; add wave sim:/testbench/DUT/CLK sim:/testbench/DUT/RESET sim:/testbench/DUT/LOAD1 sim:/testbench/DUT/LOAD2 sim:/testbench/DUT/DIN sim:/testbench/DUT/DOUT sim:/testbench/DUT/OE sim:/testbench/DUT/current_state sim:/testbench/DUT/next_state sim:/testbench/DUT/err; run -all; wave zoom full"
