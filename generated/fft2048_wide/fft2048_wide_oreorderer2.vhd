
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.reorderBuffer;
use work.sr_unsigned;

-- phase should be 0,1,2,3,4,5,6,...
-- delay is 4096
-- fft bit order: (11 downto 0) [0,1,2,3,4,5,6,7,8,9,10,11]
entity fft2048_wide_oreorderer2 is
	generic(dataBits: integer := 24);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(12-1 downto 0);
		dout: out complex;
		dout_phase: out unsigned(12-1 downto 0)
		);
end entity;
architecture ar of fft2048_wide_oreorderer2 is
	signal rb_dout_phase: unsigned(12-1 downto 0);
	signal rCnt_phase_s: unsigned(1-1 downto 0);
	signal phase_oreorder: unsigned(12-1 downto 0);
	signal phase_fix0: unsigned(12-1 downto 0);
	signal rP0: unsigned(12-1 downto 0);
	signal rP1: unsigned(12-1 downto 0);
	signal rCnt: unsigned(1-1 downto 0);


begin
	rb: entity reorderBuffer
		generic map(N=>12, dataBits=>dataBits, repPeriod=>2, bitPermDelay=>0, dataPathDelay=>0)
		port map(clk=>clk, din=>din, phase=>phase, dout=>dout,
			bitPermIn=>rP0, bitPermCount=>rCnt, bitPermOut=>rP1, doutPhase=>rb_dout_phase);
	rP1 <= rP0(0)&rP0(1)&rP0(2)&rP0(3)&rP0(4)&rP0(5)&rP0(6)&rP0(7)&rP0(8)&rP0(9)&rP0(10)&rP0(11) when rCnt(0)='1' else rP0;


	phase_cnt_align: entity work.sr_unsigned
		generic map(bits=>1, len=>iif(12 >= TRANSPOSER_OREG_THRESHOLD, 3, 2))
		port map(clk=>clk, din=>rCnt, dout=>rCnt_phase_s, ce=>'1');

		phase_fix0 <= rb_dout_phase;
	phase_oreorder <= phase_fix0(0)&phase_fix0(1)&phase_fix0(2)&phase_fix0(3)&phase_fix0(4)&phase_fix0(5)&phase_fix0(6)&phase_fix0(7)&phase_fix0(8)&phase_fix0(9)&phase_fix0(10)&phase_fix0(11) when rCnt_phase_s(0)='1' else phase_fix0;

	dout_phase <= phase_oreorder;

end ar;
