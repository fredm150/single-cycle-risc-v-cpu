module PC #(parameter WIDTH = 32)
    
    (input logic [WIDTH-1:0] pc_next,
    input clk,
    input logic wr_enable,
    input logic reset,
    output logic [WIDTH-1:0] data_out);


    // write operation
    always_ff @(posedge clk) begin
        if (reset) begin
            data_out <= '0;
            
        end else if (wr_enable) begin
            data_out <= pc_next;
        end
    end

endmodule

