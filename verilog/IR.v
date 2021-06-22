module IR (
    input wire clk, // Src : clk  
    input wire we, // Src : ctrl_ir_we  
    input wire[31:0] ir_in, // Src : RAM.rdata  

    output reg[31:0] ir_out
);

    always @(posedge clk) begin
        if (we) begin
            ir_out <= ir_in;
        end
    end
    
endmodule