module regfile2w (
    input   [31:0]  dx, dy,
    input   [4:0]   rna, rnb, wnx, wny,
    input           wex, wey,
    input           clk, clrn,
    output  [31:0]  qa, qb
);
    reg     [31:0]  register [0:31];
    assign          qa  = register[rna];
    assign          qb  = register[rnb];

    integer i;
    always @(posedge clk or negedge clrn) begin
        if (!clrn) begin 
            for (i=0; i<32; i=i+1)
                register[i] <= 0;
        end else begin 
            if (wey) // write port y has a higher priority
                register[wny] <= dy;
            if (wex && ( !wey || (wnx != wny) ))
                register[wnx] <= dx;
        end
    end
endmodule