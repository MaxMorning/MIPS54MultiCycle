module CPU (
    input wire clk,
    input wire reset,
    // RAM
    input wire[31:0] ram_cpu_rdata,

    // CP0
    input wire[31:0] cp0_cpu_rdata,
    input wire[31:0] cp0_cpu_status,
    input wire[31:0] cp0_cpu_exc_addr,

    // RAM
    output wire cpu_ram_we,
    output wire[31:0] cpu_ram_addr,
    output wire[1:0] cpu_ram_mask,
    output wire cpu_ram_signed_ext,
    output wire[31:0] cpu_ram_wdata,

    // CP0
    output wire cpu_cp0_rst,
    output wire cpu_cp0_mfc0,
    output wire cpu_cp0_mtc0,
    output wire[31:0] cpu_cp0_pc,
    output wire[4:0] cpu_cp0_rd,
    output wire[31:0] cpu_cp0_wdata,
    output wire cpu_cp0_exception,
    output wire cpu_cp0_eret,
    output wire[4:0] cpu_cp0_cause
);

    // ALU
    wire[31:0] alu_opr1;
    wire[31:0] alu_opr2;
    wire[3:0] ctrl_alu_control;
    wire[31:0] alu_result;
    wire alu_ctrl_overflow;
    wire alu_ctrl_zero;
    wire alu_ctrl_negative;

    // PC
    wire ctrl_pc_we;
    wire[31:0] pc_pc_in;
    wire[31:0] pc_pc_out;

    // IR
    wire ctrl_ir_we;
    wire[31:0] ir_ir_out;

    // RegFile
    wire[31:0] gpr_rdata1;
    wire[31:0] gpr_rdata2;
    wire ctrl_gpr_we;
    wire[4:0] gpr_waddr;
    wire[31:0] gpr_wdata;

    // branchCalc
    wire[31:0] branch_calc_result;

    // clzCalculate
    wire[31:0] clz_calc_result;

    // Concatenate
    wire[31:0] con_result;

    // divCalculate
    wire ctrl_div_start;
    wire[31:0] div_q;
    wire[31:0] div_r;
    wire div_div_done;

    // Hi reg
    wire ctrl_hi_we;
    wire[31:0] hi_wdata;
    wire[31:0] hi_rdata;

    // imm ext
    wire[1:0] ctrl_immext_select;
    wire[31:0] ext_result;

    // Lo reg
    wire ctrl_lo_we;
    wire[31:0] lo_wdata;
    wire[31:0] lo_rdata;

    // mult
    wire[31:0] multResultHi;
    wire[31:0] multResultLo;

    // select
    wire ram_addr_select;
    wire[1:0] alu_opr1_select;
    wire[1:0] alu_opr2_select;
    wire[2:0] pc_pc_in_select;
    wire[1:0] gpr_waddr_select;
    wire[2:0] gpr_wdata_select;
    wire[1:0] hi_reg_wdata_select;
    wire[1:0] lo_reg_wdata_select;

    wire ctrl_bad_addr;

    assign cpu_ram_mask = {2{~ir_ir_out[31] | ir_ir_out[30] | ctrl_bad_addr}} | ir_ir_out[27:26];

    assign cpu_ram_signed_ext = ir_ir_out[28];

    assign cpu_cp0_rst = reset;
    assign cpu_cp0_pc = pc_pc_out;
    assign cpu_cp0_rd = ir_ir_out[15:10];
    assign cpu_cp0_wdata = gpr_rdata2;
    
    assign cpu_ram_addr = ram_addr_select ? alu_result: pc_pc_out;

    assign alu_opr1 = alu_opr1_select[1] ? 
                        (alu_opr1_select[0] ? 32'h0: gpr_rdata2)
                        :
                        (alu_opr1_select[0] ? pc_pc_out: gpr_rdata1);

    assign alu_opr2 = alu_opr2_select[1] ?
                        (alu_opr2_select[0] ? 32'h4: gpr_rdata2)
                        :
                        (alu_opr2_select[0] ? ext_result: gpr_rdata1);

    assign pc_pc_in = pc_pc_in_select[2] ? cp0_cpu_exc_addr
                        :
                        (pc_pc_in_select[1] ? 
                            (pc_pc_in_select[0] ? branch_calc_result: alu_result)
                            :
                            (pc_pc_in_select[0] ? con_result: gpr_rdata1)
                        );

    assign gpr_waddr = gpr_waddr_select[1] ? 
                            5'h4
                            :
                            (gpr_waddr_select[0] ? ir_ir_out[20:16]: ir_ir_out[15:11]);

    assign gpr_wdata = gpr_wdata_select[2] ?
                            (gpr_wdata_select[1] ? 
                                clz_calc_result
                                :
                                (gpr_wdata_select[0] ? lo_rdata: hi_rdata)
                            )
                            :
                            (gpr_wdata_select[1] ? 
                                (gpr_wdata_select[0] ? cp0_cpu_rdata: pc_pc_out)
                                :
                                (gpr_wdata_select[0] ? ram_cpu_rdata: alu_result)
                            );

    assign hi_wdata = hi_reg_wdata_select[1] ?
                            gpr_rdata1
                            :
                            (hi_reg_wdata_select[0] ? div_r: multResultHi);

    assign lo_wdata = lo_reg_wdata_select[1] ?
                            gpr_rdata1
                            :
                            (lo_reg_wdata_select[0] ? div_q: multResultLo);
    
    ALU alu_inst(
        .opr1(alu_opr1),
        .opr2(alu_opr2),
        .ALUControl(ctrl_alu_control),
        .ALUResult(alu_result),
        .overflow(alu_ctrl_overflow),
        .zero(alu_ctrl_zero),
        .negative(alu_ctrl_negative)
    );

    branchCalc branchCalc_inst(
        .offset(ir_ir_out[15:0]),
        .pc_in(pc_pc_out),
        .branchCalcResult(branch_calc_result)
    );

    clzCalculate clzCalculate_inst(
        .data_in(gpr_rdata1),
        .clzCalcResult(clz_calc_result)
    );

    Concatenate concatenate_inst(
        .Jimm(ir_ir_out[25:0]),
        .pc(pc_pc_out),
        .Jconcatenate(con_result)
    );
    
    Controller controller(
        .clk(clk),
        .reset(reset),
        .ir_ctrl_instr(ir_ir_out),
        .alu_ctrl_overflow(alu_ctrl_overflow),
        .alu_ctrl_zero(alu_ctrl_zero),
        .alu_ctrl_negative(alu_ctrl_negative),
        .alu_ctrl_ls_address(alu_result[1:0]),
        .div_ctrl_done(div_div_done),

        .ctrl_ram_we(ctrl_ram_we),
        .ctrl_bad_addr(ctrl_bad_addr),
        .ctrl_alu_ALUcontrol(ctrl_alu_control),
        .ctrl_pc_we(ctrl_pc_we),
        .ctrl_ir_we(ctrl_ir_we),
        .ctrl_gpr_we(ctrl_gpr_we),
        .ctrl_immext_select(ctrl_immext_select),
        .ctrl_div_start(ctrl_div_start),
        .ctrl_hi_we(ctrl_hi_we),
        .ctrl_lo_we(ctrl_lo_we),
        .ctrl_cp0_mfc0(cpu_cp0_mfc0),
        .ctrl_cp0_mtc0(cpu_cp0_mtc0),
        .ctrl_cp0_exception(cpu_cp0_exception),
        .ctrl_cp0_eret(cpu_cp0_eret),
        .ctrl_cp0_cause(cpu_cp0_cause),

        .ram_addr_select(ram_addr_select),
        .alu_opr1_select(alu_opr1_select),
        .alu_opr2_select(alu_opr2_select),
        .pc_pc_in_select(pc_pc_in_select),
        .gpr_waddr_select(gpr_waddr_select),
        .gpr_wdata_select(gpr_wdata_select),
        .hi_reg_wdata_select(hi_reg_wdata_select),
        .lo_reg_wdata_select(lo_reg_wdata_select)
    );

    divCalculate divCalculate_inst(
        .clk(clk),
        .start(ctrl_div_start),
        .signed_div(ir_ir_out[0]),
        .dividend(gpr_rdata1),
        .divisor(gpr_rdata2),
        .q(div_q),
        .r(div_r),
        .divDone(div_div_done)
    );

    Hi_reg hi_inst(
        .clk(clk),
        .reset(reset),
        .we(ctrl_hi_we),
        .wdata(hi_wdata),
        .rdata(hi_rdata)
    );

    ImmExt immExt_inst(
        .Imm16(ir_ir_out[15:0]),
        .ExtSelect(ctrl_immext_select),
        .extResult(ext_result)
    );

    IR ir_inst(
        .clk(clk),
        .we(ctrl_ir_we),
        .ir_in(ram_cpu_rdata),
        .ir_out(ir_ir_out)
    );

    Lo_reg lo_inst(
        .clk(clk),
        .reset(reset),
        .we(ctrl_lo_we),
        .wdata(lo_wdata),
        .rdata(lo_rdata)
    );

    multCalculate multCalculate_inst(
        .signed_mult(ir_ir_out[0]),
        .mult_a(gpr_rdata1),
        .mult_b(gpr_rdata2),
        .multResultHi(multResultHi),
        .multResultLo(multResultLo)
    );

    PC pc_inst(
        .clk(clk),
        .we(ctrl_pc_we),
        .pc_in(pc_pc_in),
        .reset(reset),
        .pc_out(pc_pc_out)
    );

    RegFile reg_file(
        .clk(clk),
        .reset(reset),
        .we(ctrl_gpr_we),
        .raddr1(ir_ir_out[25:21]),
        .raddr2(ir_ir_out[20:16]),
        .waddr(gpr_waddr),
        .wdata(gpr_wdata),
        .rdata1(gpr_rdata1),
        .rdata2(gpr_rdata2)
    );
endmodule