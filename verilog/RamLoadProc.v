module RamLoadProc (
    input wire[31:0] ram_data_in,
    input wire[1:0] addr,
    input wire[1:0] mask,
    input wire signed_ext,

    output wire[31:0] data_out
);
    
    assign data_out = mask[1] ?
                        ram_data_in
                        :
                        (
                            mask[0] ?
                                {{16{ram_data_in[{addr[1], 4'b1111}] & signed_ext}}, ram_data_in[{addr[1], 4'b1111} -: 16]}
                                :
                                {{24{ram_data_in[{addr[1:0], 3'b111}] & signed_ext}}, ram_data_in[{addr[1:0], 3'b111} -: 8]}
                        );
endmodule