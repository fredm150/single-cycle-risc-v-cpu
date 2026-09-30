module datapath (
    input  logic        clk, reset,
    input  logic [2:0]  res_src,          // Writeback source control
    input  logic        pc_src,           // PC multiplexer control
    input  logic        alu_src,          // ALU source B control
    input  logic        reg_wr,           // Register file write enable
    input  logic [1:0]  imm_src,          // Immediate extension select
    input  logic [2:0]  alu_control,      // ALU operation control
    input  logic         jalr,
    output logic        branch_taken,     // check ifbranch was taken
    output logic [31:0] data_out,         // PC address output (to Instruction Memory)
    input  logic [31:0] Instr,            // Instruction input (from Instruction Memory)
    output logic [31:0] alu_result,       // ALU output (acts as Data Memory address)
    output logic [31:0] wr_data,          // Register Data 2 output (acts as Data Memory store data)
    input  logic [31:0] rd_data           // Data Memory read data input
);

    logic [31:0] pc_next, pc_plus4, pc_target;
    logic [31:0] imm_ext;
    logic [31:0] src_A; 
    logic [31:0] src_B;
    logic [31:0] Result;
    logic [2:0] funct3;
    logic alu_zero;         // alu zero flag 
    logic [31:0] jump_target;

    assign funct3 = Instr[14:12];

    always_comb begin
    case (funct3)
        3'b000: branch_taken = (src_A == src_B);                    // beq
        3'b001: branch_taken = (src_A != src_B);                    // bne
        3'b100: branch_taken = ($signed(src_A) <  $signed(src_B));  // blt
        3'b101: branch_taken = ($signed(src_A) >= $signed(src_B));  // bge
        3'b110: branch_taken = (src_A <  src_B);                    // bltu
        3'b111: branch_taken = (src_A >= src_B);                    // bgeu
        default: branch_taken = 1'b0;
    endcase
    end

    // Fetch Loop: Program Counter & Target Adders
    PC #(32) pc_module (
        .pc_next   (pc_next),
        .clk       (clk),
        .wr_enable (1'b1),
        .reset     (reset),
        .data_out  (data_out)
    );

    assign pc_plus4 = data_out + 32'd4;
    assign pc_target = data_out + imm_ext;

    // jump target
    assign jump_target = jalr ? {alu_result[31:1], 1'b0} : pc_target;

    assign pc_next = pc_src ? jump_target : pc_plus4;




    // Decode Loop: Register File & Immediate Extender
    reg_file rf (
        .clk        (clk),
        .rst        (rst),
        .wr_enable  (reg_wr),
        .reg_1      (Instr[19:15]),
        .reg_2      (Instr[24:20]),
        .reg_d      (Instr[11:7]),
        .wr_data    (Result),
        .read_data1 (src_A),
        .read_data2 (wr_data)
    );

    imm_gen imm_generator_module (Instr[31:7], imm_src, imm_ext);

    // Execute Loop: ALU Source Mux & ALU
    assign src_B = alu_src ? imm_ext : wr_data;

    // mux2 #(32) src_b_mux (wr_data, imm_ext, alu_src, src_B);

    // instantiate the ALU
    alu alu_module (
        .A              (src_A),
        .B              (src_B),
        .alu_control    (alu_control),
        .Zero           (alu_zero),
        .alu_result     (alu_result)
    );

    // writeback loop using the result multiplexer
    assign Result = (res_src == 3'b000) ? alu_result :   
                    (res_src == 3'b001) ? rd_data    :  
                    (res_src == 3'b010) ? pc_plus4   :   // jal/jalr link
                    (res_src == 3'b011) ? imm_ext    :   // lui
                                          pc_target;     // auipc


endmodule



/*
module datapath(input logic clk, reset,
        input logic [1:0] res_src,          // control signal
        input logic pc_src, alu_src,        // both are control signals
        input logic reg_wr,
        input logic [1:0] imm_src,
        input logic [2:0] alu_control,
        output logic branch_taken,      // checking whether a branch was taken
        output logic [31:0] data_out,       // represents data coming out of PC
        input logic [31:0] Instr,           // coming out of instruction memory
        output logic [31:0] alu_result, wr_data,
        input logic [31:0] rd_data
);


        logic [31:0] pc_next, pc_plus4, pc_target;
        logic [31:0] imm_ext;
        logic [31:0] src_A; 
        logic [31:0] src_B;
        logic [31:0] Result;
        logic alu_zero;         // zero flag from the alu

        assign funct3 = Instr[14:12];

        // next PC logic
        PC #(32) pc(clk, reset, pc_next, data_out);

        // increment pc after instruction
        adder pcadd4(data_out, 32'd4, pc_plus4);

        // increment pc for branch instructions
        adder pcaddbranch(data_out, imm_ext, pc_target);
        
        // mux that chooses b/n updating pc for normal instruction or branch i think?
        mux2 #(32) pcmux(pc_plus4, pc_target, pc_src, pc_next);


        // register file logic
        reg_file rf(clk, reg_wr, Instr[19:15], Instr[24:20], Instr[11:7], Result, src_A, wr_data);
        extend ext(Instr[31:7], imm_src, imm_ext);


        // alu logic
        mux2 #(32) src_b_mux(wr_data, imm_ext, alu_src, src_b);     // chooses between src_B and immediate extender
        alu alu(src_A, src_B, alu_control, alu_result, Zero);
        mux3 #(32) resultmux(alu_result, rd_data, pc_plus4, res_src, Result);


endmodule
*/

