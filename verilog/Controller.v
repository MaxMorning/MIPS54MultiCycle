module Controller (
    input wire clk, // Src : clk
    input wire reset, // Src : reset
    input wire[31:0] ir_ctrl_instr, // Src : IR.ir_out
    input wire alu_ctrl_overflow, // Src : ALU.overflow
    input wire alu_ctrl_zero, // Src : ALU.zero
    input wire alu_ctrl_negative, // Src : ALU.negative
    input wire[1:0] alu_ctrl_ls_address, // Src : ALU.ALUresult[1:0]
    input wire div_ctrl_done, // Src : divCalulate.divDone

    output wire ctrl_ram_we,
    output wire[1:0] ctrl_ram_mask,
    output wire ctrl_bad_addr,
    output wire[3:0] ctrl_alu_ALUcontrol,
    output wire ctrl_pc_we,
    output wire ctrl_ir_we,
    output wire ctrl_gpr_we,
    output wire[1:0] ctrl_immext_select,
    output wire ctrl_div_start,
    output wire ctrl_hi_we,
    output wire ctrl_lo_we,
    output wire ctrl_cp0_mfc0,
    output wire ctrl_cp0_mtc0,
    output wire ctrl_cp0_exception,
    output wire ctrl_cp0_eret,
    output wire[4:0] ctrl_cp0_cause,

    // select signal
    output wire ram_addr_select,
    output wire[1:0] alu_opr1_select,
    output wire[1:0] alu_opr2_select,
    output wire[2:0] pc_pc_in_select,
    output wire[1:0] gpr_waddr_select,
    output wire[2:0] gpr_wdata_select,
    output wire[1:0] hi_reg_wdata_select,
    output wire[1:0] lo_reg_wdata_select
);
    // definitions
    parameter sFetch            = 6'd0;
    parameter sDecode           = 6'd1;
    parameter sALregExe         = 6'd2;
    parameter sALregWB          = 6'd3;
    parameter sShamtShiftExe    = 6'd4;
    parameter sShamtShiftWB     = 6'd5;
    parameter sVarShiftExe      = 6'd6;
    parameter sVarShiftWB       = 6'd7;
    parameter sALimmExe         = 6'd8;
    parameter sALimmWB          = 6'd9;
    parameter sClz              = 6'd10;
    parameter sMulExe           = 6'd11;
    parameter sMulWB            = 6'd12;
    parameter sDivStart         = 6'd13;
    parameter sDivExe           = 6'd14;
    parameter sDivWB            = 6'd15;
    parameter sBeqExe           = 6'd16;
    parameter sBeqWB            = 6'd17;
    parameter sBgezExe          = 6'd18;
    parameter sBgezWB           = 6'd19;
    parameter sJump             = 6'd20;
    parameter sJAL              = 6'd21;
    parameter sJR               = 6'd22;
    parameter sJALR             = 6'd23;
    parameter sLoadMem          = 6'd24;
    parameter sLoadWB           = 6'd25;
    parameter sStoreMem         = 6'd26;
    parameter sStoreWB          = 6'd27;
    parameter sMFC0Ask          = 6'd28;
    parameter sMFC0Get          = 6'd29;
    parameter sMFHI             = 6'd30;
    parameter sMFLO             = 6'd31;
    parameter sMTC0             = 6'd32;
    parameter sMTHI             = 6'd33;
    parameter sMTLO             = 6'd34;
    parameter sSyscall          = 6'd35;
    parameter sEret             = 6'd36;
    parameter sTeqExe           = 6'd37;
    parameter sTeqWB            = 6'd38;
    parameter sBreak            = 6'd39;
    parameter sMul3WB           = 6'd44;
    parameter sException        = 6'd63;
    parameter sInit             = 6'd62;

    reg[5:0] status_reg;

    assign ctrl_ram_mask = {2{~ir_ctrl_instr[31] | ir_ctrl_instr[30] | status_reg[5] | ~status_reg[4] | ~status_reg[3] | status_reg[2]}} | ir_ctrl_instr[27:26];

    assign ctrl_bad_addr = | (ctrl_ram_mask & alu_ctrl_ls_address);
    assign ctrl_alu_ALUcontrol = (~status_reg[5] & ~status_reg[4] & ~status_reg[3] & ~status_reg[2] & ~status_reg[1]) ? 4'b0001 :
                                    (ir_ctrl_instr[31] ? 4'b0001  // Load / Store
                                        :
                                        (ir_ctrl_instr[29] ?
                                            (ir_ctrl_instr[28] ? // 11xx
                                                (ir_ctrl_instr[27] ? // 111x
                                                    (ir_ctrl_instr[26] ? 4'b1110 : 4'b0110) 
                                                    : //1111 lui   1110 xori
                                                    {1'b0, ir_ctrl_instr[28:26]} //1101 ori   1100 andi
                                                    // (inst[26] ? 4'b0101 : 4'b0100) //1101 ori   1100 andi
                                                ) 
                                                : // 10xx
                                                {ir_ctrl_instr[27], ir_ctrl_instr[28:26]}
                                                // (inst[27] ? 
                                                //     (inst[26] ? 4'b1011 : 4'b1010) : //1011 sltiu    1010 slti
                                                //     (inst[26] ? 4'b0001 : 4'b0000) //1001 addiu   1000 addi
                                                // )
                                            )
                                            :
                                            (ir_ctrl_instr[28] ? // 01xx
                                                4'b0110 
                                                : // 00xx
                                                (ir_ctrl_instr[27] ? // 001x
                                                    {2'b00, ir_ctrl_instr[27:26]} : // 000x
                                                    // (ir_ctrl_instr[26] ? 4'b1011 : 4'b1010) : //0011 jal   0010 j
                                                    (ir_ctrl_instr[26] ? 4'b0001 : {4{ir_ctrl_instr[5]}} ~^ {ir_ctrl_instr[3], ir_ctrl_instr[5] & ir_ctrl_instr[2], ir_ctrl_instr[4] | ir_ctrl_instr[1], ir_ctrl_instr[0]}) //0001 bgez   0000 R type & teq
                                                )
                                            )
                                        )
                                    );


    always @(posedge clk or posedge reset) begin
        if (reset) begin
            status_reg <= sFetch;
        end
        else begin
            case (status_reg)
                sFetch:
                    status_reg <= sDecode;
                sDecode:
                    begin
                        casex (ir_ctrl_instr[31:26])
                            6'b001xxx:
                                status_reg <= sALimmExe;
                            
                            6'b000000:
                                begin
                                    casex (ir_ctrl_instr[5:0])
                                        6'b100xxx:
                                            status_reg <= sALregExe;
                                        6'b10101x:
                                            status_reg <= sALregExe;

                                        6'b001000:
                                            status_reg <= sJR;

                                        6'b001001:
                                            status_reg <= sJALR;

                                        6'b0000x0:
                                            status_reg <= sShamtShiftExe;
                                        6'b000011:
                                            status_reg <= sShamtShiftExe;

                                        6'b0001x0:
                                            status_reg <= sVarShiftExe;
                                        6'b000111:
                                            status_reg <= sVarShiftExe;

                                        6'b01101x:
                                            status_reg <= sDivStart;
                                        
                                        6'b01100x:
                                            status_reg <= sMulExe;
                                        
                                        6'b010000:
                                            status_reg <= sMFHI;

                                        6'b010010:
                                            status_reg <= sMFLO;

                                        6'b010001:
                                            status_reg <= sMTHI;

                                        6'b010011:
                                            status_reg <= sMTLO;

                                        6'b001100:
                                            status_reg <= sSyscall;

                                        6'b110100:
                                            status_reg <= sTeqExe;

                                        6'b001101:
                                            status_reg <= sBreak;

                                        default: 
                                            status_reg <= sBreak;
                                    endcase
                                end
                            
                            6'b00010x:
                                status_reg <= sBeqExe;
                            
                            6'b000010:
                                status_reg <= sJump;

                            6'b000011:
                                status_reg <= sJAL;

                            6'b100x0x:
                                status_reg <= sLoadMem;
                            6'b100011:
                                status_reg <= sLoadMem;

                            6'b10100x:
                                status_reg <= sStoreMem;
                            6'b101011:
                                status_reg <= sStoreMem;

                            6'b011100:
                                status_reg <= ir_ctrl_instr[5] ? sClz : sMulExe;

                            6'b010000:
                                status_reg <= ir_ctrl_instr[25] ? sEret : (ir_ctrl_instr[23] ? sMTC0 : sMFC0Ask);

                            6'b000001:
                                status_reg <= sBgezExe;
                            default: 
                                status_reg <= sBreak;
                        endcase
                    end

                sALregExe:
                    status_reg <= sALregWB;
                sALregWB:
                    status_reg <= {6{alu_ctrl_overflow}};

                sShamtShiftExe:
                    status_reg <= sShamtShiftWB;
                sShamtShiftWB:
                    status_reg <= sFetch;

                sVarShiftExe:
                    status_reg <= sVarShiftWB;
                sVarShiftWB:
                    status_reg <= sFetch;

                sALimmExe:
                    status_reg <= sALimmWB;
                sALimmWB:
                    status_reg <= {6{alu_ctrl_overflow}};

                sClz:
                    status_reg <= sFetch;

                sMulExe:
                    status_reg <= {ir_ctrl_instr[30], 5'b01100};
                sMulWB:
                    status_reg <= sFetch;

                sDivStart:
                    status_reg <= sDivExe;
                sDivExe:
                    status_reg <= div_ctrl_done ? sDivWB : sDivExe;
                sDivWB:
                    status_reg <= sFetch;

                sBeqExe:
                    status_reg <= sBeqWB;
                sBeqWB:
                    status_reg <= sFetch;

                sBgezExe:
                    status_reg <= sBgezWB;
                sBgezWB:
                    status_reg <= sFetch;

                sJump:
                    status_reg <= sFetch;

                sJAL:
                    status_reg <= sFetch;

                sJR:
                    status_reg <= sFetch;
                
                sJALR:
                    status_reg <= sFetch;
                
                sLoadMem:
                    status_reg <= {6{ctrl_bad_addr}} | sLoadWB;
                sLoadWB:
                    status_reg <= sFetch;

                sStoreMem:
                    status_reg <= {6{ctrl_bad_addr}} | sStoreWB;
                sStoreWB:
                    status_reg <= sFetch;

                sMFC0Ask:
                    status_reg <= sMFC0Get;
                sMFC0Get:
                    status_reg <= sFetch;

                sMFHI:
                    status_reg <= sFetch;

                sMFLO:
                    status_reg <= sFetch;

                sMTC0:
                    status_reg <= sFetch;

                sMTHI:
                    status_reg <= sFetch;

                sMTLO:
                    status_reg <= sFetch;

                sSyscall:
                    status_reg <= sException;

                sEret:
                    status_reg <= sException;

                sTeqExe:
                    status_reg <= sTeqWB;
                sTeqWB:
                    status_reg <= {6{alu_ctrl_zero}};

                sBreak:
                    status_reg <= sException;

                sMul3WB:
                    status_reg <= sFetch;

                sException:
                    status_reg <= sFetch;

                sInit:
                    status_reg <= sFetch;
                default:
                    status_reg <= sBreak;
            endcase
        end
    end

    // control signals
    reg ram_we;
    reg pc_we;
    reg ir_we;
    reg gpr_we;
    reg[1:0] immext_select;
    reg div_start;
    reg hi_we;
    reg lo_we;
    reg cp0_mfc0;
    reg cp0_mtc0;
    reg cp0_exception;
    reg cp0_eret;
    reg[4:0] cp0_cause;

    // select signals
    reg addr_select;
    reg[1:0] opr1_select;
    reg[1:0] opr2_select;
    reg[2:0] pc_in_select;
    reg[1:0] reg_gpr_waddr_select;
    reg[2:0] reg_gpr_wdata_select;
    reg[1:0] reg_hi_reg_wdata_select;
    reg[1:0] reg_lo_reg_wdata_select;
    
    assign ctrl_ram_we = ram_we;
    assign ctrl_pc_we = pc_we;
    assign ctrl_ir_we = ir_we;
    assign ctrl_gpr_we = gpr_we;
    assign ctrl_immext_select = immext_select;
    assign ctrl_div_start = div_start;
    assign ctrl_hi_we = hi_we;
    assign ctrl_lo_we = lo_we;
    assign ctrl_cp0_mfc0 = cp0_mfc0;
    assign ctrl_cp0_mtc0 = cp0_mtc0;
    assign ctrl_cp0_exception = cp0_exception;
    assign ctrl_cp0_eret = cp0_eret;
    assign ctrl_cp0_cause = cp0_cause;

    assign ram_addr_select = addr_select;
    assign alu_opr1_select = opr1_select;
    assign alu_opr2_select = opr2_select;
    assign pc_pc_in_select = pc_in_select;
    assign gpr_waddr_select = reg_gpr_waddr_select;
    assign gpr_wdata_select = reg_gpr_wdata_select;
    assign hi_reg_wdata_select = reg_hi_reg_wdata_select;
    assign lo_reg_wdata_select = reg_lo_reg_wdata_select;


    parameter ram_addr_select_pc = 1'b0;
    parameter ram_addr_select_alu = 1'b1;

    parameter alu_opr1_select_gpr_rdata1 = 2'b00;
    parameter alu_opr1_select_pc = 2'b01;
    parameter alu_opr1_select_gpr_rdata2 = 2'b10;
    parameter alu_opr1_select_const_0 = 2'b11;

    parameter alu_opr2_select_gpr_rdata1 = 2'b00;
    parameter alu_opr2_select_extResult = 2'b01;
    parameter alu_opr2_select_gpr_rdata2 = 2'b10;
    parameter alu_opr2_select_const_4 = 2'b11;

    parameter pc_in_select_gpr_rdata1 = 3'b000;
    parameter pc_in_select_concatResult = 3'b001;
    parameter pc_in_select_alu = 3'b010;
    parameter pc_in_select_branchCalcResult = 3'b011;
    parameter pc_in_select_cp0_exc_addr = 3'b100;

    parameter gpr_waddr_select_ir_1511 = 2'b00;
    parameter gpr_waddr_select_ir_2016 = 2'b01;
    parameter gpr_waddr_select_const_31 = 2'b11;

    parameter gpr_wdata_select_alu = 3'b000;
    parameter gpr_wdata_select_ram = 3'b001;
    parameter gpr_wdata_select_pc = 3'b010;
    parameter gpr_wdata_select_cp0 = 3'b011;
    parameter gpr_wdata_select_hi = 3'b100;
    parameter gpr_wdata_select_lo = 3'b101;
    parameter gpr_wdata_select_clz = 3'b110;
    parameter gpr_wdata_select_multLo = 3'b111;

    parameter hi_wdata_select_mult = 2'b00;
    parameter hi_wdata_select_div = 2'b01;
    parameter hi_wdata_select_gpr = 2'b10;

    parameter lo_wdata_select_mult = 2'b00;
    parameter lo_wdata_select_div = 2'b01;
    parameter lo_wdata_select_gpr = 2'b10;
    
    always @(*) begin
        case (status_reg)
            sInit:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ram_addr_select_pc;
                    opr1_select <= alu_opr1_select_pc;
                    opr2_select <= alu_opr2_select_const_4;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end
            sFetch:
                begin
                    ram_we <= 0;
                    pc_we <= 1;
                    ir_we <= 1;
                    gpr_we <= 0;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ram_addr_select_pc;
                    opr1_select <= alu_opr1_select_pc;
                    opr2_select <= alu_opr2_select_const_4;
                    pc_in_select <= pc_in_select_alu;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end 
            
            sDecode:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'b01;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ram_addr_select_pc;
                    opr1_select <= alu_opr1_select_gpr_rdata1;
                    opr2_select <= alu_opr2_select_extResult;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sALregExe:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= alu_opr1_select_gpr_rdata1;
                    opr2_select <= alu_opr2_select_gpr_rdata2;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sALregWB:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= ~alu_ctrl_overflow;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= alu_ctrl_overflow;
                    cp0_eret <= 0;
                    cp0_cause <= 5'b01100;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= alu_opr1_select_gpr_rdata1;
                    opr2_select <= alu_opr2_select_gpr_rdata2;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= gpr_waddr_select_ir_1511;
                    reg_gpr_wdata_select <= gpr_wdata_select_alu;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sShamtShiftExe:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'b10;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= alu_opr1_select_gpr_rdata2;
                    opr2_select <= alu_opr2_select_extResult;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 2'bxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sShamtShiftWB:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 1;
                    immext_select <= 2'b10;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= alu_opr1_select_gpr_rdata2;
                    opr2_select <= alu_opr2_select_extResult;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= gpr_waddr_select_ir_1511;
                    reg_gpr_wdata_select <= gpr_wdata_select_alu;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sVarShiftExe:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= alu_opr1_select_gpr_rdata2;
                    opr2_select <= alu_opr2_select_gpr_rdata1;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sVarShiftWB:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 1;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= alu_opr1_select_gpr_rdata2;
                    opr2_select <= alu_opr2_select_gpr_rdata1;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= gpr_waddr_select_ir_1511;
                    reg_gpr_wdata_select <= gpr_wdata_select_alu;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sALimmExe:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= {1'b0, ~ir_ctrl_instr[29] | ~ir_ctrl_instr[28]};
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= alu_opr1_select_gpr_rdata1;
                    opr2_select <= alu_opr2_select_extResult;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 2'bxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sALimmWB:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= ~alu_ctrl_overflow;
                    immext_select <= {1'b0, ~ir_ctrl_instr[29] | ~ir_ctrl_instr[28]};
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= alu_ctrl_overflow;
                    cp0_eret <= 0;
                    cp0_cause <= 5'b01100;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= alu_opr1_select_gpr_rdata1;
                    opr2_select <= alu_opr2_select_extResult;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= gpr_waddr_select_ir_2016;
                    reg_gpr_wdata_select <= gpr_wdata_select_alu;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end
            
            sClz:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 1;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= 2'bxx;
                    opr2_select <= 2'bxx;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= gpr_waddr_select_ir_1511;
                    reg_gpr_wdata_select <= gpr_wdata_select_clz;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sMulExe:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= 2'bxx;
                    opr2_select <= 2'bxx;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sMulWB:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 1;
                    lo_we <= 1;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= 2'bxx;
                    opr2_select <= 2'bxx;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= hi_wdata_select_mult;
                    reg_lo_reg_wdata_select <= lo_wdata_select_mult;
                end

            sDivStart:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'bxx;
                    div_start <= 1;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= 2'bxx;
                    opr2_select <= 2'bxx;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sDivExe:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= 2'bxx;
                    opr2_select <= 2'bxx;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sDivWB:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 1;
                    lo_we <= 1;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= 2'bxx;
                    opr2_select <= 2'bxx;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= hi_wdata_select_div;
                    reg_lo_reg_wdata_select <= lo_wdata_select_div;
                end

            sBeqExe:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'b11;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= alu_opr1_select_gpr_rdata1;
                    opr2_select <= alu_opr2_select_gpr_rdata2;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sBeqWB:
                begin
                    ram_we <= 0;
                    pc_we <= alu_ctrl_zero ^ ir_ctrl_instr[26];
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'b11;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= alu_opr1_select_gpr_rdata1;
                    opr2_select <= alu_opr2_select_gpr_rdata2;
                    pc_in_select <= pc_in_select_branchCalcResult;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sBgezExe:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'b11;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= alu_opr1_select_const_0;
                    opr2_select <= alu_opr2_select_gpr_rdata1;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sBgezWB:
                begin
                    ram_we <= 0;
                    pc_we <= ~alu_ctrl_negative;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'b11;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= alu_opr1_select_const_0;
                    opr2_select <= alu_opr2_select_gpr_rdata1;
                    pc_in_select <= pc_in_select_branchCalcResult;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sJump:
                begin
                    ram_we <= 0;
                    pc_we <= 1;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= 2'bxx;
                    opr2_select <= 2'bxx;
                    pc_in_select <= pc_in_select_concatResult;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sJAL:
                begin
                    ram_we <= 0;
                    pc_we <= 1;
                    ir_we <= 0;
                    gpr_we <= 1;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= 2'bxx;
                    opr2_select <= 2'bxx;
                    pc_in_select <= pc_in_select_concatResult;
                    reg_gpr_waddr_select <= gpr_waddr_select_const_31;
                    reg_gpr_wdata_select <= gpr_wdata_select_pc;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sJR:
                begin
                    ram_we <= 0;
                    pc_we <= 1;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= 2'bxx;
                    opr2_select <= 2'bxx;
                    pc_in_select <= pc_in_select_gpr_rdata1;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sJALR:
                begin
                    ram_we <= 0;
                    pc_we <= ~(& ir_ctrl_instr[15:11]);
                    ir_we <= 0;
                    gpr_we <= 1;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= 2'bxx;
                    opr2_select <= 2'bxx;
                    pc_in_select <= pc_in_select_gpr_rdata1;
                    reg_gpr_waddr_select <= gpr_waddr_select_ir_1511;
                    reg_gpr_wdata_select <= gpr_wdata_select_pc;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sLoadMem:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 1;
                    immext_select <= 2'b01;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= ctrl_bad_addr;
                    cp0_eret <= 0;
                    cp0_cause <= 5'b00100;

                    addr_select <= ram_addr_select_alu;
                    opr1_select <= alu_opr1_select_gpr_rdata1;
                    opr2_select <= alu_opr2_select_extResult;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= gpr_waddr_select_ir_2016;
                    reg_gpr_wdata_select <= gpr_wdata_select_ram;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sLoadWB:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'b01;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ram_addr_select_pc;
                    opr1_select <= alu_opr1_select_gpr_rdata1;
                    opr2_select <= alu_opr2_select_extResult;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sStoreMem:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'b01;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= ctrl_bad_addr;
                    cp0_eret <= 0;
                    cp0_cause <= 5'b00101;

                    addr_select <= ram_addr_select_alu;
                    opr1_select <= alu_opr1_select_gpr_rdata1;
                    opr2_select <= alu_opr2_select_extResult;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end
            
            sStoreWB:
                begin
                    ram_we <= 1;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'b01;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ram_addr_select_alu;
                    opr1_select <= alu_opr1_select_gpr_rdata1;
                    opr2_select <= alu_opr2_select_extResult;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end
            
            sMFC0Ask:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 1;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= 2'bxx;
                    opr2_select <= 2'bxx;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sMFC0Get:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 1;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 1;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= 2'bxx;
                    opr2_select <= 2'bxx;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= gpr_waddr_select_ir_2016;
                    reg_gpr_wdata_select <= gpr_wdata_select_cp0;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sMFHI:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 1;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= 2'bxx;
                    opr2_select <= 2'bxx;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= gpr_waddr_select_ir_1511;
                    reg_gpr_wdata_select <= gpr_wdata_select_hi;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sMFLO:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 1;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= 2'bxx;
                    opr2_select <= 2'bxx;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= gpr_waddr_select_ir_1511;
                    reg_gpr_wdata_select <= gpr_wdata_select_lo;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end
            
            sMTC0:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 1;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= 2'bxx;
                    opr2_select <= 2'bxx;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sMTHI:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 1;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= 2'bxx;
                    opr2_select <= 2'bxx;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= hi_wdata_select_gpr;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sMTLO:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 1;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= 2'bxx;
                    opr2_select <= 2'bxx;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= lo_wdata_select_gpr;
                end

            sSyscall:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 1;
                    cp0_eret <= 0;
                    cp0_cause <= 5'b01000;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= 2'bxx;
                    opr2_select <= 2'bxx;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sEret:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 1;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= 2'bxx;
                    opr2_select <= 2'bxx;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sTeqExe:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= alu_opr1_select_gpr_rdata1;
                    opr2_select <= alu_opr2_select_gpr_rdata2;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sTeqWB:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= alu_ctrl_zero;
                    cp0_eret <= 0;
                    cp0_cause <= 5'b01101;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= alu_opr1_select_gpr_rdata1;
                    opr2_select <= alu_opr2_select_gpr_rdata2;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sBreak:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 1;
                    cp0_eret <= 0;
                    cp0_cause <= 5'b01001;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= 2'bxx;
                    opr2_select <= 2'bxx;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end

            sMul3WB:
                begin
                    ram_we <= 0;
                    pc_we <= 0;
                    ir_we <= 0;
                    gpr_we <= 1;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 1;
                    lo_we <= 1;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= 2'bxx;
                    opr2_select <= 2'bxx;
                    pc_in_select <= 3'bxxx;
                    reg_gpr_waddr_select <= gpr_waddr_select_ir_1511;
                    reg_gpr_wdata_select <= gpr_wdata_select_multLo;
                    reg_hi_reg_wdata_select <= hi_wdata_select_mult;
                    reg_lo_reg_wdata_select <= lo_wdata_select_mult;
                end

            sException:
                begin
                    ram_we <= 0;
                    pc_we <= 1;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= 2'bxx;
                    opr2_select <= 2'bxx;
                    pc_in_select <= pc_in_select_cp0_exc_addr;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end
            default: 
                begin
                    ram_we <= 0;
                    pc_we <= 1;
                    ir_we <= 0;
                    gpr_we <= 0;
                    immext_select <= 2'bxx;
                    div_start <= 0;
                    hi_we <= 0;
                    lo_we <= 0;
                    cp0_mfc0 <= 0;
                    cp0_mtc0 <= 0;
                    cp0_exception <= 0;
                    cp0_eret <= 0;
                    cp0_cause <= 5'bxxxxx;

                    addr_select <= ir_ctrl_instr[31] & ~ctrl_bad_addr;
                    opr1_select <= 2'bxx;
                    opr2_select <= 2'bxx;
                    pc_in_select <= pc_in_select_cp0_exc_addr;
                    reg_gpr_waddr_select <= 2'bxx;
                    reg_gpr_wdata_select <= 3'bxxx;
                    reg_hi_reg_wdata_select <= 2'bxx;
                    reg_lo_reg_wdata_select <= 2'bxx;
                end
        endcase
    end


endmodule