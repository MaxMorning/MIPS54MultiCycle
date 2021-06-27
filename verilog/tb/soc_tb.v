`timescale 1ns/1ps
module soc_tb();
    reg clk;
    reg reset;
    wire[31:0] soc_ram_addr;
    wire[31:0] soc_ram_data;
    wire[31:0] soc_cp0_exc_addr;
    reg[31:0] prev_instr;

    integer fout;
    integer i;

    // wire[31:0] a_0;
    // wire[31:0] a_1;
    // wire[31:0] a_2;
    // wire[31:0] a_3;
    // wire[31:0] a_4;
    // wire[31:0] a_5;
    // wire[31:0] a_6;
    // wire[31:0] a_7;

    // assign a_0 = soc_inst.ram_inst.mem[0];
    // assign a_1 = soc_inst.ram_inst.mem[1];
    // assign a_2 = soc_inst.ram_inst.mem[2];
    // assign a_3 = soc_inst.ram_inst.mem[3];
    // assign a_4 = soc_inst.ram_inst.mem[4];
    // assign a_5 = soc_inst.ram_inst.mem[5];
    // assign a_6 = soc_inst.ram_inst.mem[6];
    // assign a_7 = soc_inst.ram_inst.mem[7];

    soc soc_inst(
        .clk(clk),
        .reset(reset),
        .ram_addr(soc_ram_addr),
        .ram_data(soc_ram_data),
        .cp0_exc_addr(soc_cp0_exc_addr)
    );

    initial begin
        clk = 0;
        forever begin
            #5 clk = ~clk;
        end
    end

    initial begin
//        $readmemh("G:/FTP/TransTemp/MIPS31/WORKSPACE/instr.txt", soc.iram_inst.inst_array);
        // $readmemh("G:/FTP/TransTemp/MIPS54/WORKSPACE/ram.txt", soc_inst.ram_inst.mem);
        $readmemh("G:/FTP/TransTemp/MIPS54/WORKSPACE/ram_3.txt", soc_inst.ram_inst.mem8_inst3.mem);
        $readmemh("G:/FTP/TransTemp/MIPS54/WORKSPACE/ram_2.txt", soc_inst.ram_inst.mem8_inst2.mem);
        $readmemh("G:/FTP/TransTemp/MIPS54/WORKSPACE/ram_1.txt", soc_inst.ram_inst.mem8_inst1.mem);
        $readmemh("G:/FTP/TransTemp/MIPS54/WORKSPACE/ram_0.txt", soc_inst.ram_inst.mem8_inst0.mem);
        fout = $fopen("G:/FTP/TransTemp/MIPS54/WORKSPACE/result.txt", "w+");
        reset = 1;

        prev_instr = 32'h0;
        #6
        reset = 0;

        #6;
        forever begin
            if (prev_instr != soc_inst.cpu_inst.ir_inst.ir_out) begin
                $fdisplay(fout, "pc: %h", soc_inst.cpu_inst.pc_inst.pc_out - 8);
                $fdisplay(fout, "instr: %h", prev_instr);

                for (i = 0; i < 32; i = i + 1) begin
                    $fdisplay(fout, "regfile%d: %h", i, soc_inst.cpu_inst.reg_file.array_reg[i]);
                end

                prev_instr = soc_inst.cpu_inst.ir_inst.ir_out;
            end
            
            #10;
            
        end
        $fclose(fout);
    end
    
endmodule