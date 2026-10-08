`timescale 1ns/1ps

module dmem_testb;
    logic        clk, mem_wr;
    logic [31:0] addr, wr_data, read_data;

    dmem dut (
        .clk(clk),
        .mem_wr(mem_wr),
        .addr(addr),
        .wr_data(wr_data),
        .read_data(read_data)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    int errors = 0, tests = 0;

    task automatic check(string tag, logic [31:0] actual, logic [31:0] expected);
        tests++;
        assert (actual === expected)
            else begin errors++; $error("%s: actual=%h expected=%h", tag, actual, expected); end
    endtask

    initial begin

        mem_wr = 0;
        addr = 32'h0;
        wr_data = 32'h0;

        // write word to addr 0
        addr = 32'h0; wr_data=32'hAAAA_5555; mem_wr=1;
        @(posedge clk); #1; mem_wr=0;
        check("write_word0", read_data, 32'hAAAA_5555);

        // write a different word to addr 4
        addr=32'h4; wr_data=32'h1234_5678; mem_wr=1;
        @(posedge clk); #1; mem_wr=0;
        check("write_word1", read_data, 32'h1234_5678);


        addr=32'h0; #1;
        check("readback_word0", read_data, 32'hAAAA_5555);

        addr=32'h0; wr_data=32'hDEAD_BEEF; mem_wr=0;
        @(posedge clk); #1;
        addr=32'h0; #1;
        check("we_off", read_data, 32'hAAAA_5555);

        addr=32'h7; #1;
        check("byteoff", read_data, 32'h1234_5678);

        if (errors==0) $display("PASS: %0d checks", tests);
        else           $display("FAIL: %0d/%0d", errors, tests);
        $finish;
    end
endmodule