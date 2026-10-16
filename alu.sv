module alu #(
    parameter N = 32
)(
    input  logic [N-1:0] a, b,
    input  logic   [3:0] alu_op,
    output logic [N-1:0] result,
    output logic         zero, overflow, c_out
);

    logic [N-1:0] adr_out, shf_out,                     //results to multiplex from depending on alu_op
                  and_out, orr_out, xor_out;
    logic         slt_out, slu_out;
    logic         c_tmp, overtemp;

    addsub_unit #(.N(N)) U1 (                           //temp. save adder results
        .a(a), .b(b), .sub(alu_op[3]),
        .s(adr_out), .c_out(c_tmp), .over(overtemp)
    );
    shifter_unit #(.N(N)) U2 (                          //temp. save shifter results
        .a(a), .shamt(b[$clog2(N)-1:0]),
        .right(alu_op[3]), .arith(alu_op[2]),
        .out(shf_out)
    );

    always_comb begin
        overflow = 1'b0; c_out = 1'b0;      //prevent latches
        casez(alu_op)
            4'bz000: begin                  //addition (x==0) / subtraction (x==1)
                result = adr_out;
                overflow = overtemp;
                c_out = c_tmp;
            end

            4'b0001: result = and_out;      //AND
            4'b0010: result = orr_out;      //OR
            4'b0100: result = xor_out;      //XOR

            4'b1100: result = {{(N-1){1'b0}}, slt_out};     //0-extended SLT
            4'b1101: result = {{(N-1){1'b0}}, slu_out};     //0-extended SLTU

            4'b0111: result = {N{1'b0}};    //unused code for shifter below
            4'bzz11: result = shf_out;      //SLL (xx==00)
                                            //SRL (xx==10)
                                            //SRA (xx==11)
            default: result = {N{1'b0}};
        endcase
        zero = (result == {N{1'b0}});               //evaluate if result is zero
    end

    //slt and sltu results
    assign slt_out = overtemp ^ adr_out[N-1];   //sign bit is wrong when overflow, so XOR corrects
    assign slu_out = ~c_tmp;                    //when subtracting, carry-out = 0 means borrow happened, so a < b

    //logic results
    assign and_out = a & b;
    assign orr_out = a | b;
    assign xor_out = a ^ b;

endmodule