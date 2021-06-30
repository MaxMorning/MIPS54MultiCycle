module IR (
    input wire clk, // Src : clk  
    input wire we, // Src : ctrl_ir_we  
    input wire reset,
    input wire[31:0] ir_in, // Src : RAM.rdata  

    output reg[31:0] ir_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ir_out <= 32'h0;
        end
        else if (we) begin
            ir_out <= ir_in;
        end
    end
    
endmodule