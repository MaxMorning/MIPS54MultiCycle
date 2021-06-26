module PC (
    input wire clk,
    input wire we,
    input wire[31:0] pc_in,
    input wire reset,

    output reg[31:0] pc_out
);
    
    always @(negedge clk or posedge reset) begin
        if (reset) begin
            pc_out <= 32'h00400000;
        end
        else if (we) begin
            pc_out <= pc_in;
        end
    end
endmodule