module PC (
    input wire clk,
    input wire[31:0] pc_in,
    input wire reset,

    output reg[31:0] pc_out
);
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_out <= 32'h00400000;
        end
        else begin
            pc_out <= pc_in;
        end
    end
endmodule