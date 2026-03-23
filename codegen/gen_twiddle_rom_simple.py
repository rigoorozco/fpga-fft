#!/usr/bin/env python3
from math import cos, sin, log, ceil, pi
import sys


def usage() -> None:
    print(f"usage: {sys.argv[0]} SIZE WIDTH0 [WIDTH1...]")


def format_rom_entries(n: int, tw_bits: int, inverse: bool, reduced_bits: bool) -> str:
    scale = 2 ** (tw_bits - 1)
    fmt_bits = tw_bits
    if reduced_bits:
        scale -= 1
    else:
        fmt_bits += 1

    fmt = "{0:0" + str(fmt_bits) + "b}"
    entries = []
    for i in range(n):
        x = float(i) / n * (2 * pi)
        re1 = int(round(cos(x) * scale))
        im1 = int(round(sin(x) * scale))
        if not inverse:
            im1 = -im1

        if re1 < 0:
            re1 += 2 ** fmt_bits
        if im1 < 0:
            im1 += 2 ** fmt_bits

        entries.append(f"\"{fmt.format(im1)}{fmt.format(re1)}\"")

    lines = []
    for i in range(0, len(entries), 6):
        lines.append("\t\t\t" + ", ".join(entries[i:i + 6]))
    return ",\n".join(lines)


def main() -> int:
    if len(sys.argv) < 3:
        usage()
        return 1

    n = int(sys.argv[1])
    widths = [int(x) for x in sys.argv[2:]]

    reduced_bits = False
    depth_order = int(ceil(log(n) / log(2.0)))
    rom_width = "twBits" if reduced_bits else "twBits + 1"
    name = "twiddleGenerator" + str(n)

    out = []
    out.append(
        f"""
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
-- read delay is 2 cycles

entity {name} is
	generic(twBits: integer := 17; inverse: boolean := true);
	port(clk: in std_logic;
			twAddr: in unsigned({depth_order}-1 downto 0);
			twData: out complex
			);
end entity;
architecture a of {name} is
	constant romDepthOrder: integer := {depth_order};
	constant romDepth: integer := 2**romDepthOrder;
	constant romWidth: integer := ({rom_width})*2;
	--ram
	type ram1t is array(0 to romDepth-1) of
		std_logic_vector(romWidth-1 downto 0);
	signal rom, romInverse: ram1t;
	signal addr1: unsigned(romDepthOrder-1 downto 0);
	signal data0,data1: std_logic_vector(romWidth-1 downto 0);
begin
	addr1 <= twAddr when rising_edge(clk);

g1: if inverse generate
		data0 <= romInverse(to_integer(addr1));
	end generate;
g2: if not inverse generate
		data0 <= rom(to_integer(addr1));
	end generate;
	data1 <= data0 when rising_edge(clk);
	twData <= complex_unpack(data1);
"""
    )

    for tw_bits in widths:
        inv_rom = format_rom_entries(n, tw_bits, True, reduced_bits)
        fwd_rom = format_rom_entries(n, tw_bits, False, reduced_bits)
        out.append(
            f"""
g{tw_bits}:
	if twBits = {tw_bits} generate
		romInverse <= (
{inv_rom}
		);
		rom <= (
{fwd_rom}
		);
	end generate;
"""
        )

    out.append(
        """
end a;
"""
    )

    sys.stdout.write("".join(out))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
