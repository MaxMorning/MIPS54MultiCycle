module RamStoreProc(
    input wire[31:0] ram_data_in,
    input wire[31:0] gpr_data_in,
    input wire[1:0] addr,
    input wire[1:0] mask,

    output wire[31:0] data_out
);

    assign data_out = mask[1] ? 
                        gpr_data_in
                        :
                        (
                            mask[0] ?
                                (addr[1] ? {gpr_data_in[15:0], ram_data_in[15:0]} : {ram_data_in[31:16], gpr_data_in[15:0]})
                                :
                                (addr[1] ?
                                    (addr[0] ? {gpr_data_in[7:0], ram_data_in[23:0]} : {ram_data_in[31:24], gpr_data_in[7:0], ram_data_in[15:0]})
                                    :
                                    (addr[0] ? {ram_data_in[31:16], gpr_data_in[7:0], ram_data_in[7:0]} : {ram_data_in[31:8], gpr_data_in[7:0]})
                                )
                        );

endmodule