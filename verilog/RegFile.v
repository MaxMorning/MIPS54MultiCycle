module RegFile (
    input wire clk,
    input wire reset,
    input wire we,
    input wire[4:0] raddr1,
    input wire[4:0] raddr2,
    input wire[4:0] waddr,
    input wire[31:0] wdata,

    output wire[31:0] rdata1,
    output wire[31:0] rdata2
);
    reg[31:0] array_reg[31:0];
    assign rdata1 = array_reg[raddr1];
    assign rdata2 = array_reg[raddr2];

    integer i;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                array_reg[i] <= 32'h0;
            end
        end
        else if (we && waddr != 4'b0000) begin
            array_reg[waddr] <= wdata;
        end
        else begin
            array_reg[0] <= 32'h0;
        end
    end
endmodule