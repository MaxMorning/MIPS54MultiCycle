module Concatenate (
    input wire[25:0] Jimm,
    input wire[31:0] pc,

    output wire[31:0] Jconcatenate
);
    assign Jconcatenate = {pc[31:28], Jimm, 2'b00};
endmodule