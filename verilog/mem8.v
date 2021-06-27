module mem8 (
    input wire clk,
    input wire we,
    input wire[10:0] a,
    input wire[7:0] d,
    input wire[10:0] dpra,

    output wire[7:0] dpo
);
    reg[7:0] mem[2047:0];

    assign dpo = mem[dpra];


    always @(posedge clk) begin
        if (we) begin
            mem[a] <= d;
        end
    end
endmodule