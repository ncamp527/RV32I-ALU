from __future__ import annotations

import cocotb
from cocotb.triggers import Timer

# unsigned to signed conversion
def unsigned_to_signed(value: int, width: int) -> int:
    if value & (1 << (width - 1)):
        return value - (1 << width)
    return value

# add_test
@cocotb.test
async def add_4bit_test(dut):
    # set opcode
    dut.alu_op.value = 0b0000

    # exhaustively test all 4-bit operands in the top nibble (0x?0000000)
    for a in range(16):
        for b in range(16):
            dut.a.value = a << 28   # place a in top nibble
            dut.b.value = b << 28   # place b in top nibble
            await Timer(1, "ns")

            result = ((a + b) << 28) & 0xFFFFFFFF   # compute result
            zero   = int(result == 0)               # compute zero
            c_out  = int(a + b > 0xF)               # compute carry out

            signed_result = unsigned_to_signed(a,4) + unsigned_to_signed(b,4)
            overfl = int(not (-8 <= signed_result <= 7))   # compute overflow

            # verify outputs
            assert int(dut.result.value) == int(result), (
                f"a: {a}, b: {b}, "
                f"expected: {result}, actual: {int(dut.result.value)}"
            )

            assert int(dut.zero.value) == zero, (
                f"a: {a}, b: {b}, "
                f"expected: {zero}, actual: {int(dut.zero.value)}"
            )

            assert int(dut.c_out.value) == c_out, (
                f"a: {a}, b: {b}, "
                f"expected: {c_out}, actual: {int(dut.c_out.value)}"
            )

            assert int(dut.overflow.value) == overfl, (
                f"a: {a}, b: {b}, "
                f"expected: {overfl}, actual: {int(dut.overflow.value)}"
            )
# end add_4bit_test