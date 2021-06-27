module mem8 (
    input wire clk,
    input wire we,
    input wire[31:0] addr,
    input wire[1:0] mask,
    input wire signed_ext,
    input wire[31:0] wdata,

    output wire[31:0] rdata
);
    reg[31:0] mem[255:0];
    // wire[31:0] addr_1;
    // wire[31:0] addr_2;
    // wire[31:0] addr_3;

    // assign addr_1 = addr + 1;
    // assign addr_2 = addr + 2;
    // assign addr_3 = addr + 3;

    assign rdata = mask[1] ? 
                        mem[addr[9:2]]
                        :
                        (mask[0] ?
                            {{16{mem[addr[9:2]][{addr[1], 4'b1111}] & signed_ext}}, mem[addr[9:2]][{addr[1], 4'b1111} -: 16]}
                            :
                            {{24{mem[addr[9:2]][{addr[1:0], 3'b111}] & signed_ext}}, mem[addr[9:2]][{addr[1:0], 3'b111} -: 8]}
                        )
                        ;


    always @(posedge clk) begin
        if (we) begin
            if (mask[1]) begin
                mem[addr[9:2]] <= wdata;
            end
            else if (mask[0]) begin
                mem[addr[9:2]][{addr[1], 4'b1111} -: 16] <= wdata[15:0];
            end
            else begin
                mem[addr[9:2]][{addr[1:0], 3'b111} -: 8] <= wdata[7:0];
            end
        end
    end
endmodule