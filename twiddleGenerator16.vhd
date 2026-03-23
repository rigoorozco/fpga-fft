
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
-- read delay is 2 cycles

entity twiddleGenerator16 is
	generic(twBits: integer := 17; inverse: boolean := true);
	port(clk: in std_logic;
			twAddr: in unsigned(4-1 downto 0);
			twData: out complex
			);
end entity;
architecture a of twiddleGenerator16 is
	constant romDepthOrder: integer := 4;
	constant romDepth: integer := 2**romDepthOrder;
	constant romWidth: integer := (twBits + 1)*2;
	--ram
	type ram1t is array(0 to romDepth-1) of
		std_logic_vector(romWidth-1 downto 0);
	signal rom, romInverse: ram1t := (others => (others => '0'));
	signal addr1: unsigned(romDepthOrder-1 downto 0) := (others => '0');
	signal data0,data1: std_logic_vector(romWidth-1 downto 0) := (others => '0');
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

g12:
	if twBits = 12 generate
		romInverse <= (
			"00000000000000100000000000", "00011000100000011101100100", "00101101010000010110101000", "00111011001000001100010000", "01000000000000000000000000", "00111011001001110011110000",
			"00101101010001101001011000", "00011000100001100010011100", "00000000000001100000000000", "11100111100001100010011100", "11010010110001101001011000", "11000100111001110011110000",
			"11000000000000000000000000", "11000100111000001100010000", "11010010110000010110101000", "11100111100000011101100100"
		);
		rom <= (
			"00000000000000100000000000", "11100111100000011101100100", "11010010110000010110101000", "11000100111000001100010000", "11000000000000000000000000", "11000100111001110011110000",
			"11010010110001101001011000", "11100111100001100010011100", "00000000000001100000000000", "00011000100001100010011100", "00101101010001101001011000", "00111011001001110011110000",
			"01000000000000000000000000", "00111011001000001100010000", "00101101010000010110101000", "00011000100000011101100100"
		);
	end generate;

end a;
