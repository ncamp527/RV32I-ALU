// -----------------------------------------------------------------------------
// adder_logic_unit: N-bit adder and logic unit built from 1-bit adder slices.
//
// f encoding (configures the shared adder):
//   00 : logic mode. Carry-in forced to 0, b not inverted.
//        s = a ^ b (XOR), c[N:1] = a & b (AND), s | c[N:1] = a | b (OR)
//   01 : b inverted, carry-in forced to 0. s = a ^ ~b = XNOR
//   10 : ADD. s = a + b
//   11 : SUB. s = a - b (b inverted, carry-in 1). Also feeds slt/sltu.
// -----------------------------------------------------------------------------
module adder_logic_unit #(
    parameter N = 32                                    //data width
)(
    input  logic [N-1:0] a, b,                          //operands
    input  logic   [1:0] f,                             //adder/logic configuration (see above)
    output logic [N-1:0] s,                             //adder sum. valid for ADD/SUB
    output logic         c_out,                         //carry-out of MSB (ADD/SUB only)
    output logic         over,                          //signed overflow  (ADD/SUB only)
    output logic [N-1:0] and_out, or_out, xor_out,      //logic results,         gated to 0 unless f == 00
    output logic         slt, sltu                      //1-bit compare results, gated to 0 unless f == 11
);
    logic [N:0] c;  //carry chain

    //N instances of adder; takes c[i] as carry-in and ouputs c[i+1] as carry-out
    adder U[N-1:0] (
        .a(a[N-1:0]),
        .b(b[N-1:0]),
        .c_in(c[N-1:0]),
        .f(f),
        .s(s),
        .c_out(c[N:1])
    );

    assign c[0]  = f[0];                                //initial carry-in
    assign c_out = f[1] & c[N];                         //final carry-out
    assign over  = f[1] & (c[N] ^ c[N-1]);              //signed overflow: carry into MSB differs from carry-out

    assign slt     =  f[1] & f[0]  & (over ^ s[N-1]);   // SLT output (signed   a < b). sign bit is wrong when overflow, so XOR corrects
    assign sltu    =  f[1] & f[0]  & ~c[N];             //SLTU output (unsigned a < b). when subtracting, carry-out = 0 means borrow happened, so a < b

    //logic results come from adder with its carry-in forced to 0 and b not inverted (f == 00)
    //condition is replicated to N bits so every bit is gated; keeps waveforms clean
    //   c[N:1]       -> a & b  (carry-out = a & b when c_in = 0)
    //   s | c[N:1]   -> a | b  ((a ^ b) | (a & b) = a | b)
    //   s            -> a ^ b
    assign and_out = ~{N{f[1] | f[0]}} & c[N:1];        //AND output
    assign or_out  = ~{N{f[1] | f[0]}} & (s | c[N:1]);  //OR  output
    assign xor_out = ~{N{f[1] | f[0]}} & s;             //XOR output

endmodule
