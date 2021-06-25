module soc (
    input wire clk,
    input wire reset,

    output wire[31:0] ram_addr,
    output wire[31:0] ram_data,
    output wire[31:0] cp0_exc_addr
);

    wire[31:0] ram_cpu_rdata;
    wire[31:0] cp0_cpu_rdata;
    wire[31:0] cp0_cpu_status;
    wire[31:0] cp0_cpu_exc_addr;

    wire cpu_ram_we;
    wire[31:0] cpu_ram_addr;
    wire[1:0] cpu_ram_mask;
    wire cpu_ram_signed_ext;
    wire[31:0] cpu_ram_wdata;

    wire cpu_cp0_rst;
    wire cpu_cp0_mfc0;
    wire cpu_cp0_mtc0;
    wire[31:0] cpu_cp0_pc;
    wire[4:0] cpu_cp0_rd;
    wire[31:0] cpu_cp0_wdata;
    wire cpu_cp0_exception;
    wire cpu_cp0_eret;
    wire[4:0] cpu_cp0_cause;

    RAM ram_inst(
        .clk(clk),
        .we(cpu_ram_we),
        .addr(cpu_ram_addr),
        .mask(cpu_ram_mask),
        .signed_ext(cpu_ram_signed_ext),
        .wdata(cpu_ram_wdata),
        .rdata(ram_cpu_rdata)
    );

    CPU cpu_inst(
        .clk(clk),
        .reset(reset),
        .ram_cpu_rdata(ram_cpu_rdata),
        .cp0_cpu_rdata(cp0_cpu_rdata),
        .cp0_cpu_status(cp0_cpu_status),
        .cp0_exc_addr(cp0_exc_addr),
        .cpu_ram_we(cpu_ram_we),
        .cpu_ram_addr(cpu_ram_addr),
        .cpu_ram_mask(cpu_ram_mask),
        .cpu_ram_signed_ext(cpu_ram_signed_ext),
        .cpu_ram_wdata(cpu_ram_wdata),
        .cpu_cp0_rst(cpu_cp0_rst),
        .cpu_cp0_mfc0(cpu_cp0_mfc0),
        .cpu_cp0_mtc0(cpu_cp0_mtc0),
        .cpu_cp0_pc(cpu_cp0_pc),
        .cpu_cp0_rd(cpu_cp0_rd),
        .cpu_cp0_wdata(cpu_cp0_wdata),
        .cpu_cp0_exception(cpu_cp0_exception),
        .cpu_cp0_eret(cpu_cp0_eret),
        .cpu_cp0_cause(cpu_cp0_cause)
    );

    CP0 cp0_inst(
        .clk(clk),
        .rst(reset),
        .mfc0(cpu_cp0_mfc0),
        .mtc0(cpu_cp0_mtc0),
        .pc(cpu_cp0_pc),
        .Rd(cpu_cp0_rd),
        .wdata(cpu_cp0_wdata),
        .exception(cpu_cp0_exception),
        .eret(cpu_cp0_eret),
        .cause(cpu_cp0_cause),
        .rdata(cp0_cpu_rdata),
        .status(cp0_cpu_status),
        .exc_addr(cp0_cpu_exc_addr)
    );
    
endmodule