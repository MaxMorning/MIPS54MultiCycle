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
    wire[31:0] addr_1;
    wire[31:0] addr_2;
    wire[31:0] addr_3;

    assign addr_1 = addr + 1;
    assign addr_2 = addr + 2;
    assign addr_3 = addr + 3;

    assign rdata = mask[1] ? 
                        {mem[addr_3[9:0]], mem[addr_2[9:0]], mem[addr_1[9:0]], mem[addr[9:0]]}
                        :
                        (mask[0] ?
                            {{16{mem[addr_1[9:0]][7] & signed_ext}}, mem[addr_1[9:0]], mem[addr[9:0]]}
                            :
                            {{24{mem[addr[9:0]][7] & signed_ext}}, mem[addr[9:0]]}
                        )
                        ;


    always @(posedge clk) begin
        if (we) begin
            if (mask[1]) begin
                mem[addr_3[9:0]] <= wdata[31:24];
                mem[addr_2[9:0]] <= wdata[23:16];
                mem[addr_1[9:0]] <= wdata[15:8];
                mem[addr[9:0]] <= wdata[7:0];
            end
            else if (mask[0]) begin
                mem[addr_1[9:0]] <= wdata[15:8];
                mem[addr[9:0]] <= wdata[7:0];
            end
            else begin
                mem[addr[9:0]] <= wdata[7:0];
            end
        end
    end
endmodule