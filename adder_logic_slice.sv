// -----------------------------------------------------------------------------
// adder_logic_slice: one ALU bit slice. Controls a full adder with logic that
// changes inputs based on f.
// -----------------------------------------------------------------------------
module adder_logic_slice (
    input  logic       a, b, c_in,
    input  logic [1:0] f,
    output logic       s, c_out
);

    logic b_inv, c;

    assign b_inv = b ^ f[0];    //invert b when f[0] == 1 (subtraction, XNOR)
    assign c  = c_in & f[1];    //force carry-in to 0 when f[1] == 0, so s has no carry term: XOR/XNOR in s, AND in c_out

    full_adder_slice U1 (
        .a(a), .b(b_inv), .c_in(c), .s(s), .c_out(c_out)
    );
endmodule