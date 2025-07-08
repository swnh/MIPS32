module pipelined_fadder (
    input           clk, clrn,
    input   [31:0]  a, b,
    input   [1:0]   rm,
    input           sub,
    input           e,
    output  [31:0]  s
);
    wire    [26:0]  a_small_frac;
    wire    [23:0]  a_large_frac;
    wire    [22:0]  a_inf_nan_frac;
    wire    [7:0]   a_exp;
    wire            a_is_nan, a_is_inf;
    wire            a_sign;
    wire            a_op_sub;

    // exe1: alignment stage
    fadd_align      alignment (
        .a(a),
        .b(b),
        .sub(sub),
        .s_is_nan(a_is_nan),
        .s_is_inf(a_is_inf),
        .inf_nan_frac(a_inf_nan_frac),
        .sign(a_sign),
        .temp_exp(a_exp),
        .op_sub(a_op_sub),
        .large_frac24(a_large_frac),
        .small_frac27(a_small_frac)
    );
    wire    [26:0]  c_small_frac;
    wire    [23:0]  c_large_frac;
    wire    [22:0]  c_inf_nan_frac;
    wire    [7:0]   c_exp;
    wire    [1:0]   c_rm;
    wire            c_is_nan, c_is_inf;
    wire            c_sign;
    wire            c_op_sub;
    // pipelined registers
    reg_align_cal   reg_ac (
        .a_small_frac(a_small_frac),
        .a_large_frac(a_large_frac),
        .a_inf_nan_frac(a_inf_nan_frac),
        .a_exp(a_exp),
        .a_rm(rm),
        .a_is_nan(a_is_nan),
        .a_is_inf(a_is_inf),
        .a_sign(a_sign),
        .a_op_sub(a_op_sub),
        .e(e),
        .clk(clk),
        .clrn(clrn),

        .c_small_frac(c_small_frac),
        .c_large_frac(c_large_frac),
        .c_inf_nan_frac(c_inf_nan_frac),
        .c_exp(c_exp),
        .c_rm(c_rm),
        .c_is_nan(c_is_nan),
        .c_is_inf(c_is_inf),
        .c_sign(c_sign),
        .c_op_sub(c_op_sub)
    );
    wire    [27:0]  c_frac;

    // exe2: calculation stage
    fadd_cal        calculation (
        .large_frac24(c_large_frac),
        .op_sub(c_op_sub),
        .small_frac27(c_small_frac),
        .cal_frac(c_frac)
    );
    wire    [27:0]  n_frac;
    wire    [22:0]  n_inf_nan_frac;
    wire    [7:0]   n_exp;
    wire    [1:0]   n_rm;
    wire            n_is_nan, n_is_inf;
    wire            n_sign;
    // pipelined registers
    reg_cal_norm    reg_cn (
        .c_frac(c_frac),
        .c_inf_nan_frac(c_inf_nan_frac),
        .c_exp(c_exp),
        .c_rm(c_rm),
        .c_is_nan(c_is_nan),
        .c_is_inf(c_is_inf),
        .c_sign(c_sign),
        .e(e),
        .clk(clk),
        .clrn(clrn),

        .n_frac(n_frac),
        .n_inf_nan_frac(n_inf_nan_frac),
        .n_exp(n_exp),
        .n_rm(n_rm),
        .n_is_nan(n_is_nan),
        .n_is_inf(n_is_inf),
        .n_sign(n_sign)
    );

    // exe3: normalization stage
    fadd_norm       normalization (
        .cal_frac(n_frac),
        .inf_nan_frac(n_inf_nan_frac),
        .temp_exp(n_exp),
        .rm(n_rm),
        .is_nan(n_is_nan),
        .is_inf(n_is_inf),
        .sign(n_sign),
        .s(s)
    );
endmodule