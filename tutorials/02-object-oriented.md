# 02: Object-oriented testbench

The randomized testbench works, but imagine you need to make a new instruction, and test only that instruction. You would have to copy the whole thing and modify the randomized instruction generator, which is the `imem.sv` block, every time you want a specific test in mind.

## Intro to OOP testbench

The idea with OOP is to create a 'bus functional model' (BFM) that connects to the CPU as if it were the `imem` block. Remember we are testing the CPU with specific instructions.

Within this BFM, we create tests, that create instructions, where instructions are objects. Every object is created by the factory pattern.

The factory pattern is this: imagine you have a class named `animal`. Then you have a class named `cat` that extends `animal`, and a class named `dog` that extends `animal`. Every `cat` and `dog` is an `animal`. Then, we ask the factory to produce a new `giraffe`, which also has to be `animal`. We can specify common characteristics for all animals, and modify or tweak ONLY the differences. 

For our application, the `cat` and `dog` and `giraffe` will become tests, that extend a main generic class with the configuration of the overall test. But we can have types of tests, by modifying only little details of these tests.


## The Bus Functional Model

Copy the whole `riscv` original folder and label it as `riscv_v02`.

```bash
cd ~/Work/uvmcc
cp riscv riscv_v02
cd riscv_v02
```

Now, create a file `cpu_bfm.sv` and add the following code:

```systemverilog
`timescale 1ns/1ps

// bus functional model of the CPU
interface cpu_bfm;

    import cpu_pkg::*;
    `include "cpu_macros.svh"

    logic clk, rst;
    logic [31:0] instr;
    logic [31:0] result;

    Instruction in;

    initial begin
        clk = 1;
        forever begin
            #5;
            clk = ~clk;
        end
    end

    task reset_cpu();
        
        rst = 1;
        @(posedge clk);
        rst = 0;

    endtask : reset_cpu

    task send_instruction();

        in = new();
        `SV_RAND_CHECK(in.randomize());
        in.print_instr();

        instr = in.instr;
        
        @(posedge clk);

    endtask : send_instruction

endinterface
```

This uses a package, which is a collection of classes and type declarations. Let's create a file `cpu_pkg.sv` and add the following contents:

```systemverilog
package cpu_pkg;

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
					opcode = 7'b0110011;
					funct3 = 3'b111;
					funct7 = 7'b0000000;
					instr  = {funct7,rs2,rs1,funct3,rd,opcode};
				end
				OR:
				begin
					opcode = 7'b0110011;
					funct3 = 3'b110;
					funct7 = 7'b0000000;
					instr  = {funct7,rs2,rs1,funct3,rd,opcode};
				end
				SLT:
				begin
					opcode = 7'b0110011;
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
```

We will need another file with macros, let's create `cpu_macros.svh` with the following lines:

```systemverilog
// define macro for randomization check
`define SV_RAND_CHECK(r) \
    do begin \
        if (!(r)) begin \
            $display("%s:%d: Randomization failed \"%s\"", \
            `__FILE__, `__LINE__, `"r`"); \
            $finish(); \
        end \
    end while (0)
```

## The top module

And now, we need to connect the BFM to the CPU.

This part is tricky, because previously, instructions were coming from inside the CPU (remember the imem module?). Now we want to send the instructions from outside. The BFM will also manage the CLK and RST signals. Check the slides for a block diagram.

What we need to do, is modify the `cpu.sv` file and make the header look like this:

```systemverilog
module cpu (
    input clk,
    input rst,
    input  [31:0] Instr,
    output [31:0] Result
);
```

Then we need to remove the imem module completely, so make sure to eliminate both the module and the instance declaration of imem.

With this done, create a `top.sv` file where you will connect the BFM to the CPU:

```systemverilog
`timescale 1ns/1ps

module top();

    import cpu_pkg::*;

    `include "cpu_macros.svh"    
    `include "coverage.svh"
    `include "tester.svh"
    `include "scoreboard.svh"
    `include "testbench.svh"

    cpu DUT (
        .rst(bfm.rst),
        .clk(bfm.clk),
        .Instr(bfm.instr),
        .Result(bfm.result)
    );

    cpu_bfm bfm ();

    testbench testbench_h;

    initial begin
        testbench_h = new(bfm);
        testbench_h.execute();
    end

endmodule : top
```

As you can see, here the testbench is an object of the testbench class, which was declared... where? In the header files that we have not added yet. 

## The header files

Inside the `riscv_v02` folder, create a folder named `tb_classes`:

```bash
cd ~/Work/uvmcc/riscv_v02
mkdir tb_classes
cd tb_classes
```

Here, we need the following four files:

`testbench.sv`:

```systemverilog
//  testbench: the top-level class
class testbench;

    virtual cpu_bfm bfm;

    tester     tester_h;
    coverage   coverage_h;
    scoreboard scoreboard_h;

    function new (virtual cpu_bfm b);
        bfm = b;
    endfunction

    task execute ();

        tester_h     = new(bfm);
        coverage_h   = new(bfm);
        scoreboard_h = new(bfm);

        fork
            tester_h.execute();
            coverage_h.execute();
            scoreboard_h.execute();
        join_none

    endtask : execute

endclass : testbench
```

`tester.sv`:

```systemverilog
// tester: drives stimulus
class tester;
    
    virtual cpu_bfm bfm;

    function new (virtual cpu_bfm b);
        bfm = b;
    endfunction

    task execute();

        bfm.reset_cpu();
        repeat (40) bfm.send_instruction();
        $finish();
        
    endtask : execute

endclass
```

`coverage.sv`

```systemverilog
// coverage: captures functional coverage information
class coverage;

    virtual cpu_bfm bfm;

    covergroup CovInsOp;
        coverpoint bfm.in.operation;
    endgroup

    function new (virtual cpu_bfm b);
        bfm = b;
        CovInsOp = new();
    endfunction : new

    task execute();
        forever begin : sampling_block
            @(posedge bfm.clk) #1;
            CovInsOp.sample();
        end : sampling_block
   endtask : execute

endclass
```

`scoreboard.svh`:

```systemverilog
// scoreboard: checks if the cpu is working
class scoreboard;

    virtual cpu_bfm bfm;

    function new (virtual cpu_bfm b);
        bfm = b;
    endfunction : new


    task execute();
        
        logic [31:0] predicted_result;
        logic [31:0] register_bank [32];

        int i;
        for (i=0; i<32; i++) register_bank[i] = 0;

        forever begin : self_checker
            
            @(posedge bfm.clk) #1;

            case(bfm.in.operation)
                ADD:  predicted_result = register_bank[bfm.in.rs1] + register_bank[bfm.in.rs2];
                SUB:  predicted_result = register_bank[bfm.in.rs1] - register_bank[bfm.in.rs2];
                AND:  predicted_result = register_bank[bfm.in.rs1] & register_bank[bfm.in.rs2];
                OR:   predicted_result = register_bank[bfm.in.rs1] | register_bank[bfm.in.rs2];
                SLT:  predicted_result = ($signed(register_bank[bfm.in.rs1]) < $signed(register_bank[bfm.in.rs2])) ? 32'hFFFFFFFF : 32'h00000000;
                ADDI: predicted_result = register_bank[bfm.in.rs1] + {{20{bfm.in.imm[11]}},bfm.in.imm};
            endcase

            register_bank[bfm.in.rd] = (bfm.in.rd == 0) ? 32'h00000000 : predicted_result;

            if (predicted_result !== bfm.result) $error("FAILED: rs1: %0d  rs2: %0d  imm: %0d  op: %s  result: 0x%0h  expected: 0x%0h", bfm.in.rs1, bfm.in.rs2, bfm.in.imm, bfm.in.operation.name(), bfm.result, predicted_result);
            else $display("PASSED: rs1: %0d  rs2: %0d  imm: %0d  op: %s  result: 0x%0h  expected: 0x%0h", bfm.in.rs1, bfm.in.rs2, bfm.in.imm, bfm.in.operation.name(), bfm.result, predicted_result);

        end : self_checker
    
    endtask

endclass
```

## Adding the Makefile target

We now have everything ready for simulation.

Modify the Makefile and add the following target:

```makefile
cpu_v02: clean
	vlib work
	vmap work work
	vlog -sv -f ./riscv_v02/dut.f
	vlog -sv -f ./riscv_v02/tb.f
	vopt top -o top_optimized +cover=sbfec
	vsim -c top_optimized -coverage -do "set NoQuitOnFinish 1; onbreak {resume}; log /* -r; run -all; coverage save -onexit coverage.ucdb; quit;"
	#vcover report coverage.ucdb
```

Here, the `dut.f` and `tb.f` are file lists, we need to create these as well.

For the `dut.f` use this:

```bash
./riscv_v02/cpu.sv
```

And for the `tb.f` use this:

```bash
./riscv_v02/cpu_pkg.sv
./riscv_v02/cpu_bfm.sv
./riscv_v02/top.sv
+incdir+./riscv_v02/tb_classes
```

## Finally the simulation

Now do:

```bash
make cpu_v02
```

If everything is well, you should see the output of the test and some coverage reports.
