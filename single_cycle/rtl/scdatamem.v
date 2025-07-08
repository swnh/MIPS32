module scdatamem (clk, dataout, datain, addr, we);  // data memory, ram
    input           clk;                            // clock
    input           we;                             // write enable
    input   [31:0]  datain;                         // data in (to memory)
    input   [31:0]  addr;                           // ram address
    output  [31:0]  dataout;                        // data out (from memory)
    reg     [31:0]  ram [0:31];                     // ram cells: 32 words * 32 bits

    assign dataout = ram[addr[6:2]];                // use word address to read ram ???

    always @(posedge clk) begin
        if (we) begin
            ram[addr[6:2]] = datain;                // use word address to write ram
        end
    end

    integer i;
    initial begin 
        for (i = 0; i < 32; i = i + 1) begin 
            ram[i] = 0;
        end
        // ram[word_addr] = data                    // (byte_addr) item in data array
        ram[5'h14] = 32'h0000_00a3;                 // (50) data[0]   0 +  a3 =  a3
        ram[5'h15] = 32'h0000_0027;                 // (54) data[1]  a3 +  27 =  ca
        ram[5'h16] = 32'h0000_0079;                 // (58) data[2]  ca +  79 = 143
        ram[5'h17] = 32'h0000_0115;                 // (5c) data[3] 143 + 115 = 258
        // ram[5'h18] should be 0x0000_0258, the sum stored by sw instrucion
    end
endmodule