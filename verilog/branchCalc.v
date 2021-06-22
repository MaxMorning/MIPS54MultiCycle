module branchCalc (
    input wire[15:0] offset, // Src : IR.ir_out[15:0]
    input wire[31:0] pc_in, // Src : PC.pc_out

    output wire[31:0] branchCalcResult
);
    
    assign branchCalcResult = pc_in + {16'h0000, offset};
endmodule