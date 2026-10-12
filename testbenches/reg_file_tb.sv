`timescale 1ns/1ps

module reg_file_testb;
    logic        clk, rst, wr_enable;
    logic [4:0]  reg_1, reg_2, reg_d;
    logic [31:0] wr_data, read_data1, read_data2;

    reg_file dut (
        .clk(clk),
        .rst(rst),
        .wr_enable(wr_enable),
        .reg_1(reg_1),
        .reg_2(reg_2),
        .reg_d(reg_d),
        .wr_data(wr_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
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
        rst = 0;
        wr_enable = 0; 
        reg_1 = 0; 
        reg_2 = 0; 
        reg_d = 0; 
        wr_data = 0;

        // async reset
        rst=1; #1;
        reg_1=5'd5; reg_2=5'd10; #1;
        check("reset_r5",  read_data1, 32'h0);
        check("reset_r10", read_data2, 32'h0);
        rst=0;

        reg_d=5'd5; wr_data=32'hDEAD_BEEF; wr_enable=1;
        @(posedge clk); #1; wr_enable=0;
        reg_1=5'd5; #1;
        check("write_r5", read_data1, 32'hDEAD_BEEF);

        reg_d=5'd10; wr_data=32'h1234_5678; wr_enable=1;
        @(posedge clk); #1; wr_enable=0;
        reg_2=5'd10; #1;
        check("write_r10", read_data2, 32'h1234_5678);
        reg_1=5'd5; #1;
        check("r5_intact", read_data1, 32'hDEAD_BEEF);

        // write attempt on register zero
        reg_d=5'd0; wr_data=32'hFFFF_FFFF; wr_enable=1;
        @(posedge clk); #1; wr_enable=0;
        reg_1=5'd0; #1;
        check("x0_zero", read_data1, 32'h0);

        reg_d=5'd5; wr_data=32'hAAAA_AAAA; wr_enable=0;
        @(posedge clk); #1;
        reg_1=5'd5; #1;
        check("we_off", read_data1, 32'hDEAD_BEEF);

        // check if reset works correctly
        rst=1; #1;
        reg_1=5'd5; #1;
        check("reset_clears", read_data1, 32'h0);
        rst=0;

        if (errors==0) $display("PASS: %0d checks", tests);
        else           $display("FAIL: %0d/%0d", errors, tests);
        $finish;
    end
endmodule