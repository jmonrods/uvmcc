<!-- UVM Crash Course                                -->
<!-- Author:       Juan José Montero Rodríguez       -->
<!-- Date:         26.01.2026                        -->
<!-- Description:  RISC-V CPU from Harris & Harris   -->

# 03: UVM testbench

Now let's use UVM. Why? Because in the previous practice, if we ever want to create a new test, we have to modify the tester.svh file and add more tests with tasks, which will become copies of the original tasks with some modifications. This requires a lot of replication, and we do not want to copy and paste everything. 

Another issue with the copy-pasting approach is that we must compile everything, every time we want to run the test. So, imagine compilation needs 5 minutes, and we need 1000 different tests. That's 3.5 days of non-stop, compilation time.

The most efficient way to make more tests as you go, is to add them as extensions of an UVM class. In fact, let's make everything into UVM classes, to keep them standardized.

## Setting up

Let's start by creating a fresh copy of the original directed-test project:

```bash
cd ~/Work/uvmcc
cp riscv riscv_v03
cd riscv_v03
```

Inside, create a folder for the cpu (DUT) and another for the UVM testbench (`uvm_tb`). Remember also to thrash the directed testbench.

```bash
mkdir cpu
mv cpu.sv cpu/ 
rm cpu_tb.sv

mkdir uvm_tb
```

## The top module

Let's start by creating our top-level file for the simulation. In the root folder of the project, create the following `top.sv` file:

```systemverilog
`timescale 1ns/1ps

module top();

    // import uvm package and macros
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // import cpu package and macros
    import cpu_pkg::*;
    `include "cpu_macros.svh"

    // instantiate dut and bfm
    cpu DUT (
        .rst     (bfm.rst),
        .clk     (bfm.clk),
        .PC      (bfm.pc),
        .Instr   (bfm.instr),
        .Result  (bfm.result)
    );

    cpu_bfm bfm();

    initial begin
        
        // use the set() method from uvm_config_db to store the bfm into the config database
        uvm_config_db #(virtual cpu_bfm)::set(null, "*", "bfm", bfm);

        // run the test
        run_test();

    end

endmodule
```

You see some UVM predefined packages, and also our own packages. Then the DUT is instantiated, then the BFM is created as an instance too. And inside the initial, we use the `uvm_config_db` to store the BFM in the UVM database. This allows access from everywhere, so you don't need to pass the BFM down to every class and object. They look at it directly from the database. If you ever change the BFM, it is passed down automatically.


## The CPU

Inside the `cpu` folder, modify the header so it looks like this:

```systemverilog
module cpu (
    input clk,
    input rst,
    input        [31:0] Instr,
    output logic [31:0] PC,
    output logic [31:0] Result
);
```

We need the PC out of the processor, because some instructions depend on the current value of PC and we need to compute every possible outcome in the scoreboard. 


## The BFM

Navigate to the `uvm_tb` folder and start creating the following files:

`cpu_pkg.sv`

```systemverilog
package cpu_pkg;

	import uvm_pkg::*;
	`include "uvm_macros.svh"

    typedef enum {ADDI, ADD, SUB, AND, OR, SLT} op_e;

	typedef struct {
		logic [4:0]  rd;
		logic [4:0]  rs1;
		logic [4:0]  rs2;
		logic [6:0]  funct7;
		logic [2:0]  funct3;
		logic [6:0]  opcode;
		logic [11:0] imm;
	} data_s;

	`include "scoreboard.svh"
	`include "coverage.svh"
	`include "base_tester.svh"
	`include "random_tester.svh"
	`include "add_tester.svh"
	`include "env.svh"
	`include "random_test.svh"
	`include "add_test.svh"

endpackage
```

`cpu_macros.svh`

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

`cpu_bfm.sv`

```systemverilog
`timescale 1ns/1ps

// bus functional model of the CPU
interface cpu_bfm;

    import cpu_pkg::*;
    `include "cpu_macros.svh"

    logic clk, rst;
    logic [31:0] pc;
    logic [31:0] instr;
    logic [31:0] result;

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

    task send_instruction(input op_e operation, input data_s data);

        case (operation)
            ADDI:
            begin
                data.opcode = 7'b0010011;
                data.funct3 = 3'b000;
                data.funct7 = 7'b0000000;
                instr = {data.imm,data.rs1,data.funct3,data.rd,data.opcode};
            end
            ADD:
            begin
                data.opcode = 7'b0110011;
                data.funct3 = 3'b000;
                data.funct7 = 7'b0000000;
                instr  = {data.funct7,data.rs2,data.rs1,data.funct3,data.rd,data.opcode};
            end
            SUB:
            begin
                data.opcode = 7'b0110011;
                data.funct3 = 3'b000;
                data.funct7 = 7'b0100000;
                instr = {data.funct7,data.rs2,data.rs1,data.funct3,data.rd,data.opcode};
            end
            AND:
            begin
                data.opcode = 7'b0110011;
                data.funct3 = 3'b111;
                data.funct7 = 7'b0000000;
                instr = {data.funct7,data.rs2,data.rs1,data.funct3,data.rd,data.opcode};
            end
            OR:
            begin
                data.opcode = 7'b0110011;
                data.funct3 = 3'b110;
                data.funct7 = 7'b0000000;
                instr = {data.funct7,data.rs2,data.rs1,data.funct3,data.rd,data.opcode};
            end
            SLT:
            begin
                data.opcode = 7'b0110011;
                data.funct3 = 3'b010;
                data.funct7 = 7'b0000000;
                instr = {data.funct7,data.rs2,data.rs1,data.funct3,data.rd,data.opcode};
            end
        endcase

        @(posedge clk);

    endtask : send_instruction

endinterface
```

## The test and tester

Still inside the `uvm_tb` folder, create these files:

` base_tester.svh`

```systemverilog
virtual class base_tester extends uvm_component;
    `uvm_component_utils(base_tester);
    
    virtual cpu_bfm bfm;

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        if(!uvm_config_db #(virtual cpu_bfm)::get(null, "*","bfm", bfm))
            $fatal("Failed to get BFM");
    endfunction : build_phase

    pure virtual function op_e get_op();

    pure virtual function data_s get_data();

    task run_phase(uvm_phase phase);
        op_e      operation;
        data_s    data;

        phase.raise_objection(this);

        bfm.reset_cpu();

        repeat (1000) begin : random_loop
            operation = get_op();
            data      = get_data();
            bfm.send_instruction(operation, data);
        end : random_loop
        
        phase.drop_objection(this);
        
    endtask : run_phase

endclass
```

`random_tester.svh`

```systemverilog
class random_tester extends base_tester;
    `uvm_component_utils(random_tester);

    function data_s get_data();
        data_s data;
        data.rs1 = $random;
        data.rs2 = $random;
        data.rd  = $random;
        data.imm = $random;
        return data;
    endfunction : get_data

    function op_e get_op();
        op_e operation;
        logic [2:0] op;
        op = $random;
        case (op)
            3'b000:  operation = ADD;
            3'b001:  operation = SUB;
            3'b010:  operation = AND;
            3'b011:  operation = OR;
            3'b100:  operation = ADDI;
            3'b101:  operation = SLT;
            default: operation = ADD;
        endcase
        return operation;
    endfunction : get_op

    function new (string name, uvm_component parent);
      super.new(name, parent);
   endfunction : new

endclass
```

`random_test.svh`

```systemverilog
class random_test extends uvm_test;
    `uvm_component_utils(random_test);

    env env_h;

    function new (string name, uvm_component parent);
        super.new(name,parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
      base_tester::type_id::set_type_override(random_tester::get_type());
      env_h = env::type_id::create("env_h",this);
   endfunction : build_phase

endclass
```

## The UVM environment

Still inside the `uvm_tb` folder, create the following file:

`env.svh`

```systemverilog
class env extends uvm_env;
    `uvm_component_utils(env);

    base_tester   tester_h;
    coverage      coverage_h;
    scoreboard    scoreboard_h;

    function void build_phase(uvm_phase phase);
        tester_h     = base_tester::type_id::create("tester_h",this);
        coverage_h   = coverage::type_id::create ("coverage_h",this);
        scoreboard_h = scoreboard::type_id::create("scoreboard_h",this);
    endfunction : build_phase

    function new (string name, uvm_component parent);
        super.new(name,parent);
    endfunction : new

endclass
```

## Coverage collection

Still inside the `uvm_tb` folder, create the following file:

`coverage.svh`

```systemverilog
// coverage: captures functional coverage information
class coverage extends uvm_component;
    `uvm_component_utils(coverage);

    virtual cpu_bfm bfm;

    covergroup cov_instr_operation;
        coverpoint bfm.instr[6:0] {
            bins rtype = {7'b0110011};
            bins itype = {7'b0010011};
        }
    endgroup

    function new (string name, uvm_component parent);
        super.new(name, parent);
        cov_instr_operation = new();
    endfunction : new

    function void build_phase(uvm_phase phase);
        if(!uvm_config_db #(virtual cpu_bfm)::get(null, "*", "bfm", bfm))
            $fatal("Failed to get BFM");
    endfunction : build_phase

    task run_phase(uvm_phase phase);

        forever begin : sampling_block
            @(posedge bfm.clk) #1;
            cov_instr_operation.sample();
        end : sampling_block
    
    endtask : run_phase

endclass
```

## The scoreboard

Still inside the `uvm_tb` folder, create the following file:

`scoreboard.svh`

```systemverilog
// scoreboard: checks if the cpu is working
class scoreboard extends uvm_component;
    `uvm_component_utils(scoreboard);

    virtual cpu_bfm bfm;

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        if(!uvm_config_db #(virtual cpu_bfm)::get(null, "*", "bfm", bfm))
            $fatal("Failed to get BFM");
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        
        logic [31:0] predicted_result;
        logic [31:0] register_bank [32];

        logic [4:0]  rs1;
        logic [4:0]  rs2;
        logic [4:0]  rd;
        logic [11:0] imm;
        logic [6:0]  opcode;
        logic [2:0]  funct3;
        logic [6:0]  funct7;

        op_e operation;

        int i;
        for (i=0; i<32; i++) register_bank[i] = 0;

        forever begin : self_checker
            
            @(posedge bfm.clk) #1;

            rd  = bfm.instr[11:7];
            rs1 = bfm.instr[19:15];
            rs2 = bfm.instr[24:20];
            imm = bfm.instr[31:20];
            opcode = bfm.instr[6:0];
            funct3 = bfm.instr[14:12];
            funct7 = bfm.instr[31:25];

            case (opcode)
                7'b0110011: // r-type 
                begin
                    case (funct3)
                        3'b000: 
                        begin
                            if (funct7[5] == 0) operation = ADD;
                            else operation = SUB;
                        end
                        3'b010: operation = SLT;
                        3'b110: operation = OR;
                        3'b111: operation = AND;
                    endcase
                end
                7'b0010011: // i-type
                begin
                    operation = ADDI;
                end
            endcase

            case(operation)
                ADD:  predicted_result = register_bank[rs1] + register_bank[rs2];
                SUB:  predicted_result = register_bank[rs1] - register_bank[rs2];
                AND:  predicted_result = register_bank[rs1] & register_bank[rs2];
                OR:   predicted_result = register_bank[rs1] | register_bank[rs2];
                SLT:  predicted_result = ($signed(register_bank[rs1]) < $signed(register_bank[rs2])) ? 32'hFFFFFFFF : 32'h00000000;
                ADDI: predicted_result = register_bank[rs1] + {{20{imm[11]}},imm};
            endcase

            register_bank[rd] = (rd == 0) ? 32'h00000000 : predicted_result;

            if (predicted_result !== bfm.result) $error("FAILED: rd: %0d  rs1: %0d  rs2: %0d  imm: %0d  op: %s  result: 0x%0h  expected: 0x%0h", rd, rs1, rs2, imm, operation.name(), bfm.result, predicted_result);
            else $display("PASSED: rd: %0d  rs1: %0d  rs2: %0d  imm: %0d  op: %s  result: 0x%0h  expected: 0x%0h", rd, rs1, rs2, imm, operation.name(), bfm.result, predicted_result);

        end : self_checker
    
    endtask : run_phase

endclass
```

## Adding the Makefile target

Modify the Makefile of the project and add the following target:

```makefile
cpu_v03: clean
	vlib work
	vmap work work
	vlog -sv \
		./riscv_v03/cpu/cpu.sv \
		./riscv_v03/uvm_tb/cpu_pkg.sv \
		./riscv_v03/uvm_tb/cpu_bfm.sv \
		./riscv_v03/top.sv \
		+incdir+./riscv_v03/uvm_tb
	vopt top -o top_optimized +cover=sbfec+cpu
	vsim -c +UVM_TESTNAME="random_test" top_optimized -coverage -do "set NoQuitOnFinish 1; onbreak {resume}; log /* -r; run -all; coverage save -onexit coverage.ucdb; quit;"
	vcover report coverage.ucdb
```

## Running the simulation

Just hit the make command!

```bash
cd ~/Work/uvmcc
make cpu_v03
```

You should see the simulation output with random instructions, coverage, and the PASS/FAIL results of the scoreboard.

## Adding a specific test

If we want to test ONLY the add instructions, we can make another tester. Navigate to the `uvm_tb` folder and create the following two files:

`add_tester.svh`

```systemverilog
class add_tester extends random_tester;
    `uvm_component_utils(add_tester);
    
    function op_e get_op();
        op_e operation;
        operation = ADD;
        return operation;
    endfunction : get_op

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

endclass
```

`add_test.svh`

```systemverilog
class add_test extends uvm_test;
    `uvm_component_utils(add_test);

    env env_h;

    function new (string name, uvm_component parent);
        super.new(name,parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
      base_tester::type_id::set_type_override(add_tester::get_type());
      env_h = env::type_id::create("env_h",this);
   endfunction : build_phase

endclass
```

Modify the Makefile:

```makefile
cpu_v03: clean
	vlib work
	vmap work work
	vlog -sv \
		./riscv_v03/cpu/cpu.sv \
		./riscv_v03/uvm_tb/cpu_pkg.sv \
		./riscv_v03/uvm_tb/cpu_bfm.sv \
		./riscv_v03/top.sv \
		+incdir+./riscv_v03/uvm_tb
	vopt top -o top_optimized +cover=sbfec+cpu
	vsim -c +UVM_TESTNAME="random_test" top_optimized -coverage -do "set NoQuitOnFinish 1; onbreak {resume}; log /* -r; run -all; coverage save -onexit coverage.ucdb; quit;"
	vcover report coverage.ucdb
    vsim -c +UVM_TESTNAME="add_test" top_optimized -coverage -do "set NoQuitOnFinish 1; onbreak {resume}; log /* -r; run -all; coverage save -onexit coverage.ucdb; quit;"
	vcover report coverage.ucdb
```

And observe that the `vlog` command is invoked only once, then the specific tests are running after compilation time, by passing a parameter called `UVM_TESTNAME` with the specific test we want. No need to recompile before switching tests.

This concludes our lecture. Good effort!
