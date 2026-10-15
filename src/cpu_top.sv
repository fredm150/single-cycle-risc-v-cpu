module cpu_top (
    input  logic clk,
    input  logic reset
);

    logic [31:0] pc, instr, rd_data;
    logic [31:0] alu_result, wr_data;
    logic        mem_wr, pc_src, alu_src, reg_wr, branch_taken;
    logic [2:0]  res_src, imm_src;
    logic [3:0]  alu_control;
    logic jalr;

    logic [31:0] store_data;
    logic [3:0]  byte_en;

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
        .store_data(store_data),
        .byte_en    (byte_en),
        .jalr           (jalr),
        .data_out   (pc),          
        .Instr      (instr),       
        .alu_result (alu_result),  
        .wr_data    (wr_data),     
        .rd_data    (rd_data)
    );

    // instantiate data memory
    dmem dmem (
        .clk        (clk),
        .mem_wr  (mem_wr),
        .byte_en(byte_en),
        .addr       (alu_result),
        .wr_data (store_data),
        .read_data  (rd_data)
    );

endmodule