# UVM Crash Course
# Author:       Juan José Montero Rodríguez
# Date:         26.01.2026
# Description:  RISC-V CPU from Harris & Harris

clean:
	rm ./vsim.wlf -f
	rm ./vsim.dbg -f
	rm ./modelsim.ini -f
	rm ./coverage.ucdb -f
	rm ./coverage.txt -f
	rm ./work/ -rf
	rm ./transcript -f

cpu_v00: clean
	vlib work
	vmap work work
	vlog -sv ./riscv/cpu_tb.sv ./riscv/cpu.sv
	vsim -c work.cpu_tb -do "run -all; quit -f;"


