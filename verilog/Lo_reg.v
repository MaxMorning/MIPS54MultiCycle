module Lo_reg (
    input wire clk, // Src : clk
    input wire reset, // Src : reset
    input wire we, // Src : ctrl_hi_we
    input wire[31:0] wdata, // Src : GPR.rdata1(rs) / multCalculate.multResultHi / divCalculate.r

    output reg[31:0] rdata
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rdata <= 32'h00000000;
        end
        else if (we) begin
            rdata <= wdata;
        end
    end
endmodule