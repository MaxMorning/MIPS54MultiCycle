# MIPS54MultiCycle
A MIPS CPU without pipeline that support 54 basic instructions  
__Internal Code__ : Beryllium  
__Speed Test__ :   

    Programmed @ Xilinx Artix-7 28nm
    Top Speed @ 96 MHz
## Module Define
### RAM
    input wire clk, // Src : clk  
    input wire we, // Src : ctrl_ram_we
    input wire[31:0] addr, // Src : PC.pc_out / ALU.ALUresult
    // Notice : when exec lh inst, mask == 0011, signed_ext == 0, even if addr[1:0] == 10(not aligned in 32bit)
    input wire[31:0] wdata, // Src : RamStoreProc.data_out  

    output wire[31:0] rdata
### ALU
    input wire[31:0] opr1, // Src : PC.pc_out / GPR.rdata1 / GPR.rdata2 / 0 
    input wire[31:0] opr2, // Src : 4 / GPR.rdata1 / GPR.rdata2 / ImmExt.extResult  
    input wire[3:0] ALUcontrol,  // Src : ctrl_alu_ALUcontrol

    output wire[31:0] ALUresult,  
    output wire overflow,  
    output wire zero,  
    output wire negative  
### PC
    input wire clk, // Src : clk  
    input wire we, // Src : ctrl_pc_we  
    input wire[31:0] pc_in, // Src : ALU.ALUresult / GPR.rdata1(rs) / BranchCalc.branchCalcResult / Concat.concatResult / CP0.exec_addr  
    input wire reset,  // Src : reset  

    output reg[31:0] pc_out
### IR
    input wire clk, // Src : clk  
    input wire we, // Src : ctrl_ir_we  
    input wire[31:0] ir_in, // Src : RAM.rdata  

    output reg[31:0] ir_out
### GPR(RegFile)
    input wire clk, // Src : clk
    input wire reset, // Src : reset
    input wire we, // Src : ctrl_gpr_we
    input wire[4:0] raddr1, // Src : IR.ir_out[25:21](rs)
    input wire[4:0] raddr2, // Src : IR.ir_out[20:16](rt)
    input wire[4:0] waddr, // Src : 31 / IR.ir_out[20:16](rt) / IR.ir_out[15:11](rd)
    input wire[31:0] wdata, // Src : PC / HI_reg.rdata / LO_reg.rdata / CP0.rdata / ALUresult / clzCalcResult / RamLoadProc.rdata

    output wire[31:0] rdata1,
    output wire[31:0] rdata2
### ImmExt
    input wire[15:0] Imm16, // Src : IR.ir_out[15:0]
    input wire[1:0] ExtSelect, // Src : ctrl_immext_select

    output wire[31:0] extResult
### Concat
    input wire[25:0] Jimm, // Src : IR.ir_out[25:0]
    input wire[31:0] pc, // Src : PC.pc_out

    output wire[31:0] concatResult
### clzCalculate
    // 在Decode阶段进行L/S指令地址预计算时，GPR.rdata1内容即为GPRs[rs]的值，在Execute阶段clzCalcResult已经有效
    input wire[31:0] data_in, // Src : GPR.rdata1(rs)

    output wire[31:0] clzCalcResult
### multCalculate
    // 乘法可以在Decode阶段进行L/S指令地址预计算时并行预计算，此时需要进行的额外操作是gpr_raddr_select设置为IR.ir_out[20:16](rt)；Execute阶段空过一轮；Final Ops阶段时可以得到计算结果，写回HiLo即可
    input wire signed_mult, // Src : ~IR.ir_out[0]
    input wire[31:0] mult_a, // Src : GPR.rdata1(rs)
    input wire[31:0] mult_b, // Src : GPR.rdata2(rt)

    output wire[31:0] multResultHi,
    output wire[31:0] multResultLo
### divCalculate
    input wire clk, // Src : clk
    input wire start, // Src : ctrl_div_start
    input wire signed_div, // Src : ~IR.ir_out[0]
    input wire[31:0] dividend, // Src : GPR.rdata1(rs)
    input wire[31:0] divisor, // Src : GPR.rdata2(rt)
    
    output wire[31:0] q,
    output wire[31:0] r,
    output wire divDone
### branchCalc
    input wire[15:0] offset, // Src : IR.ir_out[15:0]
    input wire[31:0] pc_in, // Src : PC.pc_out

    output wire[31:0] branchCalcResult
### HI_reg
    input wire clk, // Src : clk
    input wire reset, // Src : reset
    input wire we, // Src : ctrl_hi_we
    input wire[31:0] wdata, // Src : GPR.rdata1(rs) / multCalculate.multResultHi / divCalculate.r

    output reg[31:0] rdata
### LO_reg
    input wire clk, // Src : clk
    input wire reset, // Src : reset
    input wire we, // Src : ctrl_lo_we
    input wire[31:0] wdata, // Src : GPR.rdata1(rs) / multCalculate.multResultLo / divCalculate.q

    output reg[31:0] rdata
### CP0
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
    output reg timer_int, 
    output wire[31:0] exc_addr

### RamStoreProc
    input wire[31:0] ram_data_in, // Src : RAM.rdata
    input wire[31:0] gpr_data_in, // Src : GPR.rdata2(rt)
    input wire[1:0] addr, // Src : ALU.ALUresult[1:0]
    input wire[1:0] mask, // Src : ctrl_ram_mask

    output wire[31:0] data_out

### RamLoadProc
    input wire[31:0] ram_data_in, // Src : RAM.rdata
    input wire[1:0] addr, // Src : ALU.ALUresult[1:0]
    input wire[1:0] mask, // Src : ctrl_ram_mask
    input wire signed_ext, // Src : IR.ir_out[0]

    output wire[31:0] data_out

### Controller
    input wire clk, // Src : clk
    input wire reset, // Src : reset
    input wire[31:0] ir_ctrl_instr, // Src : IR.ir_out
    input wire alu_ctrl_overflow, // Src : ALU.overflow
    input wire alu_ctrl_zero, // Src : ALU.zero
    input wire alu_ctrl_negative, // Src : ALU.negative
    input wire[31:0] alu_ctrl_ls_address, // Src : ALU.ALUresult
    input wire div_ctrl_done, // Src : divCalulate.divDone

    output wire ctrl_ram_we,
    output wire[1:0] ctrl_ram_mask,
    output wire ctrl_bad_addr,
    output wire[3:0] ctrl_alu_ALUcontrol, //  inst[31] ? 4'b0001  // Load / Store
                                                :
                                                inst[28] ? // 01xx
                                                4'b0110 : // 00xx
                                                // (inst[27] ? 
                                                //     (inst[26] ? 4'b1110 : 4'b0110) : //0111 NA  0110 NA
                                                //     (inst[26] ? 4'b0110 : 4'b0110) //0101 bne   0100 beq
                                                // )
                                                (inst[27] ? // 001x
                                                    {2'b00, inst[27:26]} : // 000x
                                                    // (inst[26] ? 4'b1011 : 4'b1010) : //0011 jal   0010 j
                                                    (inst[26] ? 4'b0001 : {4{inst[5]}} ~^ {inst[3], inst[5] & inst[2], inst[4] | inst[1], inst[0]}) //0001 bgez   0000 R type & teq
                                                )
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


## Interrupt Define
__CP0.cause[6:2]:__  
01000   syscall  
01001   break  
01101   teq  
01100   IntegerOverflow  
00100   AddressErrorLoad
00101   AddressErrorStore