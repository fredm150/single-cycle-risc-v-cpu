module instr_memory (
    input  logic [31:0] addr,   
    output logic [31:0] instr);

    // internal memory array (64 words each 32 bits)
    logic [31:0] RAM[0:63];

    // load test program into internal ram
    initial
        $readmemh("program.txt", RAM);
    

    // instruction lookup using address
    assign instr = RAM[addr[31:2]];

endmodule