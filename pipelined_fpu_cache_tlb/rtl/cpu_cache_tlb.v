module cpu_cache_tlb (
    input               clk,
    input               memclk,
    input               clrn,
    input       [31:0]  mem_data,
    input               mem_ready,
    output      [31:0]  v_pc,
    output      [31:0]  pc,
    output      [31:0]  inst,
    output      [31:0]  ealu,
    output      [31:0]  malu,
    output      [31:0]  wdi,
    output      [31:0]  wd,
    output      [31:0]  mem_a,
    output      [31:0]  mem_st_data,
    output      [4:0]   wn,
    output              ww,
    output              stall_lw,
    output              stall_fp,
    output              stall_lwc1,
    output              stall_swc1,
    output              stall,
    output              mem_access,
    output              mem_write,
    output              io
);
    wire        [31:0]  e3d;
    wire        [31:0]  qfa, qfb, fa, fb, dfa, dfb;
    wire        [31:0]  mmo, wmo;
    wire        [4:0]   count_div, count_sqrt;
    wire        [4:0]   e1n, e2n, e3n, wrn, fs, ft, fd;
    wire        [2:0]   fc;
    wire        [1:0]   e1c, e2c, e3c;
    wire                fwdla, fwdlb, fwdfa, fwdfb;
    wire                wf, fasmds, e1w, e2w, e3w, wwfpr;
    wire                no_cache_stall, dtlb;
//  wire                e;

    iu_cache_tlb    i_u (
        // input ports
        .clk(clk),              .clrn(clrn),
        .memclk(memclk),        .mem_data(mem_data),    .mem_ready(mem_ready),
        .dfb(dfb),              .e3d(e3d),
        .e1n(e1n),              .e2n(e2n),              .e3n(e3n),
        .e1w(e1w),              .e2w(e2w),              .e3w(e3w),
        .stall(stall),          .st(1'b0),
        // output ports
        .v_pc(v_pc),            .pc(pc),                .inst(inst),
        .ealu(ealu),            .malu(malu),
        .wdi(wdi),              .mmo(mmo),              .wmo(wmo),
        .mem_a(mem_a),          .mem_st_data(mem_st_data),
        .fs(fs),                .ft(ft),                .fd(fd),
        .fc(fc),                .wrn(wrn),
        .mem_access(mem_access),.mem_write(mem_write),
        .wwfpr(wwfpr),          .wf(wf),                .fasmds(fasmds),
        .fwdla(fwdla),          .fwdlb(fwdlb),
        .fwdfa(fwdfa),          .fwdfb(fwdfb),
        .stall_lw(stall_lw),    .stall_fp(stall_fp),
        .stall_lwc1(stall_lwc1),.stall_swc1(stall_swc1),
        .no_cache_stall(no_cache_stall),
        .dtlb(dtlb),            .io(io)               
    );
    regfile2w       fpr (
        // input ports
        .clk(~clk),             .clrn(clrn),
        .dx(wd),                .dy(wmo),
        .rna(fs),               .rnb(ft),
        .wnx(wn),               .wny(wrn),
        .wex(ww),               .wey(wwfpr),
        // output ports
        .qa(qfa),               .qb(qfb) 
    );
    mux2x32         fwd_f_load_a (qfa, mmo, fwdla, fa);
    mux2x32         fwd_f_load_b (qfb, mmo, fwdlb, fb);
    mux2x32         fwd_f_res_a (fa, e3d, fwdfa, dfa);
    mux2x32         fwd_f_res_b (fb, e3d, fwdfb, dfb);
    fpu             fp_unit (
        // input ports
        .clk(clk),              .clrn(clrn),
        .a(dfa),                .b(dfb),
        .fd(fd),                .fc(fc),                .wf(wf),
        .ein1(no_cache_stall),  .ein2(dtlb),
        // output ports
        .wd(wd),                .ed(e3d),
        .count_div(count_div),  .count_sqrt(count_sqrt),
        .e1n(e1n),              .e2n(e2n),              .e3n(e3n),
        .wn(wn),                .ww(ww),
        .e1c(e1c),              .e2c(e2c),              .e3c(e3c),
        .e1w(e1w),              .e2w(e2w),              .e3w(e3w),
        .st_ds(stall),          .e(e)
    );
endmodule