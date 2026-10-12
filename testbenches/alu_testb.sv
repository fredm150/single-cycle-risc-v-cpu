`timescale 1ns/1ps

import alu_ops_pkg::*;                 // only if the DUT uses it

module alu_testb;
  
    //declare local signals
    logic [31:0] a, b;
    logic [3:0]  alu_control;
    logic [31:0] alu_result;
    logic        zero;

    // instantiate DUT
    alu #(.DATA_WIDTH(32)) dut (
        .A          (a),
        .B          (b),
        .alu_control(alu_control),
        .alu_result     (alu_result),
        .Zero       (zero)
    );




  // make a reusable task
  int errors = 0, tests = 0;
  task automatic check(string tag, logic [31:0] actual, logic [31:0] expected);
    tests++;
    assert (actual === expected)             
      else begin errors++; $error("%s: actual=%h expected=%h", tag, actual, expected); end
  endtask

  
  initial begin

    // ADD
    a = 32'd5;  b = 32'd3;  alu_control = ALU_ADD;  #1;
    check("ADD", alu_result, 32'd8);
    assert (zero === 1'b0) else $error("ADD: zero should be 0");

    // ADD  result 0
    a = 32'hFFFF_FFFF; b = 32'd1; alu_control = ALU_ADD; #1;
    check("ADD_wrap_zero", alu_result, 32'h0);
    assert (zero === 1'b1) else $error("ADD_wrap: zero should be 1");

    // SUB
    a = 32'd10; b = 32'd4;  alu_control = ALU_SUB;  #1;
    check("SUB", alu_result, 32'd6);

    // subtraction with equal numbers
    a = 32'd7;  b = 32'd7;  alu_control = ALU_SUB;  #1;
    check("SUB_zero", alu_result, 32'h0);
    assert (zero === 1'b1) else $error("SUB_zero: zero should be 1");

    // AND
    a = 32'hF0F0_F0F0; b = 32'h0FF0_0FF0; alu_control = ALU_AND; #1;
    check("AND", alu_result, 32'h00F0_00F0);

    // OR
    a = 32'hF0F0_F0F0; b = 32'h0FF0_0FF0; alu_control = ALU_OR;  #1;
    check("OR", alu_result, 32'hFFF0_FFF0);

    // XOR
    a = 32'hF0F0_F0F0; b = 32'h0FF0_0FF0; alu_control = ALU_XOR; #1;
    check("XOR", alu_result, 32'hFF00_FF00);

    // Shift left logical
    a = 32'h0000_0001; b = 32'd4;  alu_control = ALU_SLL; #1;
    check("SLL", alu_result, 32'h0000_0010);

    // Shift left logical
    a = 32'h0000_0001; b = 32'd32; alu_control = ALU_SLL; #1;
    check("SLL_shamt", alu_result, 32'h1);

    // Sjift right logical
    a = 32'h8000_0000; b = 32'd4;  alu_control = ALU_SRL; #1;
    check("SRL", alu_result, 32'h0800_0000);

    // Shift right arithmetic with sign extension
    a = 32'h8000_0000; b = 32'd4;  alu_control = ALU_SRA; #1;
    check("SRA", alu_result, 32'hF800_0000);

    // default 
    a = 32'd123; b = 32'd456; alu_control = 4'hF; #1;
    check("DEFAULT", alu_result, 32'h0);

    // Signed Less Than (SLT)
    a = 32'hFFFF_FFFF; b = 32'd0;  alu_control = ALU_SLT; #1;
    check("SLT", alu_result, 32'h1);

    // Signed Less Than (SLT) unsigned
    a = 32'hFFFF_FFFF; b = 32'd0;  alu_control = ALU_SLTU; #1;
    check("SLTU", alu_result, 32'h0);

   
    // multiply 
    a = 32'hFFFF_FFFF; b = 32'hFFFF_FFFF;  alu_control = ALU_MUL; #1;
    check("MUL", alu_result, 32'h1);

    // multiply (signed x signed)
    a = 32'hFFFF_FFFF; b = 32'hFFFF_FFFF;  alu_control = ALU_MULH; #1;
    check("MULH", alu_result, 32'h0);

    // multiply H (signed by unsigned)
    a = 32'hFFFF_FFFF; b = 32'hFFFF_FFFF;  alu_control = ALU_MULHSU; #1;
    check("MULHSU", alu_result, 32'hFFFF_FFFF);

    // multiply h (both unsigned)
    a = 32'hFFFF_FFFF; b = 32'hFFFF_FFFF;  alu_control = ALU_MULHU; #1;
    check("MULHU", alu_result, 32'hFFFF_FFFE);





    

    // summary
    if (errors == 0) $display("PASS: %0d checks", tests);
    else             $display("FAIL: %0d/%0d", errors, tests);
    $finish;
  end
endmodule
  

    