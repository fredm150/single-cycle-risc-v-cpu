`timescale 1ns/1ps



module alu #(parameter DATA_WIDTH = 32)
            (input  logic [DATA_WIDTH-1:0] A, B,
             input  logic [3:0] alu_control,
             output logic Zero,
             output logic [DATA_WIDTH-1:0] alu_result);
    import alu_ops_pkg::*;

    always_comb begin
        case (alu_control)
            ALU_ADD:  alu_result = A + B;
            ALU_SUB:  alu_result = A - B;
            ALU_AND:  alu_result = A & B;
            ALU_OR:   alu_result = A | B;
            ALU_XOR:  alu_result = A ^ B;
            ALU_SLTU: alu_result = (A < B) ? 32'd1 : 32'd0;
            ALU_SLT:  alu_result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;
            ALU_SLL:  alu_result = A << B[4:0];
            ALU_SRL:  alu_result = A >> B[4:0];
            ALU_SRA:  alu_result = $signed(A) >>> B[4:0];
            default:  alu_result = '0;
        endcase
    end

    assign Zero = (alu_result == '0);
endmodule

/*
module alu #(parameter DATA_WIDTH = 32) 

            (input logic [DATA_WIDTH-1:0] A, B,
            input logic [3:0] alu_control,
            output logic Zero,
            output logic [DATA_WIDTH-1:0] alu_result);



    // main mux
    always_comb begin
        case (alu_control)

        4'h0: alu_result = A + B;
        4'h1: alu_result = A - B;
        4'h2: alu_result = A & B;
        4'h3: alu_result = A | B;
        4'h4: alu_result = A ^ B;
        4'h5: alu_result = (A < B) ? 32'd1 : 32'd0;                 // SLTU  less than (unsigned)
        4'h6: alu_result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;      // when they're signed integers
        4'h7: alu_result = A << B[4:0];          // shift logical left
        4'h8: alu_result = A >> B [4:0];
        4'h9: alu_result = $signed(A) >>> B [4:0];       // shift right arithmetic
            default: alu_result = '0;
        endcase

        
    end

    // output zero falg for beq and bra
    assign Zero = (alu_result == '0);

    


    
endmodule
*/
