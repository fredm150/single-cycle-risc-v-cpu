`timescale 1ns/1ps

module pc_testb;


    logic [31:0] pc_next, data_out;
    logic        clk, wr_enable, reset;

    PC #(.WIDTH(32)) dut (
        .pc_next(pc_next), 
        .clk(clk),
        .wr_enable(wr_enable), 
        .reset(reset), 
        .data_out(data_out)
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

        // synchronous reset
        reset = 1; wr_enable = 0; pc_next = 32'h0;
        @(posedge clk); #1;
        check("reset", data_out, 32'h0);

        // load, with wr_enable high
        reset=0; wr_enable=1; pc_next=32'h4;
        @(posedge clk); #1;
        check("load_4", data_out, 32'h4);

        pc_next = 32'h8;
        @(posedge clk); #1;
        check("load_8", data_out, 32'h8);

        // write enable low
        wr_enable = 0; pc_next = 32'hDEAD_BEEF;
        @(posedge clk); #1;
        check("hold", data_out, 32'h8);

        // reset mid-stream
        reset=1;
        @(posedge clk); #1;
        check("reset_again", data_out, 32'h0);

        if (errors==0) $display("PASS: %0d checks", tests);
        else           $display("FAIL: %0d/%0d", errors, tests);
        $finish;
    end
endmodule