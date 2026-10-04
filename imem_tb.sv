`timescale 1ns/1ps

module imem_testb;
    logic [31:0] addr, inst;

    instr_memory dut (.addr(addr), .inst(inst));

    int errors = 0, tests = 0;
    task automatic check(string tag, logic [31:0] actual, logic [31:0] expected);
        tests++;
        assert (actual === expected)
            else begin errors++; $error("%s: actual=%h expected=%h", tag, actual, expected); end
    endtask

    initial begin
        #1;  
       
        // check instructions from program.txt
        addr = 32'h0000_0000; #1; check("w0", inst, 32'h00500113);
        addr = 32'h0000_0004; #1; check("w1", inst, 32'h00C00193);
        addr = 32'h0000_0008; #1; check("w2", inst, 32'hFF718393);
        addr = 32'h0000_000C; #1; check("w3", inst, 32'h0023E233);

        // low 2 bits ignored
        addr = 32'h0000_0005; #1; check("byteoff", inst, 32'h00C00193);

        if (errors==0) $display("PASS: %0d checks", tests);
        else           $display("FAIL: %0d/%0d", errors, tests);
        $finish;
    end
endmodule

