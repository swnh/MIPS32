// pipelined cpu with fpu, inst mem, and data mem
module fpu_1_iu (
    input           clk, memclk, clrn,
    output  [31:0]  pc, inst, ealu, malu, walu,
    output  [31:0]  e3d, wd,
    output  [4:0]   e1n, e2n, e3n, wn,
    output          ww, stl_lw, stl_fp, stl_lwc1, stl_swc1, stl,
    output          e,
    output  [4:0]   cnt_div, cnt_sqrt // for testing
);
    wire    [31:0]  qfa, qfb, fa, fb, dfa, dfb, mmo, wmo;
    wire    [4:0]   fs, ft, fd, wrn;
    wire    [2:0]   fc;
    wire    [1:0]   e1c, e2c, e3c;
    wire            fwdla, fwdlb, fwdfa, fwdfb, wf, fasmds;
    wire            e1w, e2w, e3w;
    wire            wwfpr;

    iu              i_u (
        // input ports
        .clk(clk),              .clrn(clrn),            .memclk(memclk),
        .dfb(dfb),              .e3d(e3d),              
        .e1n(e1n),              .e2n(e2n),              .e3n(e3n),
        .e1w(e1w),              .e2w(e2w),              .e3w(e3w),
        .stall(stl),            .st(1'b0),
        // output ports
        .pc(pc),                .inst(inst),
        .ealu(ealu),            .malu(malu),            .walu(walu),
        .mmo(mmo),              .wmo(wmo),
        .fs(fs),                .ft(ft),                .fc(fc),
        .fd(fd),                .wrn(wrn),
        .wwfpr(wwfpr),          .fwdla(fwdla),          .fwdlb(fwdlb),
        .wf(wf),                .fwdfa(fwdfa),          .fwdfb(fwdfb),
        .fasmds(fasmds),        
        .stall_lw(stl_lw),      .stall_fp(stl_fp),
        .stall_lwc1(stl_lwc1),  .stall_swc1(stl_swc1)
    
    );
    regfile2w       fpr (
        // input ports
        .clk(~clk),             .clrn(clrn),
        .dx(wd),                .dy(wmo),
        .rna(fs),               .rnb(ft),
        .wnx(wn),               .wny(wrn),
        .wex(ww),               .wey(wwfpr),
        // output ports
        .qa(qfa),                .qb(qfb)
    );
    mux2x32         fwd_f_load_a (qfa, mmo, fwdla, fa);
    mux2x32         fwd_f_load_b (qfb, mmo, fwdlb, fb);
    mux2x32         fwd_f_res_a (fa, e3d, fwdfa, dfa);
    mux2x32         fwd_f_res_b (fb, e3d, fwdfb, dfb);
    fpu             fp_unit (
        // input ports
        .clk(clk),              .clrn(clrn),
        .a(dfa),                .b(dfb),
        .fd(fd),                .fc(fc),
        .wf(wf),                .ein1(1'b1),            .ein2(1'b1),
        // output ports
        .ed(e3d),               .wd(wd),                .wn(wn),
        .count_div(cnt_div),    .count_sqrt(cnt_sqrt),
        .e1n(e1n),              .e2n(e2n),              .e3n(e3n),
        .e1c(e1c),              .e2c(e2c),              .e3c(e3c),
        .e1w(e1w),              .e2w(e2w),              .e3w(e3w),
        .ww(ww),                .st_ds(stl),            .e(e)
    );
endmodule