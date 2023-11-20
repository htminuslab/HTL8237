@REM ------------------------------------------------------
@REM Simple DOS batch file to compile and run the testbench
@REM Ver 1.0 HT-Lab 2005-2024
@REM Tested with Modelsim 10.3
@REM ------------------------------------------------------
vlib work

@REM Compile HTL8237 
vcom -93 -quiet -work work ../rtl/HTL8237_pkg.vhd
vcom -93 -quiet -work work ../rtl/dreqack_rtl.vhd
vcom -93 -quiet -work work ../rtl/fsm37_fsm.vhd
vcom -93 -quiet -work work ../rtl/channel_rtl.vhd
vcom -93 -quiet -work work ../rtl/blk37_struct.vhd
vcom -93 -quiet -work work ../rtl/htl8237_struct.vhd


@REM Compile Testbench
vcom -2008 -quiet -work work ../testbench/utils.vhd
vcom -2008 -quiet -work work ../testbench/sram_behavior.vhd
vcom -2008 -quiet -work work ../testbench/ioblk_behavioral.vhd
vcom -2008 -quiet -work work ../testbench/stimulus_behavioral.vhd
vcom -2008 -quiet -work work ../testbench/htl8237_tb_behavioral.vhd

@REM Run simulation
vsim HTL8237_tb -c -do "set StdArithNoWarnings 1; run -all; quit -f"
