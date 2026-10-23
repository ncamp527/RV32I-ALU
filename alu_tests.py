from __future__ import annotations

import random

import cocotb
from cocotb.triggers import Timer

# operation codes
OP_ADD = 0b0000
OP_SUB = 0b1000
OP_AND = 0b0001
OP_ORR = 0b0010
OP_XOR = 0b0100
OP_SLT = 0b1100
OP_SLU = 0b1101
OP_SLL = 0b0011
OP_SRL = 0b1011
OP_SRA = 0b1111

# edge cases tested against one another
EDGE_CASES = [
    0x00000000, 0x00000001, 0x00000002,
    0x7FFFFFFE, 0x7FFFFFFF,              # largest positives
    0x80000000, 0x80000001,              # smallest negatives
    0xFFFFFFFE, 0xFFFFFFFF,              # -2, -1
    0x0000FFFF, 0xFFFF0000,              # half-words
    0x55555555, 0xAAAAAAAA,              # alternating bits
]

# unsigned to signed conversion
def to_signed(value: int, width: int = 32) -> int:
    return value - (1 << width) if (value & (1 << (width - 1))) else value

# reduce duplicated code
def compute_addsub(op: int, a: int, b: int) -> dict[str, int]:
    if op == OP_ADD:
        raw = a + b
        c_out = int(raw > ((1 << 32) - 1))      # any bits over 32?
        signed = to_signed(a) + to_signed(b)
    elif op == OP_SUB:
        raw = a - b
        c_out = int(a >= b)
        signed = to_signed(a) - to_signed(b)
    else:
        raise ValueError(f"Invalid op: {op}")

    result = raw & ((1 << 32) - 1)              # truncate to 32 bits
    lo, hi = -(1 << 31), (1 << 31) - 1          # bounds of 32b 2's comp. number

    return {
        "result": result,
        "zero": int(result == 0),
        "c_out": c_out,
        "overflow": int(not (lo <= signed <= hi)),
    }

async def assert_addsub(dut, op: int, a: int, b: int):
    # assign inputs
    dut.alu_op.value = op
    dut.a.value = a
    dut.b.value = b
    await Timer(1, "ns")

    # verify outputs
    for name, exp in compute_addsub(op, a, b).items():
        assert int(getattr(dut, name).value) == exp, (
            f"op: {op}, "
            f"a: {a}, b: {b}, "
            f"{name} expected: {exp}, actual: {int(getattr(dut, name).value)}"
        )


# test_addsub_4bit
@cocotb.test
@cocotb.parametrize(op=[OP_ADD, OP_SUB])
async def test_addsub_4bit(dut,op):
    # exhaustively test all 4-bit operands in the top nibble (0x?0000000)
    for a in range(16):
        for b in range(16):
            await assert_addsub(dut, op, a << 28, b << 28)
# end test_addsub_4bit

# test_addsub_rand
@cocotb.test
@cocotb.parametrize(op=[OP_ADD, OP_SUB])
async def test_addsub_rand(dut,op):
    # randomly assign values and test 100k times
    for _ in range(100000):
        await assert_addsub(dut, op, random.getrandbits(32), random.getrandbits(32))
# end test_addsub_rand

# test_addsub_edge
@cocotb.test
@cocotb.parametrize(op=[OP_ADD, OP_SUB])
async def test_addsub_edge(dut,op):
    for case in EDGE_CASES:
        for case2 in EDGE_CASES:
            await assert_addsub(dut, op, case, case2)
# end test_addsub_edge
