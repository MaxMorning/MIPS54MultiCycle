module multCalculate (
    input wire signed_mult,
    input wire[31:0] mult_a,
    input wire[31:0] mult_b,

    output wire[31:0] multResultHi,
    output wire[31:0] multResultLo
);
    wire [31:0] a_in;
    wire [31:0] b_in;
    wire int_signal;

    wire [31:0] wire_lv0[31:0];
    wire [33:0] wire_lv1[15:0];
    wire [36:0] wire_lv2[7:0];
    wire [41:0] wire_lv3[3:0];
    wire [50:0] wire_lv4[1:0];
    wire [63:0] wire_lv5;
    
    wire [63:0] wire_out;

    assign a_in = signed_mult & mult_a[31] == 1 ? ~mult_a + 1 : mult_a;
    assign b_in = signed_mult & mult_b[31] == 1 ? ~mult_b + 1 : mult_b;
    assign int_signal = mult_a[31] ^ mult_b[31];
    
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1)
        begin : lv0
            assign wire_lv0[i] = {32{b_in[i]}} & a_in;
        end
    endgenerate
    
    generate
        for (i = 0; i < 16; i = i + 1)
        begin : lv1
            assign wire_lv1[i] = {{{1'b0, wire_lv0[2 * i + 1]} + {2'b00, wire_lv0[2 * i][31:1]}}, wire_lv0[2 * i][0]};
        end
    endgenerate

    generate
        for (i = 0; i < 8; i = i + 1)
        begin : lv2
            assign wire_lv2[i] = {{{1'b0, wire_lv1[2 * i + 1]} + {3'b000, wire_lv1[2 * i][33:2]}}, wire_lv1[2 * i][1:0]};
        end
    endgenerate

    generate
        for (i = 0; i < 4; i = i + 1)
        begin : lv3
            assign wire_lv3[i] = {{{1'b0, wire_lv2[2 * i + 1]} + {5'b00000, wire_lv2[2 * i][36:4]}}, wire_lv2[2 * i][3:0]};
        end
    endgenerate

    assign wire_lv4[0] = {{{1'b0, wire_lv3[1]} + {9'h0, wire_lv3[0][41:8]}}, wire_lv3[0][7:0]};
    assign wire_lv4[1] = {{{1'b0, wire_lv3[3]} + {9'h0, wire_lv3[2][41:8]}}, wire_lv3[2][7:0]};

    assign wire_lv5 = {{wire_lv4[1][47:0] + {13'h0, wire_lv4[0][50:16]}}, wire_lv4[0][15:0]};
    
    assign wire_out = signed_mult & int_signal ? ~wire_lv5 + 1 : wire_lv5;
    assign multResultHi = wire_out[63:32];
    assign multResultLo = wire_out[31:0];
endmodule