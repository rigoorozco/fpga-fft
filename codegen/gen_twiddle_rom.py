#!/usr/bin/env python3
from math import cos, sin, log, ceil, pi
import sys


def usage() -> None:
    print(f"usage: {sys.argv[0]} SIZE WIDTH0 [WIDTH1...]")


def format_rom_entries(n: int, size: int, tw_bits: int) -> str:
    rom_width = tw_bits - 1
    scale = 2 ** rom_width
    fmt = "{0:0" + str(rom_width) + "b}"

    entries = []
    for i in range(size):
        x = float(i + 1) / n * (2 * pi)
        re1 = int(round(cos(x) * scale))
        im1 = int(round(sin(x) * scale))
        if re1 >= scale:
            re1 = scale - 1
        if im1 >= scale:
            im1 = scale - 1
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

    size = n // 8
    rom_depth_order = int(ceil(log(size) / log(2.0)))
    use_lutram = rom_depth_order <= 5
    use_blockram = rom_depth_order >= 8
    name = "twiddleRom" + str(n)

    extra_code = ""
    if use_lutram:
        extra_code = """
	attribute rom_style: string;
	attribute rom_style of data0: signal is "distributed";
	attribute rom_style of addr1: signal is "distributed";"""
    if use_blockram:
        extra_code = """
	attribute rom_style: string;
	attribute rom_style of data0: signal is "block";
	attribute rom_style of addr1: signal is "block";"""

    out = []
    out.append(
        f"""
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
-- read delay is 2 cycles

entity {name} is
	generic(twBits: integer := 17);
	port(clk: in std_logic;
			romAddr: in unsigned({rom_depth_order}-1 downto 0);
			romData: out std_logic_vector((twBits-1)*2-1 downto 0)
			);
end entity;
architecture a of {name} is
	constant romDepthOrder: integer := {rom_depth_order};
	constant romDepth: integer := 2**romDepthOrder;
	constant romWidth: integer := (twBits-1)*2;
	--ram
	type ram1t is array(0 to romDepth-1) of
		std_logic_vector(romWidth-1 downto 0);
	signal rom: ram1t;
	signal addr1: unsigned(romDepthOrder-1 downto 0);
	signal data0,data1: std_logic_vector(romWidth-1 downto 0);
{extra_code}
begin
	addr1 <= romAddr when rising_edge(clk);
	data0 <= rom(to_integer(addr1));
	data1 <= data0 when rising_edge(clk);
	romData <= data1;"""
    )

    for tw_bits in widths:
        rom = format_rom_entries(n, size, tw_bits)
        out.append(
            f"""
g{tw_bits}:
	if twBits = {tw_bits} generate
		rom <= (
{rom}
		);
	end generate;"""
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
