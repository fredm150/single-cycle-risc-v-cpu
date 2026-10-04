module datapath (
    input  logic        clk, reset,
    input  logic [2:0]  res_src,          
    input  logic        pc_src,           
    input  logic        alu_src,          
    input  logic        reg_wr,           
    input  logic [2:0]  imm_src,          
    input  logic [3:0]  alu_control,      
    input  logic         jalr,
    output logic        branch_taken,     // check if branch was taken
    output logic [31:0] data_out,         
    input  logic [31:0] Instr,            
    output logic [31:0] alu_result,       
    output logic [31:0] wr_data,          
    input  logic [31:0] rd_data           
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
        .rst        (reset),
        .wr_enable  (reg_wr),
        .reg_1      (Instr[19:15]),
        .reg_2      (Instr[24:20]),
        .reg_d      (Instr[11:7]),
        .wr_data    (Result),
        .read_data1 (src_A),
        .read_data2 (wr_data)
    );

    imm_gen imm_generator_module (Instr, imm_src, imm_ext);

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


