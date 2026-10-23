// -----------------------------------------------------------------------------
// addsub_unit: N-bit adder unit built from 1-bit adder slices.
// -----------------------------------------------------------------------------
module addsub_unit #(
    parameter N = 32                                    //data width
)(
    input  logic [N-1:0] a, b,                          //operands
    input  logic         sub,                           //inverter for subtraction
    output logic [N-1:0] s,                             //sum
    output logic         c_out,                         //carry-out of MSB
    output logic         over                           //signed overflow
);
    logic   [N:0] c;        //carry chain
    logic [N-1:0] b_inv;

    //N instances of adder; takes c[i] as carry-in and outputs c[i+1] as carry-out
    full_adder_slice U[N-1:0] (
        .a(a[N-1:0]),
        .b(b_inv[N-1:0]),
        .c_in(c[N-1:0]),
        .s(s),
        .c_out(c[N:1])
    );

    assign b_inv = b ^ {N{sub}};                //invert b when sub == 1 (subtraction)
    assign c[0]  = sub;                         //initial carry-in
    assign c_out = c[N];                        //final carry-out
    assign over  = c[N] ^ c[N-1];               //signed overflow: carry into MSB differs from carry-out
endmodule
