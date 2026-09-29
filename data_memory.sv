module dmem (
    input  logic        clk,
    input  logic        mem_wr,    // write_enable (from control unit MemWrite)
    input  logic [31:0] addr,     // address from ALUResult
    input  logic [31:0] wr_data,    // write data
    output logic [31:0] read_data     // read data
);
    logic [31:0] RAM[63:0];

    // read
    assign read_data = RAM[addr[31:2]];

    // write
    always_ff @(posedge clk) begin
        if (mem_wr) begin
            RAM[addr[31:2]] <= wr_data;     // write data from the address at the internal ram memory
        end
    end

   
endmodule