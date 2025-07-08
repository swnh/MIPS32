module shift_to_msb_equ_1 (
    input   [23:0]  a,
    output  [23:0]  b,
    output  [4:0]   sa
);
    wire    [23:0]  a5, a4, a3, a2, a1, a0;
    assign          a5  = a;
    assign          sa[4]   = ~|a5[23:08];
    assign          a4  = sa[4] ? {a5[07:00],16'b0} : a5;
    assign          sa[3]   = ~|a4[23:16];
    assign          a3  = sa[3] ? {a4[15:00], 8'b0} : a4;
    assign          sa[2]   = ~|a3[23:20];
    assign          a2  = sa[2] ? {a3[19:00], 4'b0} : a3;
    assign          sa[1]   = ~|a2[23:22];
    assign          a1  = sa[1] ? {a2[21:00], 2'b0} : a2;
    assign          sa[0]   = ~a1[23];
    assign          a0  = sa[0] ? {a1[22:00], 1'b0} : a1;
    assign          b   = a0;  
endmodule