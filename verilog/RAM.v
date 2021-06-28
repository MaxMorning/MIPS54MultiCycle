module RAM (
    input wire clk,
    input wire we,
    input wire[31:0] addr,
    input wire[31:0] wdata,

    output wire[31:0] rdata
);
    reg[31:0] mem[4095:0];
    // wire[31:0] addr_1;
    // wire[31:0] addr_2;
    // wire[31:0] addr_3;

    // assign addr_1 = addr + 1;
    // assign addr_2 = addr + 2;
    // assign addr_3 = addr + 3;

    assign rdata = mem[{addr[27], addr[12:2]}];


    always @(posedge clk) begin
        if (we) begin
            mem[{addr[27], addr[12:2]}] <= wdata;
        end
    end
endmodule