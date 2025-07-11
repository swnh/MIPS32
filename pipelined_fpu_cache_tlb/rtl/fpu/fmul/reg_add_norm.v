module reg_add_norm (
    input       [47:0]  a_z48,
    input       [22:0]  a_inf_nan_frac,
    input       [9:0]   a_exp10,
    input       [1:0]   a_rm,
    input               a_sign,
    input               a_is_nan,
    input               a_is_inf,
    input               e,
    input               clk, clrn,
    output  reg [47:0]  n_z48,
    output  reg [22:0]  n_inf_nan_frac,
    output  reg [9:0]   n_exp10,
    output  reg [1:0]   n_rm,
    output  reg         n_sign,
    output  reg         n_is_nan,
    output  reg         n_is_inf
);
    always @(posedge clk or negedge clrn) begin 
        if (!clrn) begin 
            n_rm            <= 0;
            n_sign          <= 0;
            n_exp10         <= 0;
            n_is_nan        <= 0;
            n_is_inf        <= 0;
            n_inf_nan_frac  <= 0;
            n_z48           <= 0;
        end else if (e) begin
            n_rm            <= a_rm;
            n_sign          <= a_sign;
            n_exp10         <= a_exp10;
            n_is_nan        <= a_is_nan;
            n_is_inf        <= a_is_inf;
            n_inf_nan_frac  <= a_inf_nan_frac;
            n_z48           <= a_z48;
        end
    end
endmodule