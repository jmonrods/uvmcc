# 01: Randomization

In this tutorial, we want to create an imem module that generates random instructions, instead of the imem module from the original CPU.

Create a copy of the riscv folder as follows:

```bash
cp riscv riscv_v01
cd riscv_v01
```

## Random instruction generator

Create a file imem.sv:

```bash
touch imem.sv
```

Add the following contents to this file:

```systemverilog
`timescale 1ns/1ps

// define macro for randomization check
`define SV_RAND_CHECK(r) \
    do begin \
        if (!(r)) begin \
            $display("%s:%d: Randomization failed \"%s\"", \
            `__FILE__, `__LINE__, `"r`"); \
            $finish(); \
        end \
    end while (0)


package riscv_asm;

	typedef enum {ADDI, ADD, SUB, AND, OR, SLT} op_e;
	
	class Instruction;
	
		rand op_e operation;
		
		rand logic [4:0] rd;
		rand logic [4:0] rs1;
		rand logic [4:0] rs2;
		
		logic [6:0] funct7;
		logic [2:0] funct3;
		logic [6:0] opcode;

		rand logic [11:0] imm;

		logic [31:0] instr;
		
		function void post_randomize();
			
			case (operation)
				ADDI:
				begin
					opcode = 7'b0010011;
					funct3 = 3'b000;
					funct7 = 7'b0000000;
					instr  = {imm,rs1,funct3,rd,opcode};
				end
				ADD:
				begin
					opcode = 7'b0110011;
					funct3 = 3'b000;
					funct7 = 7'b0000000;
					instr  = {funct7,rs2,rs1,funct3,rd,opcode};
				end
				SUB:
				begin
					opcode = 7'b0110011;
					funct3 = 3'b000;
					funct7 = 7'b0100000;
					instr  = {funct7,rs2,rs1,funct3,rd,opcode};
				end
				AND:
				begin
					opcode = 7'b0010011;
					funct3 = 3'b111;
					funct7 = 7'b0000000;
					instr  = {funct7,rs2,rs1,funct3,rd,opcode};
				end
				OR:
				begin
					opcode = 7'b0010011;
					funct3 = 3'b110;
					funct7 = 7'b0000000;
					instr  = {funct7,rs2,rs1,funct3,rd,opcode};
				end
				SLT:
				begin
					opcode = 7'b0010011;
					funct3 = 3'b010;
					funct7 = 7'b0000000;
					instr  = {funct7,rs2,rs1,funct3,rd,opcode};
				end
			endcase
			
		endfunction
		
		function void print_instr();
		
			case (operation)
				ADDI:    $display("%0s:\t%32b",operation.name(),instr);
				default: $display("%0s:\t%32b",operation.name(),instr); 
			endcase
		
		endfunction 
	
	endclass

endpackage


module imem(
	input        [31:0] A,
	output logic [31:0] RD
);

	import riscv_asm::*;

	Instruction in;
	

	initial begin
		
		#400 $finish();
	
	end

	always @(A) begin

		in = new();
		`SV_RAND_CHECK(in.randomize());
		in.print_instr();
		RD = in.instr;

	end

endmodule
```

Also, create a testbench for this module:

```bash
touch imem_tb.sv
```

And add the following code to the testbench:

```systemverilog
`timescale 1ns/1ps

module imem_tb();

	logic [31:0] addr;
	logic [31:0] instr;

	imem imem1(
		.A  (addr),
		.RD (instr)
	);
	
	initial begin
	
		addr = 32'h00400000;
		forever #10 addr = addr + 4;
	
	end

endmodule

```

Modify the Makefile:
```bash
cd ..
nano Makefile
```

And add the following target to the Makefile:
```makefile
imem_tb: clean
	vlib work
	vmap work work
	vlog -sv ./riscv_v01/imem_tb.sv ./riscv_v01/imem.sv
	vsim -c work.imem_tb -do "run -all; quit -f;"
```

Run the testbench of the imem block:

```bash
make imem_tb
```

## Testbench of the CPU with the random instruction generator

Edit the cpu.sv file and comment the whole module declaration for the imem module.

Then, edit the Makefile and add a new target with the following commands:

```makefile
cpu_tb_v01: clean
	vlib work
	vmap work work
	vlog -sv ./riscv_v01/cpu_tb.sv ./riscv_v01/imem.sv ./riscv_v01/cpu.sv
	vsim -c work.cpu_tb -do "run -all; quit -f;"
```

Run the testbench:

```bash
make cpu_tb_v01
```

If you want, you can give more time to the simulation by modifying the testbench too. Just add more time inside the `initial` block.

This runs with the default seed, you can pick a specific seed by adding it to the vlog and vsim commands, for example with `-sv_seed 100`, or a random seed each time with `-sv_seed random`.


## Coverage collection

Now it is time to add coverage collection to our randomized test.

In order to do this, just add another Makefile target:

```makefile
cpu_tb_v01_cov: clean
	vlib work
	vmap work work
	vlog +cover -sv ./riscv_v01/cpu_tb.sv ./riscv_v01/cpu.sv ./riscv_v01/imem.sv
	vsim -c -coverage work.cpu_tb -do "coverage save -onexit coverage.ucdb; run -all; quit -f;"
	vcover report coverage.ucdb
```

Try with random seeds to see who of the class can get the most coverage. This is done by adding `-sv_seed random` to the `vlog` command.

Also, give it more time in the `cpu_tb.sv` until you reach 'enough' coverage. 
