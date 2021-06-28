module RAM (
    input wire clk,
    input wire we,
    input wire[31:0] addr,
    input wire[31:0] wdata,

    output wire[31:0] rdata
);

    mem mem_inst(
        .clk(clk),
        .we(we),
        .a(addr[12:2]),
        .dpra(addr[12:2]),
        .dpo(rdata),
        .d(wdata)
    );
endmodule