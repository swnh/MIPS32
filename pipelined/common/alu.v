module alu (
    input   [31:0]  a, b,
    input   [03:0]  aluc,
    output  [31:0]  r,
    output          z
); 
    reg     [31:0]  r;
    always @(*) begin
        casex (aluc)
            4'bx000: r = a + b;                  // add
            4'bx100: r = a - b;                  // sub
            4'bx001: r = a & b;                  // and
            4'bx101: r = a | b;                  // or
            4'bx010: r = a ^ b;                  // xor
            4'bx110: r = {b[15:0], 16'h0};       // lui
            4'b0011: r = b << a[4:0];            // sll
            4'b0111: r = b >> a[4:0];            // srl
            4'b1111: r = $signed(b) >>> a[4:0];  // sra
        endcase
    end
    assign z  = ~|r;
endmodule