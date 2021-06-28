module fake_PC (
    input wire clk,
    input wire we,
    input wire[31:0] fake_pc_in,
    input wire reset,

    output reg[31:0] fake_pc_out
);
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            fake_pc_out <= 32'h00400000;
        end
        else if (we) begin
            fake_pc_out <= fake_pc_in;
        end
    end
endmodule