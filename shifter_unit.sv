module shifter_unit #(
    parameter N = 32
)(
    input  logic [N-1:0]         a,
    input  logic [$clog2(N)-1:0] shamt,
    input  logic                 right, arith,
    output logic [N-1:0]         out
);
    logic [$clog2(N):0][N-1:0] x;
    logic fill;

    assign fill =  right & arith & a[N-1];      //determine filling by 0 or 1

    //reverse if right shift
    always_comb for (int i = 0; i < N; i++)
        x[0][i] = right ? a[N-1-i] : a[i];

    //shift
    for (genvar i = 0; i < $clog2(N); i++) begin : shifter
        localparam integer shiftby = (1'b1<<i);
        assign x[i+1] = shamt[i] ? {x[i][N-1-shiftby:0], {shiftby{fill}}} : x[i];
    end

    //assign to output, un-reverse if needed
    always_comb for (int i = 0; i < N; i++)
        out[i] = right ? x[$clog2(N)][N-1-i] : x[$clog2(N)][i];
endmodule