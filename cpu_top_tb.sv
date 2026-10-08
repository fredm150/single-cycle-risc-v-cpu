`timescale 1ns/1ps

module cpu_top_testb;
    logic clk, reset;

    cpu_top dut (
        .clk(clk), 
        .reset(reset)
        );

    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0, cpu_top_testb);
    end

    initial clk = 0;
    always #5 clk = ~clk;

    int errors = 0, tests = 0;
    task automatic check(string tag, logic [31:0] actual, logic [31:0] expected);
        tests++;
        assert (actual === expected)
            else begin errors++; $error("%s: actual=%h expected=%h", tag, actual, expected); end
    endtask

    initial begin

        // hold reset for 2 cycles, then release
        reset = 1;
        repeat (2) @(posedge clk);
        reset = 0;

        // run the program
        repeat (30) @(posedge clk);
        #1;

        // check registers
        check("x2", dut.dp.rf.registers[2], 32'd25);
        check("x3", dut.dp.rf.registers[3], 32'd68);
        check("x4", dut.dp.rf.registers[4], 32'd1);
        check("x5", dut.dp.rf.registers[5], 32'd11);
        check("x7", dut.dp.rf.registers[7], 32'd7);
        check("x9", dut.dp.rf.registers[9], 32'd18);
        
        
        // untouched registers stay 0
        check("x1", dut.dp.rf.registers[1], 32'd0);
        check("x6", dut.dp.rf.registers[6], 32'd0);
        check("x8", dut.dp.rf.registers[8], 32'd0);

        // check data memory
        check("mem_0x60", dut.dmem.RAM[24], 32'd7);
        check("mem_0x64", dut.dmem.RAM[25], 32'd25);

        if (errors==0) $display("PASS: %0d checks", tests);
        else           $display("FAIL: %0d/%0d", errors, tests);
        $finish;
    end
endmodule