# MIPS54MultiCycle
A MIPS CPU without pipeline that support 54 basic instructions
## Module Define
### RAM
    input wire clk, // Src : clk  
    input wire we, // Src : ctrl_ram_we
    input wire[31:0] addr, // Src : PC.pc_out / ALU.ALUresult
    input wire[3:0] load_mask, // Src : ctrl_ram_load_mask
    input wire signed_ext, // Src : ctrl_ram_signedExt
    // Notice : when exec lh inst, load_mask == 0011, signed_ext == 0, even if addr[1:0] == 10(not aligned in 32bit)
    input wire[31:0] wdata, // Src : GPR.rdata2(rt)  
    input wire[3:0] write_mask, // Src : ctrl_ram_write_mask  

    output wire[31:0] rdata
### ALU
    input wire[31:0] opr1, // Src : PC.pc_out / GPR.rdata1 / GPR.rdata2  
    input wire[31:0] opr2, // Src : 4 / GPR.rdata1 / GPR.rdata2 / ImmExt.extResult  
    input wire[3:0] ALUcontrol,  // Src : ctrl_alu_ALUcontrol

    output wire[31:0] ALUresult,  
    output wire overflow,  
    output wire zero,  
    output wire negative  
### PC
    input wire clk, // Src : clk  
    input wire we, // Src : ctrl_pc_we  
    input wire[31:0] pc_in, // Src : ALU.ALUresult / 4 / GPR.rdata1(rs) / BranchCalc.branchCalcResult / Concat.concatResult / CP0.exec_addr  
    input wire reset,  // Src : reset  

    output reg[31:0] pc_out
### IR
    input wire clk, // Src : clk  
    input wire we, // Src : ctrl_ir_we  
    input wire[31:0] ir_in, // Src : RAM.rdata  

    output reg[31:0] ir_out
### GPR
    input wire clk, // Src : clk
    input wire reset, // Src : reset
    input wire we, // Src : ctrl_gpr_we
    input wire[4:0] raddr1, // Src : IR.ir_out[25:21](rs) / IR.ir_out[20:16](rt) / IR.ir_out[15:11](rd)
    input wire[4:0] raddr2, // Src : IR.ir_out[25:21](rs) / IR.ir_out[20:16](rt) / IR.ir_out[15:11](rd)
    input wire[4:0] waddr, // Src : 31 / IR.ir_out[20:16](rt) / IR.ir_out[15:11](rd)
    input wire[31:0] wdata, // Src : PC / HI_LO / CP0.rdata / ALUresult / multResult / clzCalcResult / RAM.rdata

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
    input wire[31:0] data_in, // Src : GPR.rdata1(rs)

    output wire[4:0] clzCalcResult
### multCalculate
    input wire clk, // Src : clk
    input wire reset, // Src : ctrl_mult_reset
    input wire[31:0] mult_a, // Src : GPR.rdata1(rs)
    input wire[31:0] mult_b, // Src : GPR.rdata2(rt)

    output wire[63:0] multResult,
    output wire multDone
### divCalculate
    input wire clk, // Src : clk
    input wire start, // Src : ctrl_div_start
    input wire[31:0] dividend, // Src : GPR.rdata1(rs)
    input wire[31:0] divisor, // Src : GPR.rdata2(rt)
    
    output wire[31:0] q,
    output wire[31:0] r,
    output wire divDone
### branchCalc
    input wire[15:0] offset, // Src : IR.ir_out[15:0]
    input wire[31:0] pc_in, // Src : PC.pc_out

    output wire[31:0] branchCalcResult
### HI_LO
    input wire clk, // Src : clk
    input wire reset, // Src : reset
    input wire hi_lo_select, // Src : ctrl_hilo_select
    input wire we, // Src : ctrl_hilo_we
    input wire[31:0] wdata, // Src : GPR.rdata1(rs)

    output wire[31:0] rdata
### Controller
    input wire clk, // Src : clk
    input wire reset, // Src : reset

    output wire ctrl_ram_we,
    output wire[3:0] ctrl_ram_load_mask,
    output wire ctrl_ram_signedExt,
    output wire[3:0] ctrl_ram_write_mask, 
    output wire[3:0] ctrl_alu_ALUcontrol,
    output wire ctrl_pc_we,
    output wire ctrl_ir_we,
    output wire ctrl_gpr_we,
    output wire[1:0] ctrl_immext_select,
    output wire ctrl_mult_reset,
    output wire ctrl_div_start,
    output wire ctrl_hilo_select,
    output wire ctrl_hilo_we


## Interrupt Define
__CP0.cause[6:2]:__  
01000   syscall  
01001   break  
01101   teq  
10000   IntegerOverflow  
10001   AddressError