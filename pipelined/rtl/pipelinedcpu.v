module pipelinedcpu (clk, clrn, pc, inst, ealu, malu, wdi);
    input           clk, clrn;  // clock and reset
    output  [31:0]  pc;         // program counter
    output  [31:0]  inst;       // instruction in ID stage
    output  [31:0]  ealu;       // alu result in EXE stage
    output  [31:0]  malu;       // alu result in MEM stage
    output  [31:0]  wdi;        // data to be written into register file

    // signals in IF stage
    wire    [31:0]  pc4;        // pc+4 in IF stage
    wire    [31:0]  ins;        // instruction in IF stage
    wire    [31:0]  npc;        // next pc in IF stage

    // signals in ID stage
    wire    [31:0]  dpc4;       // pc+4 in ID stage
    wire    [31:0]  bpc;        // branch target of beq and bne instructions
    wire    [31:0]  jpc;        // jump target of jr instruction
    wire    [31:0]  da,db;      // two operands a and b in ID stage
    wire    [31:0]  dimm;       // 32-bit extended immediate in ID stage
    wire    [4:0]   drn;        // destination register number in ID stage
    wire    [3:0]   daluc;      // alu control in ID stage
    wire    [1:0]   pcsrc;      // next pc (npc) select in ID stage
    wire            wpcir;      // pipepc and pipeir write enable
    wire            dwreg;      // register file write enable in ID stage
    wire            dm2reg;     // memory to register in ID stage
    wire            dwmem;      // memory wirte in ID stage
    wire            daluimm;    // alu input b is an immediate in ID stage
    wire            dshift;     // shift in ID stage
    wire            djal;       // jal in ID stage

    // signals in EXE stage
    wire    [31:0]  epc4;       // pc+4 in EXE stage
    wire    [31:0]  ea,eb;      // two operands a and b in EXE stage
    wire    [31:0]  eimm;       // 32-bit extended immediate in EXE stage
    wire    [4:0]   ern0;       // temporary register number in WB stage
    wire    [4:0]   ern;        // destination register number in EXE stage
    wire    [3:0]   ealuc;      // alu control in EXE stage
    wire            ewreg;      // register file write enable in EXE stage
    wire            em2reg;     // memory to register in EXE stage
    wire            ewmem;      // memoy write in EXE stage
    wire            ealuimm;    // alu input b is an immediate in EXE stage
    wire            eshift;     // shift in EXE stage
    wire            ejal;       // jal in EXE stage

    // signals in MEM stage
    wire    [31:0]  mb;         // operand b in MEM stage
    wire    [31:0]  mmo;        // memory data out in MEM stage
    wire    [4:0]   mrn;        // destination register number in MEM stage
    wire            mwreg;      // register file write enable in MEM stage
    wire            mm2reg;     // memory to register in MEM stage
    wire            mwmem;      // memory write in MEM stage

    // signals in WB stage
    wire    [31:0]  wmo;        // memory data out in WB stage
    wire    [31:0]  walu;       // alu result in WB stage
    wire    [4:0]   wrn;        // destination register number in WB stage
    wire            wwreg;      // register file write enable in WB stage
    wire            wm2reg;     // memory to register in WB stage

    // program counter
    pipepc      prog_cnt (
        // input ports
        .clk(clk),
        .clrn(clrn),
        .npc(npc),
        .wpc(wpcir),
        // output port
        .pc(pc)
    );
    pipeif      if_stage (
        // inputs ports
        .pcsrc(pcsrc),
        .pc(pc),
        .bpc(bpc),
        .rpc(da),
        .jpc(jpc),
        // output ports
        .npc(npc),
        .pc4(pc4),
        .ins(ins)
    );
    pipeifid    ifid_reg (
        .pc4(pc4),
        .ins(ins),
        .wir(wpcir),
        .clk(clk),
        .clrn(clrn),
        .dpc4(dpc4),
        .dinst(inst)
    );
    pipeid      id_stage (
        // input ports
        .clk(clk),
        .clrn(clrn),
        .dpc4(dpc4),
        .dinst(inst),
        .wdi(wdi),
        .ealu(ealu),
        .malu(malu),
        .mmo(mmo),
        .ern(ern),
        .mrn(mrn),
        .wrn(wrn),
        .ewreg(ewreg),
        .em2reg(em2reg),
        .mwreg(mwreg),
        .mm2reg(mm2reg),
        .wwreg(wwreg),
        // output ports
        .bpc(bpc),
        .jpc(jpc),
        .a(da),
        .b(db),
        .dimm(dimm),
        .rn(drn),
        .aluc(daluc),
        .pcsrc(pcsrc),
        .nostall(wpcir),
        .wreg(dwreg),
        .m2reg(dm2reg),
        .wmem(dwmem),
        .aluimm(daluimm),
        .shift(dshift),
        .jal(djal)
    );
    pipeidexe   idexe_reg (
        // input ports
        .clk(clk),
        .clrn(clrn),
        .da(da),
        .db(db),
        .dimm(dimm),
        .dpc4(dpc4),
        .drn(drn),
        .daluc(daluc),
        .dwreg(dwreg),
        .dm2reg(dm2reg),
        .dwmem(dwmem),
        .daluimm(daluimm),
        .dshift(dshift),
        .djal(djal),
        // output ports
        .ea(ea),
        .eb(eb),
        .eimm(eimm),
        .epc4(epc4),
        .ern(ern0),
        .ealuc(ealuc),
        .ewreg(ewreg),
        .em2reg(em2reg),
        .ewmem(ewmem),
        .ealuimm(ealuimm),
        .eshift(eshift),
        .ejal(ejal)
    );
    pipexe      exe_stage(
        // input ports
        .ea(ea),
        .eb(eb),
        .eimm(eimm),
        .epc4(epc4),
        .ern0(ern0),
        .ealuc(ealuc),
        .ealuimm(ealuimm),
        .eshift(eshift),
        .ejal(ejal),
        // output ports
        .ealu(ealu),
        .ern(ern)
    );
    pipexemem   exemem_reg (
        // input ports
        .clk(clk),
        .clrn(clrn),
        .ealu(ealu),
        .eb(eb),
        .ern(ern),
        .ewreg(ewreg),
        .em2reg(em2reg),
        .ewmem(ewmem),
        // output ports
        .malu(malu),
        .mb(mb),
        .mrn(mrn),
        .mwreg(mwreg),
        .mm2reg(mm2reg),
        .mwmem(mwmem)
    );
    pipemem     mem_stage (
        .clk(clk),
        .addr(malu),
        .datain(mb),
        .we(mwmem),
        .dataout(mmo)
    );
    pipememwb   memwb_reg (
        // input ports
        .clk(clk),
        .clrn(clrn),
        .mmo(mmo),
        .malu(malu),
        .mrn(mrn),
        .mwreg(mwreg),
        .mm2reg(mm2reg),
        // output ports
        .wmo(wmo),
        .walu(walu),
        .wrn(wrn),
        .wwreg(wwreg),
        .wm2reg(wm2reg)
    );
    pipewb      wb_stage (
        .walu(walu),
        .wmo(wmo),
        .wm2reg(wm2reg),
        .wdi(wdi)
    );
endmodule