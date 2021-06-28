module sccomp_dataflow (
    input wire clk_in,
    input wire reset,

    output wire[31:0] inst,
    output wire[31:0] pc
);

    wire[31:0] ram_cpu_rdata;
    wire[31:0] cp0_cpu_rdata;
    wire[31:0] cp0_cpu_status;
    wire[31:0] cp0_cpu_exc_addr;

    wire cpu_ram_we;
    wire[31:0] cpu_ram_addr;
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

    wire[31:0] cpu_fake_pc;

    assign pc = cpu_fake_pc;

    RAM ram_inst(
        .clk(clk_in),
        .we(cpu_ram_we),
        .addr(cpu_ram_addr),
        .wdata(cpu_ram_wdata),
        .rdata(ram_cpu_rdata)
    );

    CPU sccpu(
        .clk(clk_in),
        .reset(reset),
        .ram_cpu_rdata(ram_cpu_rdata),
        .cp0_cpu_rdata(cp0_cpu_rdata),
        .cp0_cpu_status(cp0_cpu_status),
        .cp0_cpu_exc_addr(cp0_cpu_exc_addr),
        .cpu_ram_we(cpu_ram_we),
        .cpu_ram_addr(cpu_ram_addr),
        .cpu_ram_wdata(cpu_ram_wdata),
        .cpu_cp0_rst(cpu_cp0_rst),
        .cpu_cp0_mfc0(cpu_cp0_mfc0),
        .cpu_cp0_mtc0(cpu_cp0_mtc0),
        .cpu_cp0_pc(cpu_cp0_pc),
        .cpu_cp0_rd(cpu_cp0_rd),
        .cpu_cp0_wdata(cpu_cp0_wdata),
        .cpu_cp0_exception(cpu_cp0_exception),
        .cpu_cp0_eret(cpu_cp0_eret),
        .cpu_cp0_cause(cpu_cp0_cause),
        .cpu_fake_pc(cpu_fake_pc),
        .cpu_ir_out(inst)
    );

    CP0 cp0_inst(
        .clk(clk_in),
        .rst(reset),
        .mfc0(cpu_cp0_mfc0),
        .mtc0(cpu_cp0_mtc0),
        .pc(cpu_fake_pc),
        .Rd(cpu_cp0_rd),
        .wdata(cpu_cp0_wdata),
        .exception(cpu_cp0_exception),
        .eret(cpu_cp0_eret),
        .cause(cpu_cp0_cause),
        .rdata(cp0_cpu_rdata),
        .status(cp0_cpu_status),
        .exc_addr(cp0_cpu_exc_addr),

        .intr(),
        .timer_int()
    );
    
endmodule