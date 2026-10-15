module control_unit (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic       funct7_5,
    input  logic       funct7_0,
    input  logic       branch_taken,
    output logic [2:0] res_src,
    output logic       mem_wr,
    output logic       pc_src,
    output logic       alu_src,
    output logic       reg_wr,
    output logic        jalr,
    output logic [2:0] imm_src,
    output logic [3:0] alu_control
);
    logic       branch;
    logic       jump;
    logic [1:0] ALU_op;

    main_decoder md (
        .opcode(opcode), 
        .reg_wr(reg_wr), 
        .alu_src(alu_src),
        .mem_wr(mem_wr), 
        .res_src(res_src), 
        .branch(branch),
        .imm_src(imm_src), 
        .ALU_op(ALU_op),
        .jump(jump),
        .jalr(jalr)
    );

    alu_decoder ad (
        .funct3(funct3),
        .funct7_5(funct7_5),
        .funct7_0(funct7_0),
        .op_b5(opcode[5]),
        .ALU_op(ALU_op), 
        .alu_control(alu_control)
    );

    assign pc_src = (branch & branch_taken) | jump;   // branch if equal or jump (unconditionally)
endmodule


// build amin decoder
module main_decoder (
    input  logic [6:0] opcode,
    output logic       reg_wr,
    output logic       alu_src,
    output logic       mem_wr,
    output logic [2:0] res_src,
    output logic       branch,
    output logic       jump,        // added jump instruction
    output logic       jalr,        // added jump and link register instruction
    output logic [2:0] imm_src,
    output logic [1:0] ALU_op
);

    // set local parameters for the opcode matching
    localparam logic [6:0] load   = 7'b0000011;
    localparam logic [6:0] store  = 7'b0100011;
    localparam logic [6:0] r_type = 7'b0110011;
    localparam logic [6:0] i_alu = 7'b0010011;             // oopcode for immediates e.g addi, xori, slli, slri, etc
    localparam logic [6:0] OP_BRANCH = 7'b1100011;
    localparam logic [6:0] jal       = 7'b1101111;         // opcode for jump and link
    localparam logic [6:0] jalr_op   = 7'b1100111;   
    localparam logic [6:0] lui       = 7'b0110111;   
    localparam logic [6:0] auipc     = 7'b0010111;   

    always_comb begin

        // set everything to zero in the beginning
        reg_wr  = 1'b0;
        alu_src = 1'b0;
        mem_wr  = 1'b0;
        res_src = 3'b0;
        branch  = 1'b0;
        imm_src = 3'b000;
        ALU_op  = 2'b00;
        jump  = 1'b0;
        jalr = 1'b0;
        // i_alu  nvm 

        casez (opcode)
            load: begin
                reg_wr  = 1'b1;
                alu_src = 1'b1;
                mem_wr  = 1'b0;
                res_src = 3'b1;
                branch  = 1'b0;
                imm_src = 3'b0; // I-type immediate
                ALU_op  = 2'b00;
            end
            
            store: begin
                reg_wr  = 1'b0;
                alu_src = 1'b1;
                mem_wr  = 1'b1;
                res_src = 3'bxxx;
                branch  = 1'b0;
                imm_src = 3'b001; // S-type immediate
                ALU_op  = 2'b00;
            end
            
            r_type: begin
                reg_wr  = 1'b1;
                alu_src = 1'b0;
                mem_wr  = 1'b0;
                res_src = 3'b0;
                branch  = 1'b0;
                imm_src = 3'bxxx; // No immediate used
                ALU_op  = 2'b10;
            end

            i_alu: begin                 // I-type ALU: addi, slti, xori, slli, ...
                reg_wr  = 1'b1;
                alu_src = 1'b1;          // operand B is the immediate
                mem_wr  = 1'b0;
                res_src = 3'b0;         // writeback = ALU result
                branch  = 1'b0;
                imm_src = 3'b0;          // I-type immediate
                ALU_op  = 2'b10;         // decode from funct3
            end
            
            OP_BRANCH: begin
                reg_wr  = 1'b0;
                alu_src = 1'b0;
                mem_wr  = 1'b0;
                res_src = 2'bxx;
                branch  = 1'b1;
                imm_src = 3'b010;       // B-type immediate
                ALU_op  = 2'b01;
            end

            jal: begin
                reg_wr  = 1'b1;     // write the link register
                res_src = 3'b10;    // writeback = PC+4
                imm_src = 3'b011;   // J-type immediate
                jump    = 1'b1;     // unconditional jump
            end

            jalr_op: begin                 
                reg_wr = 1'b1; 
                alu_src = 1'b1;
                res_src = 3'b10;          
                imm_src = 3'b0;          
                ALU_op = 2'b00;            // ALU does rs1 + imm (the target)
                jump = 1'b1; 
                jalr = 1'b1;
            end

            lui: begin                     
                reg_wr = 1'b1;
                res_src = 3'b011;          
                imm_src = 3'b100;          
            end

            auipc: begin                   
                reg_wr = 1'b1;
                res_src = 3'b100;          
                imm_src = 3'b100;         
            end
            
            default: begin
                reg_wr  = 1'b0;
                alu_src = 1'b0;
                mem_wr  = 1'b0;
                res_src = 2'b00;
                branch  = 1'b0;
                imm_src = 3'b000;
                ALU_op  = 2'b00;
                jump  = 1'b0;
                jalr = 1'b0;

            end
        endcase
    end
endmodule



module alu_decoder (
    input  logic [2:0] funct3,
    input  logic funct7_5,
    input logic funct7_0,
    input logic op_b5,
    input  logic [1:0] ALU_op,
    output logic [3:0] alu_control
);
    import alu_ops_pkg::*;

    logic rtype_sub;
    logic is_mul;
    assign rtype_sub = funct7_5 & op_b5;
    assign is_mul = funct7_0 & op_b5;       // multiply extension

    always_comb begin
        alu_control = ALU_ADD;          // default

        case (ALU_op)
            2'b00: alu_control = ALU_ADD;   // loads/stores: address add
            2'b01: alu_control = ALU_SUB;   // branches: subtract for compare
            2'b10: begin                    // R-type
                if (is_mul) begin
                    case (funct3)
                        3'b000: alu_control = ALU_MUL;
                        3'b001: alu_control = ALU_MULH;
                        3'b010: alu_control = ALU_MULHSU;
                        3'b011: alu_control = ALU_MULHU;
                        default: alu_control = ALU_ADD;
                    endcase
                end else begin
                    case (funct3)
                            3'b000: alu_control = rtype_sub ? ALU_SUB : ALU_ADD;
                            3'b001: alu_control = ALU_SLL;
                            3'b010: alu_control = ALU_SLT;
                            3'b011: alu_control = ALU_SLTU;
                            3'b100: alu_control = ALU_XOR;
                            3'b101: alu_control = funct7_5 ? ALU_SRA : ALU_SRL;
                            3'b110: alu_control = ALU_OR;
                            3'b111: alu_control = ALU_AND;
                            default: alu_control = ALU_ADD;
                    endcase
                end
            end
            default: alu_control = ALU_ADD;
        endcase
    end
endmodule








/*
module alu_decoder (
    input  logic [2:0] func3,
    input  logic [6:0] func7, // Must be [6:0] so func7[5] is valid
    input  logic [1:0] ALU_op,
    output logic [3:0] alu_control
);

    always_comb begin
        // Default control output
        alu_control = 3'b000;

        casez (ALU_op)
            2'b00: alu_control = 3'b000; // Addition for loads/stores (lw, sw)
            2'b01: alu_control = 3'b001; // Subtraction for branches (beq)
            2'b10: begin                 // R-type instructions
                casez (func3)
                    3'b000: begin
                        // Check func7[5] to separate ADD from SUB
                        if (func7[5]) 
                            alu_control = 3'b001; // SUB
                        else          
                            alu_control = 3'b000; // ADD
                    end
                    3'b010: alu_control = 3'b101; // SLT (Set Less Than)
                    3'b110: alu_control = 3'b011; // OR
                    3'b111: alu_control = 3'b010; // AND
                    default: alu_control = 3'b000;
                endcase
            end
            default: alu_control = 3'b000;
        endcase
    end
endmodule
*/