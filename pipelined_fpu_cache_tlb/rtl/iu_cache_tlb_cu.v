module iu_cache_tlb_cu (
    input               rsrtequ, ewreg, em2reg, ewfpr, mwreg, mm2reg, mwfpr,
    input               e1w, e2w, e3w, stall_div_sqrt, st,
    input        [5:0]  op, func,
    input        [4:0]  rs, rt, rd, fs ,ft, ern, mrn, e1n, e2n, e3n,
    input       [31:0]  sta,
    output              wpcir, wreg, m2reg, wmem, jal, aluimm, shift, sext, regrt,
    output              swfp, fwdf, fwdfe,
    output              fwdla, fwdlb, fwdfa, fwdfb,
    output              wfpr, wf, fasmds,
    output       [1:0]  pcsrc, 
    output  reg  [1:0]  fwda, fwdb,
    output       [3:0]  aluc,
    output       [2:0]  fc,
    output              stall_lw, stall_fp, stall_lwc1, stall_swc1,
    output              rc0,
    output              wc0,
    output              tlbwi,
    output              tlbwr,
    output       [1:0]  c0rn, sepc, selpc,
    output              windex,
    output              wentlo,
    output              wcontx,
    output              wenthi,
    output              wepc,
    output              wcau,
    output              wsta,
    output              isbr,
    output              cancel,
    output              exce,
    output              ldst,
    output      [31:0]  cause,
    input               wisbr,
    input               ecancel,
    input               itlb_exc,
    input               dtlb_exc,
    output              itlb_exce,
    output              dtlb_exce
);
    // Instruction Decode
    // R-type
    wire            rtype   = (op == 6'b000000);
    wire            i_add   = rtype & (func == 6'b100000);
    wire            i_sub   = rtype & (func == 6'b100010);
    wire            i_and   = rtype & (func == 6'b100100);
    wire            i_or    = rtype & (func == 6'b100101);
    wire            i_xor   = rtype & (func == 6'b100110);
    wire            i_sll   = rtype & (func == 6'b000000);
    wire            i_srl   = rtype & (func == 6'b000010);
    wire            i_sra   = rtype & (func == 6'b000011);
    wire            i_jr    = rtype & (func == 6'b001000);
    // I-type
    wire            i_addi  = (op == 6'b001000);
    wire            i_andi  = (op == 6'b001100);
    wire            i_ori   = (op == 6'b001101);
    wire            i_xori  = (op == 6'b001110);
    wire            i_lw    = (op == 6'b100011);
    wire            i_sw    = (op == 6'b101011);
    wire            i_beq   = (op == 6'b000100);
    wire            i_bne   = (op == 6'b000101);
    wire            i_lui   = (op == 6'b001111);
    // J-type
    wire            i_j     = (op == 6'b000010);
    wire            i_jal   = (op == 6'b000011);
    // F-type
    wire            ftype   = (op == 6'b010001);
    wire            i_fadd  = ftype & (func == 6'b000000);
    wire            i_fsub  = ftype & (func == 6'b000001);
    wire            i_fmul  = ftype & (func == 6'b000010);
    wire            i_fdiv  = ftype & (func == 6'b000011);
    wire            i_fsqrt = ftype & (func == 6'b000100);
    wire            i_lwc1  = (op == 6'b110001);
    wire            i_swc1  = (op == 6'b111001);
    wire            i_rs    = i_add  | i_sub | i_and  | i_or  | i_xor  | i_jr   |
                              i_addi |         i_andi | i_ori | i_xori |
                              i_lw   | i_sw  | i_beq  | i_bne | i_lwc1 | i_swc1;
    wire            i_rt    = i_add  | i_sub | i_and  | i_or  | i_xor  | i_mtc0 |
                              i_sll  | i_srl | i_sra  | i_sw  | i_beq  | i_bne;
    assign          itlb_exce   = itlb_exc & sta[4];
    assign          dtlb_exce   = dtlb_exc & sta[5];
    wire            no_dtlb_exce    = ~dtlb_exce;
    assign          ldst    = (i_lw | i_sw | i_lwc1 | i_swc1) & ~ecancel & no_dtlb_exce;
    assign          isbr    = i_beq | i_bne | i_j | i_jal;
    // itlb_exce    dtlb_exce   isbr    wisbr   EPC     sepc[1:0]
    // 1            x           0       x       V_PC    0 0
    // 1            x           1       x       PCD     0 1
    // 0            1           x       0       PCM     1 0
    // 0            1           x       1       PCW     1 1
    assign          sepc[1] = ~itlb_exce & dtlb_exce;
    assign          sepc[0] =  itlb_exce & isbr | ~itlb_exce & dtlb_exce & wisbr;
    assign          exce    =  itlb_exce | dtlb_exce;
    assign          cancel  = exce;
    assign          selpc[1]    = exce;
    assign          selpc[0]    = i_eret;
    // op       rs      rt      rd              func
    // 010000   00100   xxxxx   xxxxx   00000   000000  mtc0 rt, rd; c0[rd] <- gpr[rt]
    // 010000   00000   xxxxx   xxxxx   00000   000000  mfc0 rt, rd; gpr[rt] <- c0[rd]
    // 010000   10000   00000   00000   00000   000010  tlbwi
    // 010000   10000   00000   00000   00000   000110  tlbwr
    // 010000   10000   00000   00000   00000   011000  eret
    assign          i_mtc0  = (op == 6'h10) & (rs == 5'h04) & (func == 6'h00) & no_dtlb_exce;
    assign          i_mfc0  = (op == 6'h10) & (rs == 5'h00) & (func == 6'h00);
    assign          i_eret  = (op == 6'h10) & (rs == 5'h10) & (func == 6'h18);
    assign          tlbwi   = (op == 6'h10) & (rs == 5'h10) & (func == 6'h02);
    assign          tlbwr   = (op == 6'h10) & (rs == 5'h10) & (func == 6'h06);
    assign          windex  = i_mtc0 & (rd == 5'h00);
    assign          wentlo  = i_mtc0 & (rd == 5'h02);
    assign          wcontx  = i_mtc0 & (rd == 5'h04);
    assign          wenthi  = i_mtc0 & (rd == 5'h09);
    assign          wsta    = i_mtc0 & (rd == 5'h0c) | exce | i_eret;
    assign          wcau    = i_mtc0 & (rd == 5'h0d) | exce;
    assign          wepc    = i_mtc0 & (rd == 5'h0e) | exce;
//  wire            rcontx  = i_mfc0 & (rd == 5'h04);
    wire            rstatus = i_mfc0 & (rd == 5'h0c);
    wire            rcause  = i_mfc0 & (rd == 5'h0d);
    wire            repc    = i_mfc0 & (rd == 5'h0e);
    assign          c0rn[1] = rcause  | repc;               // c0rn:    00     01    10    11
    assign          c0rn[0] = rstatus | repc;               //          contx  sta   cau   epc
    assign          rc0     = i_mfc0;                       // read  c0 regs
    assign          wc0     = i_mtc0;                       // write c0 regs
    wire     [2:0]  exccode;                                // test itlb_exc and dtlb_exc
    //        000   interupt
    //        001   syscall
    //        010   unimpl. inst
    //        011   overflow
    //        100   itlb_exc
    //        101   dtlb_exc
    assign          exccode[2]  = itlb_exc | dtlb_exc;
    assign          exccode[1]  = 0;
    assign          exccode[0]  = dtlb_exc;
    assign          cause       = {27'h0,exccode,2'b00};
    assign      stall_lw    = ewreg & em2reg & (ern != 0) & 
                              (i_rs & (ern == rs) | i_rt & (ern == rt));
//  reg     [1:0]   fwda, fwdb;
    always @ (ewreg or mwreg or ern or mrn or em2reg or mm2reg or rs or rt) begin
        fwda = 2'b00;                                 // default: no hazards
        if (ewreg & (ern != 0) & (ern == rs) & ~em2reg) begin
            fwda = 2'b01;                             // select exe_alu
        end else begin
            if (mwreg & (mrn != 0) & (mrn == rs) & ~mm2reg) begin
                fwda = 2'b10;                         // select mem_alu
            end else begin
                if (mwreg & (mrn != 0) & (mrn == rs) & mm2reg) begin
                    fwda = 2'b11;                     // select mem_lw
                end 
            end
        end
        fwdb = 2'b00;                                 // default: no hazards
        if (ewreg & (ern != 0) & (ern == rt) & ~em2reg) begin
            fwdb = 2'b01;                             // select exe_alu
        end else begin
            if (mwreg & (mrn != 0) & (mrn == rt) & ~mm2reg) begin
                fwdb = 2'b10;                         // select mem_alu
            end else begin
                if (mwreg & (mrn != 0) & (mrn == rt) & mm2reg) begin
                    fwdb = 2'b11;                     // select mem_lw
                end 
            end
        end
    end 

    assign          wreg    = (i_add | i_sub  | i_and  | i_or   | i_xor  | i_sll  |
                               i_srl | i_sra  | i_addi | i_andi | i_ori  | i_xori |
                               i_lw  | i_lui  | i_jal  | i_mfc0) & wpcir;
    assign          regrt   = i_addi | i_andi | i_ori  | i_xori | i_lw   | i_lui  | i_lwc1 |
                              i_mfc0;
    assign          jal     = i_jal;
    assign          m2reg   = i_lw;
    assign          shift   = i_sll  | i_srl  | i_sra;
    assign          aluimm  = i_addi | i_andi | i_ori  | i_xor  | i_lw   | i_lui  | i_sw   |
                              i_lwc1 | i_swc1;
    assign          sext    = i_addi | i_lw   | i_sw   | i_beq  | i_bne  | i_lwc1 | i_swc1;
    assign          aluc[3] = i_sra;
    assign          aluc[2] = i_sub  | i_or   | i_srl  | i_sra  | i_ori  | i_lui;
    assign          aluc[1] = i_xor  | i_sll  | i_srl  | i_sra  | i_xori | i_beq  | i_bne  | i_lui;
    assign          aluc[0] = i_and  | i_or   | i_sll  | i_srl  | i_sra  | i_andi | i_ori;
    assign          wmem    = (i_sw  | i_swc1) & wpcir & ~ecancel & no_dtlb_exce;
    assign          pcsrc[1]= i_jr   | i_j    | i_jal;
    assign          pcsrc[0]= i_beq & rsrtequ | i_bne & ~rsrtequ | i_j | i_jal;
    // 000 fadd, 001 fsub, 01x fmul, 10x fdiv, 11x fsqrt
    wire    [2:0]   fop;
    assign          fop[2]  = i_fdiv | i_fsqrt;
    assign          fop[1]  = i_fmul | i_fsqrt;
    assign          fop[0]  = i_fsub;
    // stall caused by fp data hazards
    wire            i_fs    = i_fadd | i_fsub | i_fmul | i_fdiv | i_fsqrt;
    wire            i_ft    = i_fadd | i_fsub | i_fmul | i_fdiv;
    assign      stall_fp    = (e1w & (i_fs & (e1n == fs) | i_ft & (e1n == ft))) |
                              (e2w & (i_fs & (e2n == fs) | i_ft & (e2n == ft)));
    assign          fwdfa   = e3w & (e3n == fs);
    assign          fwdfb   = e3w & (e3n == ft);
    assign          wfpr    = i_lwc1 & wpcir & ~ecancel & no_dtlb_exce;
    assign          fwdla   = mwfpr & (mrn == fs);
    assign          fwdlb   = mwfpr & (mrn == ft);
    assign      stall_lwc1  = ewfpr & (i_fs & (ern == fs) | i_ft & (ern == ft));
    assign          swfp    = i_swc1;
    assign          fwdf    = swfp & e3w & (ft == e3n);
    assign          fwdfe   = swfp & e2w & (ft == e2n);
    assign      stall_swc1  = swfp & e1w & (ft == e1n);
    assign      stall_others= stall_lw | stall_fp | stall_lwc1 | stall_swc1 | st;
    assign          wpcir   = ~(stall_div_sqrt | stall_others);
    assign          fc      = fop & {3{~stall_others}};
    assign          wf      = i_fs & wpcir & ~ecancel & no_dtlb_exce;
    assign          fasmds  = i_fs;
endmodule