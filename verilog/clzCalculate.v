module clzCalculate (
    input wire[31:0] data_in,

    output wire[31:0] clzCalcResult
);
    assign clzCalcResult[31:5] = 27'h0000;
    assign clzCalcResult[4] = ~(| data_in[31:16]);
    reg[3:0] clzResult;
    assign clzCalcResult[3:0] = clzResult;

    always @ (*) begin
        if (clzCalcResult[4]) begin
            clzResult[3] <= ~(| data_in[15:8]);
        end
        else begin
            clzResult[3] <= ~(| data_in[31:24]);
        end
    end

    always @(*) begin
        case (clzCalcResult[4:3])
            2'b00:
                begin
                    clzResult[2] <= ~(| data_in[31:28]);
                end
            2'b01:
                begin
                    clzResult[2] <= ~(| data_in[23:20]);
                end
            2'b10:
                begin
                    clzResult[2] <= ~(| data_in[15:12]);
                end
            2'b11: 
                begin
                    clzResult[2] <= ~(| data_in[7:4]);
                end
        endcase
    end

    always @(*) begin
        case (clzCalcResult[4:2])
            3'b000:
                begin
                    clzResult[1] <= ~(| data_in[31:30]);
                end 
            3'b001: 
                begin
                    clzResult[1] <= ~(| data_in[27:26]);
                end 
            3'b010:
                begin
                    clzResult[1] <= ~(| data_in[23:22]);
                end 
            3'b011:
                begin
                    clzResult[1] <= ~(| data_in[19:18]);
                end 
            3'b100:
                begin
                    clzResult[1] <= ~(| data_in[15:14]);
                end 
            3'b101:
                begin
                    clzResult[1] <= ~(| data_in[11:10]);
                end
            3'b110:
                begin
                    clzResult[1] <= ~(| data_in[7:6]);
                end 
            3'b111:
                begin
                    clzResult[1] <= ~(| data_in[3:2]);
                end
        endcase
    end

    always @(*) begin
        clzResult[0] <= ~data_in[31 - {clzCalcResult[4:1], 1'b0}];
        // case (clzCalcResult[4:1])
        //     4'b0000: 
        //         begin
        //             clzResult[0] <= ~data_in[31];
        //         end
        //     4'b0001: 
        //         begin
        //             clzResult[0] <= ~data_in[29];
        //         end
        //     4'b0010: 
        //         begin
        //             clzResult[0] <= ~data_in[27];
        //         end
        //     4'b0011: 
        //         begin
        //             clzResult[0] <= ~data_in[2];
        //         end
        // endcase
    end

endmodule