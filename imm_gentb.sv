`timescale 1ns/1ps

module imm_gen_testb;
  
    //declare local signals
    logic [31:0] instr, imm_ext;
    logic [2:0]  imm_src;

    
    // instantiate DUT
    imm_gen dut (
        .instr      (instr),
        .imm_ext    (imm_ext),
        .imm_src    (imm_src)
    );


  // make a reusable task
  int errors = 0, tests = 0;
  task automatic check(string tag, logic [31:0] actual, logic [31:0] expected);
    tests++;
    assert (actual === expected)             
      else begin errors++; $error("%s: actual=%h expected=%h", tag, actual, expected); end
  endtask

  
  initial begin

    instr = 32'h00500000; imm_src = 3'b000; #1;
    check("I_pos", imm_ext, 32'h00000005);

    instr = 32'hFFB00000; imm_src = 3'b000; #1;
    check("I_neg", imm_ext, 32'hFFFFFFFB);

    instr = 32'h00000280; imm_src = 3'b001; #1;
    check("S_pos", imm_ext, 32'h00000005);

    instr = 32'hFE000D80; imm_src = 3'b001; #1;
    check("S_neg", imm_ext, 32'hFFFFFFFB);

    instr = 32'h02000280; imm_src = 3'b010; #1;
    check("B_pos", imm_ext, 32'h00000824);

    instr = 32'hFE000E80; imm_src = 3'b010; #1;
    check("B_neg", imm_ext, 32'hFFFFFFFC);

    instr = 32'h00501000; imm_src = 3'b011; #1;
    check("J_pos", imm_ext, 32'h00001804);

    instr = 32'hFFDFF000; imm_src = 3'b011; #1;
    check("J_neg", imm_ext, 32'hFFFFFFFC);

    instr = 32'h12345FFF; imm_src = 3'b100; #1;
    check("U", imm_ext, 32'h12345000);

    instr = 32'h12345678; imm_src = 3'b101; #1;
    check("Default", imm_ext, 32'h00000000);


    // summary
    if (errors == 0) $display("PASS: %0d checks", tests);
    else             $display("FAIL: %0d/%0d", errors, tests);
    $finish;
  end
endmodule



    

