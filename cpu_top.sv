module cpu_top (
    input  logic clk,
    input  logic reset
);

    logic [31:0] pc, instr, rd_data;
    logic [31:0] alu_result, wr_data;
    logic        mem_wr, pc_src, alu_src, reg_wr, branch_taken;
    logic [2:0]  res_src, imm_src;
    logic [2:0]  alu_control;

    // instantiate instruction memory
    instr_memory imem (
        .addr(pc),
        .instr(instr)
    );

    // instantiate control unit
    control_unit ctrl (
        .opcode     (instr[6:0]),
        .funct3     (instr[14:12]),
        .funct7_5   (instr[30]),
        .funct7_0   (instr[25]),
        .branch_taken  (branch_taken),
        .res_src    (res_src),
        .jalr       (jalr),
        .mem_wr     (mem_wr),
        .pc_src     (pc_src),
        .alu_src    (alu_src),
        .reg_wr     (reg_wr),
        .imm_src    (imm_src),
        .alu_control(alu_control)
    );

    // instantiate datapath
    datapath dp (
        .clk        (clk),
        .reset      (reset),
        .res_src    (res_src),
        .pc_src     (pc_src),
        .alu_src    (alu_src),
        .reg_wr     (reg_wr),
        .imm_src    (imm_src),
        .alu_control(alu_control),
        .branch_taken   (branch_taken),
        .jalr           (jalr),
        .data_out   (pc),          // Connects your PC register output back to Instruction Memory
        .Instr      (instr),       // Feeds the instruction into the datapath (for imm_gen and register slicing)
        .alu_result (alu_result),  // Acts as the address for Data Memory
        .wr_data    (wr_data),     // Acts as the store data for Data Memory
        .rd_data    (rd_data)      // Receives loaded data back from Data Memory
    );

    // instantiate data memory
    data_mem dmem (
        .clk        (clk),
        .mem_write  (mem_wr),
        .addr       (alu_result),
        .write_data (wr_data),
        .read_data  (rd_data)
    );

endmodule