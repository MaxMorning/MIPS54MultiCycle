module RAM8 (
    input wire clk,
    input wire we,
    input wire[31:0] addr,
    input wire[1:0] mask,
    input wire signed_ext,
    input wire[31:0] wdata,

    output wire[31:0] rdata
);

    wire[3:0] mask4;
    wire[31:0] ori_rdata;
    wire[31:0] final_wdata;

    mem8_3 mem8_inst3(
        .clk(clk),
        .we(mask4[3] & we),
        .a(addr[12:2]),
        .d(final_wdata[31:24]),
        .dpra(addr[12:2]),
        .dpo(ori_rdata[31:24])
    );

    mem8_2 mem8_inst2(
        .clk(clk),
        .we(mask4[2] & we),
        .a(addr[12:2]),
        .d(final_wdata[23:16]),
        .dpra(addr[12:2]),
        .dpo(ori_rdata[23:16])
    );

    mem8_1 mem8_inst1(
        .clk(clk),
        .we(mask4[1] & we),
        .a(addr[12:2]),
        .d(final_wdata[15:8]),
        .dpra(addr[12:2]),
        .dpo(ori_rdata[15:8])
    );

    mem8_0 mem8_inst0(
        .clk(clk),
        .we(mask4[0] & we),
        .a(addr[12:2]),
        .d(final_wdata[7:0]),
        .dpra(addr[12:2]),
        .dpo(ori_rdata[7:0])
    );

    assign mask4 = mask[1] ?
                        4'b1111
                        :
                        (
                            mask[0] ?
                                (addr[1] ? 4'b1100 : 4'b0011)
                                :
                                (addr[1] ?
                                    (addr[0] ? 4'b1000 : 4'b0100)
                                    :
                                    (addr[0] ? 4'b0010 : 4'b0001)
                                )
                        );

    assign rdata = mask[1] ? 
                        ori_rdata
                        :
                        (mask[0] ?
                            {{16{ori_rdata[{addr[1], 4'b1111}] & signed_ext}}, ori_rdata[{addr[1], 4'b1111} -: 16]}
                            :
                            {{24{ori_rdata[{addr[1:0], 3'b111}] & signed_ext}}, ori_rdata[{addr[1:0], 3'b111} -: 8]}
                        )
                        ;

    assign final_wdata = mask[1] ?
                            wdata
                            :
                            (mask[0] ?
                                (addr[1] ? {wdata[15:0], 16'h0000} : {16'h0000, wdata[15:0]})
                                :
                                (addr[1] ?
                                    (addr[0] ? {wdata[7:0], 24'h000000} : {8'h00, wdata[7:0], 16'h0000})
                                    :
                                    (addr[0] ? {16'h0000, wdata[7:0], 8'h00} : {24'h000000, wdata[7:0]})
                                )
                            );
endmodule