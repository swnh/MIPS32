module iu (
    input               clk, memclk, clrn,
    input       [31:0]  dfb, e3d,
    input        [4:0]  e1n, e2n, e3n,
    input               e1w, e2w, e3w, stall, st,
    output  reg [31:0]  pc, inst, malu, walu,
    output      [31:0]  ealu,
    output      [31:0]  mmo,
    output  reg [31:0]  wmo,
    output       [4:0]  fs, ft, fd, 
    output  reg  [4:0]  wrn,
    output       [2:0]  fc,
    output  reg         wwfpr,
    output              fwdla, fwdlb, fwdfa, fwdfb, wf, fasmds,
    output              stall_lw, stall_fp, stall_lwc1, stall_swc1
);
    wire    [31:0]  bpc, jpc, npc, pc4, ins; 
    reg     [31:0]  dpc4;
    wire    [31:0]  qa, qb, da, db, dimm, dc, dd;
    wire    [31:0]  simm, epc8, alua, alub, ealu0; 
    wire    [31:0]  sa, eb, wdi;
    wire     [5:0]  op, func;
    wire     [4:0]  rs, rt, rd, drn, ern;
    wire     [3:0]  aluc;
    wire     [1:0]  pcsrc, fwda, fwdb;
    wire            wpcir, wreg, m2reg, wmem, aluimm, shift, jal, z;
    reg             ewfpr, ewreg, em2reg, ewmem, ejal, efwdfe, ealuimm, eshift;
    reg             mwfpr, mwreg, mm2reg, mwmem;
    reg             wwpfr, wwreg, wm2reg;
    reg     [31:0]  epc4, ea, ed, eimm, mb;
    reg      [4:0]  ern0, mrn;
    reg      [3:0]  ealuc;
//  cla32           pc_plus4 (pc, 32'h4, 1'b0, pc4);
    assign          pc4     = pc + 32'h4;
    mux4x32         next_pc (pc4, bpc, da, jpc, pcsrc, npc);
    blk_mem_gen_0   i_mem (
        .addra(pc[7:2]),
        .clka(~clk),
        .douta(ins)
    );
//  dffe32          program_counter (npc, clk, clrn, wpcir, pc);
//  dffe32          pc_4_r (pc4, clk, clrn, wpcir, dpc4);
//  dffe32          inst_r (ins, clk, clrn, wpcir, inst);
    always @(posedge clk or negedge clrn) begin 
        if (!clrn) begin
            pc      <= 0;
            dpc4    <= 0;
            inst    <= 0;
        end else if (wpcir) begin
            pc      <= npc;
            dpc4    <= pc4;
            inst    <= ins;
        end
    end
    wire            swfp, regrt, sext, fwdf, fwdfe, wfpr;
    assign          op      = inst[31:26];
    assign          rs      = inst[25:21];
    assign          rt      = inst[20:16];
    assign          rd      = inst[15:11];
    assign          ft      = inst[20:16];
    assign          fs      = inst[15:11];
    assign          fd      = inst[10:06];
    assign          func    = inst[05:00];
    assign          simm    = {{16{sext&inst[15]}},inst[15:0]};
    assign          jpc     = {dpc4[31:28],inst[25:0],2'b00};
//  cla32           br_addr (dpc4,{simm[29:00],2'b00},1'b0,bpc);
    assign          bpc     = dpc4 + {simm[29:00],2'b00};
    regfile         rf (
        // input ports
        .clk(~clk),             .clrn(clrn),                 
        .wn(wrn),               .we(wwreg),
        .rna(rs),               .rnb(rt),
        .d(wdi),
        // output ports
        .qa(qa),                .qb(qb)
    );
    mux4x32         alu_a (qa, ealu, malu, mmo, fwda, da);
    mux4x32         alu_b (qb, ealu, malu, mmo, fwdb, db);
    mux2x32         store_f (db, dfb, swfp, dc);
    mux2x32         fwd_f_d (dc, e3d, fwdf, dd);
    wire            rsrtequ = ~|(da^db);
    mux2x5          des_reg_no (rd, rt, regrt, drn);
    iu_control      cu (
        // input ports
        .op(op),                .func(func),
        .rs(rs),                .rt(rt),            
        .fs(fs),                .ft(ft),
        .e1n(e1n),              .e2n(e2n),          .e3n(e3n),
        .e1w(e1w),              .e2w(e2w),          .e3w(e3w),  
        .ewreg(ewreg),          .em2reg(em2reg),    .ewfpr(ewfpr),      .ern(ern),
        .mwreg(mwreg),          .mm2reg(mm2reg),    .mwfpr(mwfpr),      .mrn(mrn),
        .stall_div_sqrt(stall),                     .st(st),
        .rsrtequ(rsrtequ),
        // output ports
        .wpcir(wpcir),          .wreg(wreg),        .m2reg(m2reg),      .wmem(wmem),
        .jal(jal),              .aluimm(aluimm),    .shift(shift),      .sext(sext),
        .regrt(regrt),          .swfp(swfp),        .fwdf(fwdf),        .fwdfe(fwdfe),
        .fwdla(fwdla),          .fwdlb(fwdlb),      .fwdfa(fwdfa),      .fwdfb(fwdfb),
        .wfpr(wfpr),            .wf(wf),            .fasmds(fasmds),    .aluc(aluc),
        .fc(fc),                                    .pcsrc(pcsrc),
        .fwda(fwda),                                .fwdb(fwdb),
        .stall_lw(stall_lw),                        .stall_fp(stall_fp), 
        .stall_lwc1(stall_lwc1),                    .stall_swc1(stall_swc1)
    );
    always @(posedge clk or negedge clrn) begin 
        if (!clrn) begin 
            ewfpr   <= 0;               ewreg   <= 0;
            em2reg  <= 0;               ewmem   <= 0;
            ejal    <= 0;               ealuimm <= 0;
            efwdfe  <= 0;               ealuc   <= 0;
            eshift  <= 0;               epc4    <= 0;
            ea      <= 0;               ed      <= 0;
            eimm    <= 0;               ern0    <= 0;
        end else begin
            ewfpr   <= wfpr;            ewreg   <= wreg;
            em2reg  <= m2reg;           ewmem   <= wmem;
            ejal    <= jal;             ealuimm <= aluimm;
            efwdfe  <= fwdfe;           ealuc   <= aluc;
            eshift  <= shift;           epc4    <= dpc4;
            ea      <= da;              ed      <= dd;
            eimm    <= simm;            ern0    <= drn;
        end
    end
//  cla32           ret_addr (epc4, 32'h4, 1'b0, epc8);
    assign          epc8    = epc4 + 32'h4;
    assign          sa      = {eimm[5:0],eimm[31:6]};
    mux2x32         alu_ina (ea, sa, eshift, alua);
    mux2x32         alu_inb (ed, eimm, ealuimm, alub);
    mux2x32         save_pc8 (ealu0, epc8, ejal, ealu);
    alu             al_unit (alua, alub, ealuc, ealu0, z);
    assign          ern     = ern0 | {5{jal}};
    mux2x32         fwd_f_e (ed, e3d, efwdfe, eb);
    always @(posedge clk or negedge clrn) begin
        if (!clrn) begin 
            mwfpr   <= 0;               mwreg   <= 0;
            mm2reg  <= 0;               mwmem   <= 0;
            malu    <= 0;               mb      <= 0;
            mrn     <= 0;
        end else begin 
            mwfpr   <= ewfpr;           mwreg   <= ewreg;
            mm2reg  <= em2reg;          mwmem   <= ewmem;
            malu    <= ealu;            mb      <= eb;
            mrn     <= ern;
        end
    end
//  data_mem        d_mem (mwmem, malu, mb, memclk, mmo);
    blk_mem_gen_1   d_mem (
        .addra(malu[6:2]),
        .clka(memclk),
        .dina(mb),
        .douta(mmo),
        .wea(mwmem)
    );
    always @(posedge clk or negedge clrn) begin
        if (!clrn) begin
            wwfpr   <= 0;               wwreg   <= 0;
            wm2reg  <= 0;               wmo     <= 0;
            walu    <= 0;               wrn     <= 0;
        end else begin 
            wwfpr   <= mwfpr;           wwreg   <= mwreg;
            wm2reg  <= mm2reg;          wmo     <= mmo;
            walu    <= malu;            wrn     <= mrn;
        end
    end
    mux2x32         wb_sel (walu, wmo, wm2reg, wdi);
endmodule