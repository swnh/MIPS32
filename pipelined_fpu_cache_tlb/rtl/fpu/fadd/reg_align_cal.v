module reg_align_cal (
    input           [26:0]  a_small_frac,
    input           [23:0]  a_large_frac,
    input           [22:0]  a_inf_nan_frac,
    input           [7:0]   a_exp,
    input           [1:0]   a_rm,
    input                   a_is_nan, a_is_inf, a_sign, a_op_sub,
    input                   e,
    input                   clk, clrn,
    output  reg     [26:0]  c_small_frac,
    output  reg     [23:0]  c_large_frac,
    output  reg     [22:0]  c_inf_nan_frac,
    output  reg     [7:0]   c_exp,
    output  reg     [1:0]   c_rm,
    output  reg             c_is_nan, c_is_inf, c_sign, c_op_sub
);
    always @(posedge clk or negedge clrn) begin 
        if (!clrn) begin 
            c_rm            <= 0;
            c_is_nan        <= 0;
            c_is_inf        <= 0;
            c_inf_nan_frac  <= 0;
            c_sign          <= 0;
            c_exp           <= 0;
            c_op_sub        <= 0;
            c_large_frac    <= 0;
            c_small_frac    <= 0;
        end else if (e) begin 
            c_rm            <= a_rm;
            c_is_nan        <= a_is_nan;
            c_is_inf        <= a_is_inf;
            c_inf_nan_frac  <= a_inf_nan_frac;
            c_sign          <= a_sign;
            c_exp           <= a_exp;
            c_op_sub        <= a_op_sub;
            c_large_frac    <= a_large_frac;
            c_small_frac    <= a_small_frac;
        end
    end
endmodule