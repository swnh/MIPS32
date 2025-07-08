// The circuit for EXE stage
module  pipexe (
    input   [31:0]  ea, eb,
    input   [31:0]  eimm,
    input   [31:0]  epc4,
    input   [04:0]  ern0,
    input   [03:0]  ealuc,
    input           ealuimm,
    input           eshift,
    input           ejal,
    output  [31:0]  ealu,
    output  [04:0]  ern
); 

    wire    [31:0]  alua;
    wire    [31:0]  alub;
    wire    [31:0]  ealu0;  // alu result
    wire    [31:0]  epc8;
    wire            z;
    wire    [31:0]  esa = {eimm[5:0], eimm[31:6]}; // sa = inst[10:06]

    assign epc8 = epc4 + 4;
    assign alua = eshift  ? esa  : ea;
    assign alub = ealuimm ? eimm : eb;
    assign ealu = ejal    ? epc8 : ealu0;
    assign ern  = ern0 | {5{ejal}};
    
    alu alu (
        .a(alua),
        .b(alub),
        .aluc(ealuc),
        .r(ealu0),
        .z(z)
    );
endmodule