module ALU (
    input wire[31:0] opr1,
    input wire[31:0] opr2,
    input wire[3:0] ALUControl,

    output wire[31:0] ALUResult,
    output wire overflow,
    output wire zero
);

    wire[32:0] extOpr1 = {opr1[31], opr1};
    wire[32:0] extOpr2 = {opr2[31], opr2};

    wire[32:0] addResult = extOpr1 + extOpr2;
    wire[31:0] adduResult = opr1 + opr2;

    wire[32:0] subResult = extOpr1 - extOpr2;
    wire[31:0] subuResult = opr1 - opr2;

    wire[31:0] andResult = opr1 & opr2;
    wire[31:0] orResult = opr1 | opr2;
    wire[31:0] xorResult = opr1 ^ opr2;
    wire[31:0] norResult = ~(opr1 | opr2);

    wire[31:0] sltResult = $signed(opr1) < $signed(opr2) ? 32'h1 : 32'h0;
    wire[31:0] sltuResult = opr1 < opr2 ? 32'h1 : 32'h0;

    wire[31:0] sllResult = opr1 << opr2;
    wire[31:0] srlResult = opr1 >> opr2;
    wire[31:0] sraResult = opr1[31] ? (~(32'hffffffff >> opr2) | (opr1 >> opr2)) : opr1 >> opr2;
    // wire[31:0] sraResult = ({32{opr2[31]}} << (32 - opr1)) | (opr2 >> opr1);

    wire[31:0] luiResult = {opr2[15:0], 16'h0};


    assign ALUResult = ALUControl[3] ? // 1xxx
                            (ALUControl[2] ? // 11xx
                                (ALUControl[1] ? // 111x
                                    (ALUControl[0] ? sllResult : luiResult) // 1111    1110
                                    : // 110x
                                    (ALUControl[0] ? srlResult : sraResult) // 1101    1100
                                )
                                : // 10xx
                                (ALUControl[0] ? sltuResult : sltResult) // 1011    1010
                                // (ALUControl[1] ? // 101x
                                //     (ALUControl[0] ? sltuResult : sltResult) // 1011    1010
                                //     : // 100x
                                //     (ALUControl[0] ? srlResult : sraResult) // 1001 NA   1000 NA
                                // )
                            )
                            : // 0xxx
                            (ALUControl[2] ? // 01xx
                                (ALUControl[1] ? // 011x
                                    (ALUControl[0] ? norResult : xorResult) // 0111    0110
                                    : // 010x
                                    (ALUControl[0] ? orResult : andResult) // 0101    0100
                                )
                                : // 00xx
                                (ALUControl[1] ? // 001x
                                    (ALUControl[0] ? subuResult : subResult[31:0]) // 0011    0010
                                    : // 000x
                                    (ALUControl[0] ? adduResult : addResult[31:0]) // 0001   0000
                                )
                            );
    assign overflow = ALUControl[3] | ALUControl[2] | ALUControl[0] ? 1'b0 : (ALUControl[1] ? subResult[32] ^ subResult[31] : addResult[32] ^ addResult[31]);
    assign zero = ~(| ALUResult);
endmodule