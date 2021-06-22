module RAM (
    input wire clk,
    input wire we,
    input wire[31:0] addr,
    input wire[1:0] mask,
    input wire signed_ext,
    input wire[31:0] wdata,

    output wire[31:0] rdata
);
    reg[7:0] mem[1023:0];

    assign rdata = mask[1] ? 
                        {mem[(addr + 3)[9:0]], mem[(addr + 2)[9:0]], mem[(addr + 1)[9:0]], mem[addr[9:0]]}
                        :
                        (mask[0] ?
                            {{16{mem[(addr + 1)[9:0]][7] & signed_ext}}, mem[(addr + 1)[9:0]], mem[addr[9:0]]}
                            :
                            {{24{mem[addr[9:0]][7] & signed_ext}}, mem[addr[9:0]]}
                        )
                        ;


    always @(posedge clk) begin
        if (we) begin
            if (mask[1]) begin
                mem[(addr + 3)[9:0]] <= wdata[31:24];
                mem[(addr + 2)[9:0]] <= wdata[23:16];
                mem[(addr + 1)[9:0]] <= wdata[15:8];
                mem[addr[9:0]] <= wdata[7:0];
            end
            else if (mask[0]) begin
                mem[(addr + 1)[9:0]] <= wdata[15:8];
                mem[addr[9:0]] <= wdata[7:0];
            end
            else begin
                mem[addr[9:0]] <= wdata[7:0];
            end
        end
    end
endmodule