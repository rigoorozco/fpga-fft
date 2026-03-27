
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.fft2048_wide;
use work.fft2048_wide_oreorderer1;

use work.fft2048_wide_ireorderer1;

-- 1 interleaved channels, natural order
-- phase should be 0,1,2,3,4,5,6,...
-- din should be ch0d0, ch1d0, ch2d0, ch3d0, ch0d1, ch1d1, ... (if 4 channels)
-- delay is 6382
entity fft2048_wide_wrapper1 is
	generic(dataBits: integer := 24; twBits: integer := 12; inverse: boolean := true);
	port(clk: in std_logic;
			din: in complex;
			din_valid: in std_logic := '1';
			phase: in unsigned(11-1 downto 0);
			dout: out complex;
			dout_valid: out std_logic
			);
end entity;
architecture ar of fft2048_wide_wrapper1 is
	constant PIPELINE_DELAY_CYCLES: integer := 6382;
	signal core_din, core_dout: complex := to_complex(0, 0);
	signal core_phase: unsigned(11-1 downto 0) := (others => '0');
	signal oreorderer_phase: unsigned(11-1 downto 0) := (others => '0');
begin

	ireorder: entity fft2048_wide_ireorderer1 generic map(dataBits=>dataBits)
		port map(clk=>clk, phase=>phase, din=>din, dout=>core_din);

	core_phase <= phase + 1 when rising_edge(clk);

	core: entity fft2048_wide generic map(dataBits=>dataBits, twBits=>twBits, inverse=>inverse)
		port map(clk=>clk, phase=>core_phase(11-1 downto 0), din=>core_din, dout=>core_dout);
	
	oreorderer_phase <= core_phase + 1811 when rising_edge(clk);
	
	oreorderer: entity fft2048_wide_oreorderer1 generic map(dataBits=>dataBits)
		port map(clk=>clk, phase=>oreorderer_phase, din=>core_dout, dout=>dout);

	valid_delay: entity work.sr_bit
		generic map(len=>PIPELINE_DELAY_CYCLES)
		port map(clk=>clk, din=>din_valid, dout=>dout_valid, ce=>'1');
end ar;
