module fmul_add (
    input   [39:0]  z_sum,
    input   [39:0]  z_carry,
    output  [47:8]  z
);
    assign          z   = z_sum + z_carry;
endmodule