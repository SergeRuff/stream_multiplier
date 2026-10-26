cd /d "%~dp0"

vlib work
vlog oneshot_buffer.sv stream_multiplier.sv ../src/testbench.sv
if errorlevel 1 exit /b %errorlevel%
vsim -gui -voptargs="+acc" work.testbench -do "onfinish stop; add wave -position insertpoint sim:/testbench/*; add wave -position insertpoint sim:/testbench/DUT/*; run -all; wave zoom full"
