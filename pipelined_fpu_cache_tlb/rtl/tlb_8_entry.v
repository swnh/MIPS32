module tlb_8_entry (
    input       [23:0]  pte_in,
    input               tlbwi,
    input               tlbwr,
    input       [2:0]   index,
    input       [19:0]  vpn,
    input               clk, clrn,
    output      [23:0]  pte_out,
    output              tlb_hit
);
    wire        [2:0]   random;
    wire        [2:0]   w_idx;
    wire        [2:0]   ram_idx;
    wire        [2:0]   vpn_index;
    wire                tlbw    = tlbwi | tlbwr;
    rand3   rdm (clk,clrn,random);
    mux2x3  w_address (index,random,tlbwr,w_idx);
    mux2x3  ram_address (vpn_index,w_idx,tlbw,ram_idx);
    ram8x24 rpn (
        .clk(clk),
        .address(ram_idx),
        .data(pte_in),
        .we(tlbw),
        .q(pte_out)
    );
    cam8x21 valid_tag (
        .clk(clk),
        .wren(tlbw),
        .pattern(vpn),
        .wraddress(w_idx),
        .maddress(vpn_index),
        .mfound(tlb_hit)
    );
endmodule