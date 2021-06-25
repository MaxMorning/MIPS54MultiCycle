`timescale 1ns / 1ps

module divCalculate (
    input wire clk,
    input wire start,
    input wire signed_div,
    input wire[31:0] dividend,
    input wire[31:0] divisor,

    output wire[31:0] q,
    output wire[31:0] r,
    output wire divDone
);

    reg busy;
    reg r_signal;
    reg q_signal;
    reg [4:0] cnt;
    reg r_sign;
    reg [31:0] reg_b;
    reg [31:0] reg_r;
    reg [31:0] reg_q;
    wire [31:0] temp_r;
    wire [32:0] sub_add;

    assign sub_add = r_sign ? ({reg_r, reg_q[31]} + {1'b0, reg_b}) : ({reg_r, reg_q[31]} - {1'b0, reg_b});
    assign temp_r = r_sign ? reg_r + reg_b : reg_r;
    assign q = q_signal ? ~reg_q + 1 : reg_q; 
    assign r = r_signal ? ~temp_r + 1 : temp_r;
    assign divDone = ~busy;
    always @(posedge clk) begin
        if (start) begin
            busy <= 1'b1;
            reg_q <= dividend[31] ? ~dividend + 1 : dividend;
            r_signal <= dividend[31] & signed_div;
            reg_r <= 32'h0;
            reg_b <= divisor[31] ? ~divisor + 1 : divisor;
            q_signal <= (divisor[31] ^ dividend[31]) & signed_div;
            r_sign <= 1'b0;
            cnt <= 1'b0;
        end
        else if (busy) begin
            reg_r <= sub_add[31:0];
            r_sign <= sub_add[32];
            reg_q <= {reg_q[30:0], ~sub_add[32]};
            cnt <= cnt + 1'b1;
            if (cnt == 5'b11111) begin
                busy <= 1'b0;
            end
        end
    end
endmodule