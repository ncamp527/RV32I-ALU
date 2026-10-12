// -----------------------------------------------------------------------------
// full_adder_slice: standard 1-bit full adder.
// -----------------------------------------------------------------------------
module full_adder_slice (
    input logic a, b, c_in, output logic s, c_out
);
    assign s     = (a ^ b) ^ c_in;              //sum bit
    assign c_out = (a & b) | ((a ^ b) & c_in);  //generate OR propagate-and-carry
endmodule