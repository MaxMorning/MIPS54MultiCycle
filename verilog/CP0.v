module CP0 (
    input wire clk, // Src : clk
    input wire rst, // Src : reset
    input wire mfc0, // Src : ctrl_cp0_mfc0
    input wire mtc0, // Src : ctrl_cp0_mtc0
    input wire[31:0] pc, // Src : PC.pc_out
    input wire[4:0] Rd, // Src : IR.ir_out[15:10](rd)
    input wire[31:0] wdata, // Src : GPR.rdata2(rt)
    input wire exception, // Src : ctrl_cp0_exception
    input wire eret, // Src : ctrl_cp0_eret
    input wire[4:0] cause, // Src : ctrl_cp0_cause
    input wire intr,

    output wire[31:0] rdata, 
    output wire[31:0] status, 
    output wire timer_int, 
    output reg[31:0] exc_addr
);
    reg[31:0] reg_file[31:0];

    assign rdata = reg_file[Rd];
    assign status = reg_file[12];

    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                if (i != 12)
                    reg_file[i] <= 32'h0;
                else
                    reg_file[12] <= 32'hf;
            end
        end
        else if (exception) begin
            if (reg_file[12][0] && reg_file[12][{3'b000, cause[0], cause[2]}]) begin
                reg_file[12][0] <= 1'b0;
                reg_file[13][6:2] <= cause;
                reg_file[14] <= pc;
                exc_addr <= 32'h00400004;
            end
            else begin
                exc_addr <= pc;
            end
        end 
        else if (eret) begin
            reg_file[12][0] <= 1'b1;
            exc_addr <= reg_file[14];
        end
        else if (mtc0) begin
            reg_file[Rd] <= wdata;
        end
    end

    
endmodule