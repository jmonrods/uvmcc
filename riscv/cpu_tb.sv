// UVM Crash Course
// Author:       Juan José Montero Rodríguez
// Date:         26.01.2026
// Description:  RISC-V CPU Directed Testbench

`timescale 1ns/1ps

module cpu_tb();

    reg clk;
    reg rst;
    wire [31:0] read_data;

    cpu cpu1 (
        .clk(clk),
        .rst(rst),
        .Result(read_data)
    );

    initial begin

        rst <= 1;
        #10 rst <= 0;
            $display("%0d",$signed(read_data));
        #10 $display("%0d",$signed(read_data));
        #10 $display("%0d",$signed(read_data));
        #10 $display("%0d",$signed(read_data));
        #10 $display("%0d",$signed(read_data));
        #10 $display("%0d",$signed(read_data));
        #10 $display("%0d",$signed(read_data));
        #10 $display("%0d",$signed(read_data));
        #10 $display("%0d",$signed(read_data));
        #10 $display("%0d",$signed(read_data));
        #10 $display("%0d",$signed(read_data));
        #10 $display("%0d",$signed(read_data));
        #10 $display("%0d",$signed(read_data));
        #10 $display("%0d",$signed(read_data));
        #10 $display("%0d",$signed(read_data));

    end

    initial begin

        clk <= 1;
        forever #5 clk <= !clk;

    end

    initial begin

        #400 $finish();

    end

endmodule
