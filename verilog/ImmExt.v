module ImmExt (
    input wire[15:0] Imm16,
    input wire[1:0] ExtSelect,

    output wire[31:0] extResult
);

    assign extResult = ExtSelect[1] ?
                        (ExtSelect[0] ? {{14{Imm16[15]}}, Imm16, 2'b00} : {27'h0, Imm16[10:6]})
                        : // signed / unsigned extension
                        {{16{ExtSelect[0] & Imm16[15]}} , Imm16};
endmodule