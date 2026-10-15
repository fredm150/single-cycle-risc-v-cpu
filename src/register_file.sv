module reg_file (
    input  logic        clk,
    input  logic        rst,          // Added reset
    input  logic        wr_enable, 
    input  logic [4:0]  reg_1,
    input  logic [4:0]  reg_2,
    input  logic [4:0]  reg_d,
    input  logic [31:0] wr_data,
    output logic [31:0] read_data1, 
    output logic [31:0] read_data2
);
    
    // 32 registers, each 32 bits wide
    logic [31:0] registers [31:0]; 

    // asynchronous read ports (hardwire x0 to zero)
    assign read_data1 = (reg_1 == 5'b00000) ? 32'd0 : registers[reg_1];
    assign read_data2 = (reg_2 == 5'b00000) ? 32'd0 : registers[reg_2];

    // synchronous write and reset logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < 32; i++) begin
                registers[i] <= 32'd0;
            end
        end else if (wr_enable && (reg_d != 5'b00000)) begin
            registers[reg_d] <= wr_data;
        end
    end

endmodule


/* module reg_file (
    input logic [4:0] reg_1,
    input logic clk,
    input logic wr_enable, 
    input logic [4:0] reg_2,
    input logic [4:0] reg_d,
    input logic [31:0] wr_data,
    output logic [31:0] read_data1, read_data2
);
    
    logic [31:0] registers [31:0];           // unpacked arrays. 32 registers and each of them is 32 bits

    assign read_data1 = (reg_1 == ZERO) ? 32'd0 : registers[reg_1];      // assign reg_1 to read_data1
    assign read_data2 = (reg_2 == ZERO) ? 32'd0 : registers[reg_2];      // assign reg_2 to read_data2


    // write logic
    always_ff @(posedge clk ) begin

        if (wr_enable && (reg_d != 5'b0)) begin
            registers[reg_d] <= wr_data;
        end
        
    end

    // set x0 to 32'h0000000 (I'll write that code later)
    assign ZERO  = 32'd0;


endmodule

*/

/*
module reg_file (
    input  logic        clk,
    input  logic        rst,          // Added reset
    input  logic        wr_enable, 
    input  logic [4:0]  reg_1,
    input  logic [4:0]  reg_2,
    input  logic [4:0]  reg_d,
    input  logic [31:0] wr_data,
    output logic [31:0] read_data1, 
    output logic [31:0] read_data2
);
    
    // 32 registers, each 32 bits wide
    logic [31:0] registers [31:0]; 

    // Asynchronous read ports (hardwire x0 to zero)
    assign read_data1 = (reg_1 == 5'b00000) ? 32'd0 : registers[reg_1];
    assign read_data2 = (reg_2 == 5'b00000) ? 32'd0 : registers[reg_2];

    // Synchronous write and reset logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < 32; i++) begin
                registers[i] <= 32'd0;
            end
        end else if (wr_enable && (reg_d != 5'b00000)) begin
            registers[reg_d] <= wr_data;
        end
    end

endmodule
*/

