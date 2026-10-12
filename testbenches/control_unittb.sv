`timescale 1ns/1ps

module control_unittb;
  
    // inputs
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic       funct7_5, funct7_0;
    logic       branch_taken;

    // outputs
    logic [2:0] res_src;
    logic       mem_wr, pc_src, alu_src, reg_wr, jalr;
    logic [2:0] imm_src;
    logic [3:0] alu_control;

    
    // DUT
    control_unit dut (
        .opcode(opcode), .funct3(funct3),
        .funct7_5(funct7_5), .funct7_0(funct7_0),
        .branch_taken(branch_taken),
        .res_src(res_src), .mem_wr(mem_wr), .pc_src(pc_src),
        .alu_src(alu_src), .reg_wr(reg_wr), .jalr(jalr),
        .imm_src(imm_src), .alu_control(alu_control)
    );


  // make a reusable task
  int errors = 0, tests = 0;
  task automatic check(string tag, logic [31:0] actual, logic [31:0] expected);
    tests++;
    assert (actual === expected)             
      else begin errors++; $error("%s: actual=%h expected=%h", tag, actual, expected); end
  endtask

  


    initial begin

    // load word (lw)
    opcode=7'b0000011; funct3=3'b010; funct7_5=0; funct7_0=0; branch_taken=0; #1;
    check("LW_reg_wr",  reg_wr,      1'b1);
    check("LW_mem_wr",  mem_wr,      1'b0);
    check("LW_alu_src", alu_src,     1'b1);
    check("LW_res_src", res_src,     3'b001);
    check("LW_imm_src", imm_src,     3'b000);
    check("LW_pc_src",  pc_src,      1'b0);
    check("LW_alu_ctl", alu_control, ALU_ADD);

    // store word 
    opcode7'b0100011; funct3=3'b010; funct7_5=0; funct7_0=0; branch_taken=0; #1;
    check("SW_reg_wr",  reg_wr,      1'b0);
    check("SW_mem_wr",  mem_wr,      1'b1);
    check("SW_alu_src", alu_src,     1'b1);
    check("SW_imm_src", imm_src,     3'b001);
    check("SW_pc_src",  pc_src,      1'b0);
    check("SW_alu_ctl", alu_control, ALU_ADD);

    // r type
    opcode=7'b0110011; funct3=3'b000; funct7_5=0; funct7_0=0; branch_taken=0; #1;
    check("ADD_reg_wr",  reg_wr,      1'b1);
    check("ADD_mem_wr",  mem_wr,      1'b0);
    check("ADD_alu_src", alu_src,     1'b0);
    check("ADD_res_src", res_src,     3'b000);
    check("ADD_pc_src",  pc_src,      1'b0);
    check("ADD_alu_ctl", alu_control, ALU_ADD);

    // remainng R ty[es]
    opcode=7'b0110011; funct3=3'b000; funct7_5=1; funct7_0=0; #1;
    check("SUB_alu_ctl", alu_control, ALU_SUB);
    opcode=7'b0110011; funct3=3'b111; funct7_5=0; funct7_0=0; #1;
    check("AND_alu_ctl", alu_control, ALU_AND);
    opcode=7'b0110011; funct3=3'b110; funct7_5=0; funct7_0=0; #1;
    check("OR_alu_ctl",  alu_control, ALU_OR);
    opcode=7'b0110011; funct3=3'b010; funct7_5=0; funct7_0=0; #1;
    check("SLT_alu_ctl", alu_control, ALU_SLT);
    opcode=7'b0110011; funct3=3'b101; funct7_5=1; funct7_0=0; #1;
    check("SRA_alu_ctl", alu_control, ALU_SRA);
    opcode=7'b0110011; funct3=3'b101; funct7_5=0; funct7_0=0; #1;
    check("SRL_alu_ctl", alu_control, ALU_SRL);

    // multiply
    opcode=7'b0110011; funct3=3'b000; funct7_5=0; funct7_0=1; #1;
    check("MUL_alu_ctl",    alu_control, ALU_MUL);
    opcode=7'b0110011; funct3=3'b001; funct7_5=0; funct7_0=1; #1;
    check("MULH_alu_ctl",   alu_control, ALU_MULH);
    opcode=7'b0110011; funct3=3'b010; funct7_5=0; funct7_0=1; #1;
    check("MULHSU_alu_ctl", alu_control, ALU_MULHSU);
    opcode=7'b0110011; funct3=3'b011; funct7_5=0; funct7_0=1; #1;
    check("MULHU_alu_ctl",  alu_control, ALU_MULHU);

    // add immediate (addi)
    opcode=7'b0010011; funct3=3'b000; funct7_5=0; funct7_0=0; branch_taken=0; #1;
    check("ADDI_reg_wr",  reg_wr,      1'b1);
    check("ADDI_alu_src", alu_src,     1'b1);
    check("ADDI_mem_wr",  mem_wr,      1'b0);
    check("ADDI_res_src", res_src,     3'b000);
    check("ADDI_imm_src", imm_src,     3'b000);
    check("ADDI_alu_ctl", alu_control, ALU_ADD);

    // branch if equal
    opcode=7'b1100011; funct3=3'b000; funct7_5=0; funct7_0=0; branch_taken=0; #1;
    check("BEQ_nt_reg_wr",  reg_wr,      1'b0);
    check("BEQ_nt_mem_wr",  mem_wr,      1'b0);
    check("BEQ_nt_imm_src", imm_src,     3'b010);
    check("BEQ_nt_pc_src",  pc_src,      1'b0);
    check("BEQ_nt_alu_ctl", alu_control, ALU_SUB);

    // branch if equal
    opcode=7'b1100011; funct3=3'b000; branch_taken=1; #1;
    check("BEQ_tk_pc_src",  pc_src,      1'b1);

    // jump and link
    opcode=7'b1101111; funct3=3'b000; funct7_5=0; funct7_0=0; branch_taken=0; #1;
    check("JAL_reg_wr",  reg_wr,      1'b1);
    check("JAL_mem_wr",  mem_wr,      1'b0);
    check("JAL_res_src", res_src,     3'b010);
    check("JAL_imm_src", imm_src,     3'b011);
    check("JAL_pc_src",  pc_src,      1'b1);
    check("JAL_jalr",    jalr,        1'b0);

    // jump and link register
    opcode=7'b1100111; funct3=3'b000; branch_taken=0; #1;
    check("JALR_reg_wr",  reg_wr,      1'b1);
    check("JALR_alu_src", alu_src,     1'b1);
    check("JALR_res_src", res_src,     3'b010);
    check("JALR_imm_src", imm_src,     3'b000);
    check("JALR_pc_src",  pc_src,      1'b1);
    check("JALR_jalr",    jalr,        1'b1);

    // load upper immediate
    opcode=7'b0110111; funct3=3'b000; #1;
    check("LUI_reg_wr",  reg_wr,      1'b1);
    check("LUI_mem_wr",  mem_wr,      1'b0);
    check("LUI_res_src", res_src,     3'b011);
    check("LUI_imm_src", imm_src,     3'b100);
    check("LUI_pc_src",  pc_src,      1'b0);

    // add upper immediate PC
    opcode=7'b0010111; funct3=3'b000; #1;
    check("AUIPC_reg_wr",  reg_wr,      1'b1);
    check("AUIPC_res_src", res_src,     3'b100);
    check("AUIPC_imm_src", imm_src,     3'b100);
    check("AUIPC_pc_src",  pc_src,      1'b0);

    // miscellaneous
    opcode=7'b1111111; funct3=3'b000; branch_taken=0; #1;
    check("ILL_reg_wr",  reg_wr,      1'b0);
    check("ILL_mem_wr",  mem_wr,      1'b0);
    check("ILL_pc_src",  pc_src,      1'b0);
    check("ILL_jalr",    jalr,        1'b0);



    // summary
    if (errors == 0) $display("PASS: %0d checks", tests);
    else             $display("FAIL: %0d/%0d", errors, tests);
    $finish;
  end
endmodule
