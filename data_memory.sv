module dmem (
    input  logic        clk,
    input  logic        mem_wr,    
    input  logic [3:0]  byte_en,       
    input  logic [31:0] addr,     // address from ALUResult
    input  logic [31:0] wr_data,    
    output logic [31:0] read_data     
);
    logic [31:0] RAM[63:0];
    assign read_data = RAM[addr[31:2]];     // full word store

    // write
    always_ff @(posedge clk) begin
        if (mem_write) begin
            if (byte_en[0]) RAM[addr[31:2]][7:0]   <= write_data[7:0];
            if (byte_en[1]) RAM[addr[31:2]][15:8]  <= write_data[15:8];
            if (byte_en[2]) RAM[addr[31:2]][23:16] <= write_data[23:16];
            if (byte_en[3]) RAM[addr[31:2]][31:24] <= write_data[31:24];
        end
    end

   
endmodule